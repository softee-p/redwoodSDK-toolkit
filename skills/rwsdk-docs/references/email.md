# RedwoodSDK Email

Send and receive emails with Cloudflare Email Workers.

## Overview

RedwoodSDK integrates with Cloudflare Email Workers for transactional messaging, inbound mail handling, and replies within the same Worker runtime.

**Important**: Production deliveries require recipients to be verified through Cloudflare Email Routing. For broader transactional delivery to arbitrary recipients, use Cloudflare's Email Service beta or external providers like Resend.

## Setup

### 1. Configure wrangler.jsonc

```jsonc
{
  "send_email": [
    {
      "name": "EMAIL"
    }
  ]
}
```

### 2. Generate types

```bash
pnpm generate
```

### 3. Enable Email Routing

Follow the [Enable Email Workers](https://developers.cloudflare.com/email-routing/email-workers/enable-email-workers/) documentation to deploy your Worker in production.

## Sending Email

### Basic Send

For simple outbound email, just call `env.EMAIL.send()`:

```tsx
import { env } from "cloudflare:workers";
import { createMimeMessage } from "mimetext";

route("/send-email", async () => {
  const msg = createMimeMessage();
  msg.setSender({ name: "Sender Name", addr: "sender@example.com" });
  msg.setRecipient("recipient@example.com");
  msg.setSubject("Hello from Worker");
  msg.addMessage({
    contentType: "text/plain",
    data: "Email body content here",
  });

  const message = new EmailMessage(
    "sender@example.com",
    "recipient@example.com",
    msg.asRaw()
  );

  await env.EMAIL.send(message);
  return Response.json({ ok: true });
});
```

**Note**: In production, recipient must be a verified address in Email Routing.

## Receiving Email

To receive emails, extend the `WorkerEntrypoint` class and implement the `email` handler:

```tsx
import { WorkerEntrypoint } from "cloudflare:workers";
import * as PostalMime from "postal-mime";
import { defineApp } from "rwsdk/worker";

const app = defineApp([
  // Your routes...
]);

export default class DefaultWorker extends WorkerEntrypoint<Env> {
  async email(message: ForwardableEmailMessage) {
    // Parse inbound email
    const parser = new PostalMime.default();
    const rawEmail = new Response((message as any).raw);
    const email = await parser.parse(await rawEmail.arrayBuffer());

    console.log("Received email:", email);

    // Process email...
  }

  override async fetch(request: Request) {
    return await app.fetch(request, this.env, this.ctx);
  }
}
```

### Key Points

- Extend `WorkerEntrypoint` to make the worker handle email
- Implement `email` handler for inbound messages
- Override `fetch` to handle HTTP requests and pass to app
- Use `PostalMime` to parse inbound messages

## Replying to Email

Reply directly to inbound messages without pre-verifying recipients using `message.reply()`:

```tsx
import { createMimeMessage } from "mimetext";

async email(message: ForwardableEmailMessage) {
  // Parse inbound email
  const parser = new PostalMime.default();
  const rawEmail = new Response((message as any).raw);
  const receivedEmail = await parser.parse(await rawEmail.arrayBuffer());

  // Create reply message
  const replyToMessage = createMimeMessage();

  // CRITICAL: In-Reply-To header required for threading
  replyToMessage.setHeader(
    "In-Reply-To",
    message.headers.get("Message-ID") ?? ""
  );

  replyToMessage.setSender({
    name: "Support",
    addr: "support@example.com"
  });
  replyToMessage.setRecipient(receivedEmail.from);
  replyToMessage.setSubject(`Re: ${receivedEmail.subject}`);
  replyToMessage.addMessage({
    contentType: "text/plain",
    data: "Thanks for contacting us!",
  });

  const replyMessage = new EmailMessage(
    "support@example.com",
    message.from,
    replyToMessage.asRaw()
  );

  await message.reply(replyMessage);
}
```

### Reply Requirements

- **In-Reply-To header**: Required for proper threading
- **No pre-verification**: Can reply to any inbound sender
- **Preserves threading**: Headers maintained automatically

## Testing Locally

### Test Sending

Start dev server:

```bash
pnpm dev
```

Visit the send endpoint (e.g., `http://localhost:5173/send-email`). Check console output for the `.eml` file path:

```bash
send_email binding called with the following message:
  /tmp/miniflare-.../email/2dad29db-0a7d-498d-89ab-e961746835c4.eml
```

View the email:

```bash
cat /tmp/miniflare-.../email/2dad29db-0a7d-498d-89ab-e961746835c4.eml
```

### Test Receiving

Send a test email to the local endpoint:

```bash
curl --request POST 'http://localhost:5173/cdn-cgi/handler/email' \
  --url-query 'from=sender@example.com' \
  --url-query 'to=recipient@example.com' \
  --header 'Content-Type: application/json' \
  --data-raw 'Received: from smtp.example.com (127.0.0.1)
        by cloudflare-email.com (unknown) id 4fwwffRXOpyR
        for <recipient@example.com>; Tue, 27 Aug 2024 15:50:20 +0000
From: "John" <sender@example.com>
To: recipient@example.com
Subject: Test Email
Content-Type: text/plain

Hi there!'
```

Check console output for the parsed email object.

## Production Deployment

### Prerequisites

1. Cloudflare zone with Email Routing enabled
2. At least one verified destination address
3. Email Workers enabled in dashboard

### Setup Steps

1. [Configure Email Routing Rules and Addresses](https://developers.cloudflare.com/email-routing/setup/email-routing-addresses/)
2. [Enable Email Workers](https://developers.cloudflare.com/email-routing/email-workers/enable-email-workers/)
3. Deploy worker: `pnpm release`

## Common Patterns

### Send Transactional Email

```tsx
"use server";
import { env } from "cloudflare:workers";
import { createMimeMessage } from "mimetext";

export async function sendWelcomeEmail(email: string, name: string) {
  const msg = createMimeMessage();
  msg.setSender({ name: "Your App", addr: "noreply@example.com" });
  msg.setRecipient(email);
  msg.setSubject("Welcome to Our App!");
  msg.addMessage({
    contentType: "text/html",
    data: `<h1>Welcome, ${name}!</h1><p>Thanks for signing up.</p>`,
  });

  const message = new EmailMessage(
    "noreply@example.com",
    email,
    msg.asRaw()
  );

  await env.EMAIL.send(message);
}
```

### Auto-Reply to Contact Form

```tsx
async email(message: ForwardableEmailMessage) {
  // Parse incoming contact form email
  const parser = new PostalMime.default();
  const email = await parser.parse(
    await new Response((message as any).raw).arrayBuffer()
  );

  // Send auto-reply
  const reply = createMimeMessage();
  reply.setHeader("In-Reply-To", message.headers.get("Message-ID") ?? "");
  reply.setSender({ name: "Support", addr: "support@example.com" });
  reply.setRecipient(email.from);
  reply.setSubject(`Re: ${email.subject}`);
  reply.addMessage({
    contentType: "text/plain",
    data: "Thanks! We received your message and will respond soon.",
  });

  await message.reply(
    new EmailMessage("support@example.com", message.from, reply.asRaw())
  );

  // Store in database or forward to team...
}
```

## Libraries

- **mimetext**: Construct MIME messages
- **PostalMime**: Parse inbound emails
- **React Email** (future): Compose emails with React components

## Further Reading

- [Cloudflare Email Routing](https://developers.cloudflare.com/email-routing/email-workers/)
- [Local Development](https://developers.cloudflare.com/email-routing/email-workers/local-development/)
- [Send Email from Workers](https://developers.cloudflare.com/email-routing/email-workers/send-email-workers/)
- [Reply to Email](https://developers.cloudflare.com/email-routing/email-workers/reply-email-workers/)
- [Email Service Beta](https://blog.cloudflare.com/email-service/)
