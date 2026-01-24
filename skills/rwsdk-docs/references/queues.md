# RedwoodSDK Queues Reference

## Overview

Cloudflare Queues enable background task processing in RedwoodSDK. Send messages to queues for asynchronous processing without blocking user requests.

## Use Cases

- Send emails
- Process payments
- Generate reports
- Image/video processing
- AI/ML operations
- Webhook delivery
- Data synchronization

## Setup

### 1. Create Queue

```bash
npx wrangler queues create my-queue-name
```

### 2. Configure Wrangler

```jsonc
// wrangler.jsonc
{
  "queues": {
    "producers": [
      {
        "binding": "QUEUE",
        "queue": "my-queue-name",
      }
    ],
    "consumers": [
      {
        "queue": "my-queue-name",
        "max_batch_size": 10,
        "max_batch_timeout": 5
      }
    ]
  }
}
```

Run `pnpm generate` after updating.

### 3. Queue Naming Rules

Queue names must match: `^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$`

Valid names:
- `my-queue`
- `my-awesome-queue-123`
- `queue1`
- `my-queue-v2`

Invalid names:
- `My_Queue` (no uppercase/underscores)
- `MY_QUEUE_NAME` (no uppercase/underscores)
- `-queue-` (can't start/end with hyphen)
- `queue_name` (no underscores)

## Sending Messages

### Basic Send

```tsx
import { env } from "cloudflare:workers";

export default defineApp([
  route('/pay-with-ai', () => {
    env.QUEUE.send({
      userId: 1,
      amount: 100,
      currency: 'USD',
    });

    return new Response('Done!');
  })
]);
```

### Send from Server Function

```tsx
"use server";

import { env } from "cloudflare:workers";
import { requestInfo } from "rwsdk/worker";

export async function processPayment(formData: FormData) {
  const { ctx } = requestInfo;
  const amount = formData.get("amount");

  await env.QUEUE.send({
    type: 'PAYMENT',
    userId: ctx.user.id,
    amount: Number(amount),
    currency: 'USD',
  });

  return { success: true };
}
```

### Batch Send

```tsx
await env.QUEUE.sendBatch([
  { body: { userId: 1, action: 'email' } },
  { body: { userId: 2, action: 'email' } },
  { body: { userId: 3, action: 'email' } },
]);
```

## Receiving Messages

Change worker export to handle queue messages:

```tsx
// src/worker.tsx
const app = defineApp([/* routes... */]);

export default {
  fetch: app.fetch,
  async queue(batch) {
    for (const message of batch.messages) {
      console.log('Handling message:', message.body);
      // Process message
    }
  }
} satisfies ExportedHandler<Env>;
```

## Message Patterns

### 1. Direct Message Body (< 128KB)

Best for: Small payloads

```ts
await queue.send({
  body: JSON.stringify({
    email: "user@example.com",
    subject: "Welcome!"
  }),
});
```

Pros:
- Simple and fast

Cons:
- 128KB hard limit

### 2. Store in R2, Send Key

Best for: Large payloads (files, videos, large JSON)

```ts
// Upload to R2
await r2.put("msg/123.json", JSON.stringify(largeData));

// Send key to queue
await queue.send({
  body: JSON.stringify({ r2Key: "msg/123.json" }),
});
```

Consumer:

```tsx
async queue(batch) {
  for (const message of batch.messages) {
    const { r2Key } = JSON.parse(message.body);
    const object = await env.R2.get(r2Key);
    const data = await object.json();

    // Process data
  }
}
```

Pros:
- Handles large data
- Persistent and versioned

Cons:
- Slightly more complex
- Requires R2 setup

### 3. Store in KV, Send Key

Best for: Short-lived, small-to-medium payloads

```ts
// Save to KV
await kv.put("queue:msg:123", JSON.stringify(data), {
  expirationTtl: 600 // 10 minutes
});

// Send reference key
await queue.send({
  body: JSON.stringify({ kvKey: "queue:msg:123" }),
});
```

Pros:
- Fast access
- Automatic expiration

Cons:
- Not ideal for large data
- Eventually consistent

## Handling Different Message Types

### Using Message Type Field

```tsx
// Sending different message types
env.QUEUE.send({
  type: 'PAYMENT',
  userId: 1,
  amount: 100,
});

env.QUEUE.send({
  type: 'EMAIL',
  userId: 1,
  template: 'welcome',
});
```

```tsx
// Handling different types
async queue(batch) {
  for (const message of batch.messages) {
    const { type, ...data } = message.body;

    switch (type) {
      case 'PAYMENT':
        await processPayment(data);
        break;
      case 'EMAIL':
        await sendEmail(data);
        break;
      default:
        console.warn(`Unknown message type: ${type}`);
    }
  }
}
```

### Using Multiple Queues (Recommended)

Better practice: Dedicated queue per message type

```jsonc
// wrangler.jsonc
{
  "queues": {
    "producers": [
      { "binding": "PAYMENT_QUEUE", "queue": "payment-queue" },
      { "binding": "EMAIL_QUEUE", "queue": "email-queue" }
    ],
    "consumers": [
      { "queue": "payment-queue", "max_batch_size": 10 },
      { "queue": "email-queue", "max_batch_size": 100 }
    ]
  }
}
```

```tsx
// Sending to specific queues
env.PAYMENT_QUEUE.send({ userId: 1, amount: 100 });
env.EMAIL_QUEUE.send({ userId: 1, template: 'welcome' });
```

```tsx
// Handling by queue name
async queue(batch) {
  if (batch.queue === 'payment-queue') {
    for (const message of batch.messages) {
      await processPayment(message.body);
    }
  } else if (batch.queue === 'email-queue') {
    for (const message of batch.messages) {
      await sendEmail(message.body);
    }
  }
}
```

## Common Patterns

### Email Sending

```tsx
// Send email to queue
"use server";

export async function sendWelcomeEmail(userId: string) {
  await env.EMAIL_QUEUE.send({
    userId,
    template: 'welcome',
    timestamp: new Date().toISOString(),
  });
}
```

```tsx
// Process emails
async queue(batch) {
  if (batch.queue === 'email-queue') {
    for (const message of batch.messages) {
      const { userId, template } = message.body;
      const user = await db.user.findUnique({ where: { id: userId } });

      await sendEmail({
        to: user.email,
        subject: getSubject(template),
        html: renderTemplate(template, user),
      });
    }
  }
}
```

### Image Processing

```tsx
// Send image processing job
export async function processUploadedImage(imageKey: string) {
  await env.IMAGE_QUEUE.send({
    imageKey,
    operations: ['resize', 'optimize', 'thumbnail'],
  });
}
```

```tsx
// Process images
async queue(batch) {
  if (batch.queue === 'image-queue') {
    for (const message of batch.messages) {
      const { imageKey, operations } = message.body;
      const image = await env.R2.get(imageKey);

      for (const operation of operations) {
        const processed = await applyOperation(image, operation);
        await env.R2.put(`${imageKey}-${operation}`, processed);
      }
    }
  }
}
```

### Webhook Delivery

```tsx
// Queue webhook delivery
export async function notifyWebhook(event: string, data: any) {
  const webhooks = await db.webhook.findMany({
    where: { events: { has: event } }
  });

  for (const webhook of webhooks) {
    await env.WEBHOOK_QUEUE.send({
      url: webhook.url,
      event,
      data,
      attempt: 0,
    });
  }
}
```

```tsx
// Deliver webhooks with retry
async queue(batch) {
  if (batch.queue === 'webhook-queue') {
    for (const message of batch.messages) {
      const { url, event, data, attempt } = message.body;

      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ event, data }),
        });

        if (!response.ok && attempt < 3) {
          // Retry
          await env.WEBHOOK_QUEUE.send({
            ...message.body,
            attempt: attempt + 1,
          });
        }
      } catch (error) {
        console.error('Webhook delivery failed:', error);
      }
    }
  }
}
```

### Scheduled Reports

```tsx
// Trigger from cron
export default {
  async scheduled(controller: ScheduledController) {
    if (controller.cron === '0 9 * * *') {
      // Daily at 9 AM
      await env.REPORT_QUEUE.send({
        type: 'DAILY_REPORT',
        date: new Date().toISOString(),
      });
    }
  },

  async queue(batch) {
    if (batch.queue === 'report-queue') {
      for (const message of batch.messages) {
        const report = await generateReport(message.body);
        await sendReportEmail(report);
      }
    }
  }
};
```

### AI Processing

```tsx
// Queue AI processing
export async function analyzeContent(contentId: string) {
  await env.AI_QUEUE.send({
    contentId,
    operations: ['sentiment', 'summary', 'keywords'],
  });
}
```

```tsx
// Process with AI
async queue(batch) {
  if (batch.queue === 'ai-queue') {
    for (const message of batch.messages) {
      const { contentId, operations } = message.body;
      const content = await db.content.findUnique({
        where: { id: contentId }
      });

      for (const operation of operations) {
        const result = await runAI(operation, content.text);
        await db.aiResult.create({
          data: { contentId, operation, result }
        });
      }
    }
  }
}
```

## Error Handling

### Retry Logic

```tsx
async queue(batch) {
  for (const message of batch.messages) {
    try {
      await processMessage(message.body);
      message.ack(); // Mark as successfully processed
    } catch (error) {
      console.error('Message processing failed:', error);
      message.retry(); // Retry message
    }
  }
}
```

### Dead Letter Queue

```tsx
async queue(batch) {
  for (const message of batch.messages) {
    try {
      await processMessage(message.body);
    } catch (error) {
      if (message.attempts > 3) {
        // Send to dead letter queue
        await env.DLQ.send({
          originalMessage: message.body,
          error: error.message,
          attempts: message.attempts,
        });
      } else {
        message.retry();
      }
    }
  }
}
```

## Performance Tuning

### Batch Configuration

```jsonc
{
  "consumers": [
    {
      "queue": "my-queue",
      "max_batch_size": 100,     // More messages per batch
      "max_batch_timeout": 30,   // Wait longer for batch to fill
      "max_retries": 3,          // Retry failed messages
      "dead_letter_queue": "dlq" // Dead letter queue
    }
  ]
}
```

### Parallel Processing

```tsx
async queue(batch) {
  // Process messages in parallel
  await Promise.all(
    batch.messages.map(async (message) => {
      try {
        await processMessage(message.body);
      } catch (error) {
        console.error('Failed:', error);
      }
    })
  );
}
```

## Best Practices

1. **Dedicated Queues** - One queue per message type
2. **Small Messages** - Use R2/KV for large payloads
3. **Idempotency** - Handle duplicate messages gracefully
4. **Error Handling** - Always handle errors and retry
5. **Monitoring** - Log processing metrics
6. **Timeouts** - Set appropriate batch timeouts
7. **Dead Letters** - Implement DLQ for failed messages
8. **Type Safety** - Use TypeScript for message types

## Further Reading

- [Cloudflare Queues Documentation](https://developers.cloudflare.com/queues/)
- [Queue API Reference](https://developers.cloudflare.com/queues/reference/javascript-apis/)
- [Queue Pricing](https://developers.cloudflare.com/queues/pricing/)
