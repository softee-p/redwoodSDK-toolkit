# RedwoodSDK Cron Triggers

Schedule background tasks with Cloudflare Cron Triggers.

## Overview

Cron triggers allow you to schedule background tasks to run at specific intervals. They use standard cron syntax and run automatically in production.

**Important**: Cron triggers only fire automatically after deployment to Cloudflare. The local dev server does NOT schedule jobs automatically, but you can trigger them manually.

## Setup

### 1. Configure wrangler.jsonc

Add cron schedules to the `triggers` section:

```jsonc
{
  "triggers": {
    "crons": [
      "* * * * *",        // Every minute
      "0 * * * *",        // Every hour
      "0 21 * * *"        // Every day at 9 PM UTC
    ]
  }
}
```

### 2. Generate types

```bash
pnpm generate
```

### 3. Implement scheduled handler

Update your worker to export a `scheduled` handler:

```tsx
import { defineApp } from "rwsdk/worker";

const app = defineApp([
  // Your routes...
]);

export default {
  fetch: app.fetch,
  async scheduled(controller: ScheduledController) {
    switch (controller.cron) {
      case "* * * * *": {
        console.log("🧹 Run minute-by-minute cleanups");
        break;
      }
      case "0 * * * *": {
        console.log("📈 Aggregate hourly metrics");
        break;
      }
      case "0 21 * * *": {
        console.log("🌙 Kick off nightly billing at 9 PM UTC");
        break;
      }
      default: {
        console.warn(`Unhandled cron: ${controller.cron}`);
      }
    }
    console.log("⏰ cron processed");
  },
} satisfies ExportedHandler<Env>;
```

## Cron Syntax

Standard cron expression format:

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, 0 and 7 are Sunday)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

### Common Examples

```jsonc
{
  "crons": [
    "*/5 * * * *",      // Every 5 minutes
    "0 0 * * *",        // Every day at midnight
    "0 */6 * * *",      // Every 6 hours
    "0 9 * * 1",        // Every Monday at 9 AM
    "0 0 1 * *"         // First day of every month at midnight
  ]
}
```

## Testing Locally

Trigger cron jobs manually by hitting the scheduler endpoint:

```bash
# Test every-minute cron
curl "http://localhost:5173/cdn-cgi/handler/scheduled?cron=*+*+*+*+*"

# Test hourly cron
curl "http://localhost:5173/cdn-cgi/handler/scheduled?cron=0+*+*+*+*"

# Test daily 9 PM cron
curl "http://localhost:5173/cdn-cgi/handler/scheduled?cron=0+21+*+*+*"
```

Output will show the console logs from your `scheduled` handler.

## Common Patterns

### Database Cleanup

```tsx
async scheduled(controller: ScheduledController) {
  if (controller.cron === "0 2 * * *") {
    // Run at 2 AM daily
    const db = getDbClient();

    // Delete old sessions
    await db.deleteFrom("sessions")
      .where("expiresAt", "<", new Date())
      .execute();

    // Archive old logs
    await db.deleteFrom("logs")
      .where("createdAt", "<", new Date(Date.now() - 90 * 24 * 60 * 60 * 1000))
      .execute();

    console.log("✅ Daily cleanup completed");
  }
}
```

### Analytics Aggregation

```tsx
async scheduled(controller: ScheduledController) {
  if (controller.cron === "0 * * * *") {
    // Run every hour
    const db = getDbClient();

    // Aggregate hourly metrics
    const metrics = await db
      .selectFrom("events")
      .select([
        db.fn.count("id").as("count"),
        "event_type"
      ])
      .where("timestamp", ">=", new Date(Date.now() - 60 * 60 * 1000))
      .groupBy("event_type")
      .execute();

    // Store aggregated data
    await db.insertInto("hourly_metrics")
      .values(metrics.map(m => ({
        hour: new Date(),
        event_type: m.event_type,
        count: Number(m.count)
      })))
      .execute();

    console.log("📊 Hourly aggregation completed");
  }
}
```

### Send Scheduled Emails

```tsx
import { env } from "cloudflare:workers";

async scheduled(controller: ScheduledController) {
  if (controller.cron === "0 9 * * 1") {
    // Every Monday at 9 AM
    const db = getDbClient();

    // Get users who want weekly digest
    const users = await db
      .selectFrom("users")
      .selectAll()
      .where("emailPreferences", "like", "%weekly_digest%")
      .execute();

    // Send digest emails
    for (const user of users) {
      await sendWeeklyDigest(user.email);
    }

    console.log(`📧 Sent ${users.length} weekly digests`);
  }
}
```

### Queue Background Jobs

```tsx
async scheduled(controller: ScheduledController) {
  if (controller.cron === "*/15 * * * *") {
    // Every 15 minutes
    const db = getDbClient();

    // Find pending tasks
    const tasks = await db
      .selectFrom("pending_tasks")
      .selectAll()
      .where("status", "=", "pending")
      .where("scheduledFor", "<=", new Date())
      .limit(100)
      .execute();

    // Queue them for processing
    for (const task of tasks) {
      await env.QUEUE.send({
        taskId: task.id,
        type: task.type,
        data: task.data
      });
    }

    console.log(`⚡ Queued ${tasks.length} tasks`);
  }
}
```

## Multiple Cron Jobs Pattern

Organize multiple scheduled tasks cleanly:

```tsx
async scheduled(controller: ScheduledController) {
  const handlers = {
    "* * * * *": handleMinutely,
    "0 * * * *": handleHourly,
    "0 0 * * *": handleDaily,
    "0 9 * * 1": handleWeekly,
  };

  const handler = handlers[controller.cron];
  if (handler) {
    await handler();
  } else {
    console.warn(`Unhandled cron: ${controller.cron}`);
  }
}

async function handleMinutely() {
  // Minute-by-minute tasks
}

async function handleHourly() {
  // Hourly tasks
}

async function handleDaily() {
  // Daily tasks
}

async function handleWeekly() {
  // Weekly tasks
}
```

## Monitoring in Production

### View Cron Triggers

1. Go to Cloudflare Dashboard
2. Navigate to **Workers & Pages**
3. Click your worker
4. Go to **Settings** tab
5. Scroll to **Cron Triggers** section

### View Execution History

1. In Cron Triggers section, click **View Events**
2. See list of all triggered cron jobs
3. Check execution status and logs

## Best Practices

1. **Use switch statements**: Match cron expressions to their handlers
2. **Handle all crons**: Include default case for unhandled crons
3. **Keep jobs short**: Cron jobs have execution time limits
4. **Use queues for heavy work**: Queue long-running tasks instead of processing in cron
5. **Log completion**: Always log when cron job finishes
6. **Test locally**: Use curl to test before deploying
7. **Monitor production**: Check Cloudflare dashboard for failed executions
8. **Timezone awareness**: Cron runs in UTC, adjust times accordingly

## Limitations

- Cron jobs run in UTC timezone
- Maximum execution time applies (CPU time limits)
- No automatic retries on failure
- Minimum interval is 1 minute
- Local dev server doesn't auto-trigger (manual testing only)

## Further Reading

- [Cloudflare Cron Triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/)
- [Cron Expression Reference](https://crontab.guru/)
