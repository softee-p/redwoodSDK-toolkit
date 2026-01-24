# RedwoodSDK Realtime Reference

## Overview

RedwoodSDK provides built-in realtime updates using Cloudflare Durable Objects and WebSockets for bidirectional communication between clients and server.

**Status**: Experimental

## Core Concepts

Realtime in RedwoodSDK builds on React Server Components:
1. **Event happens** - User action or external trigger
2. **App state updates** - Using RSC action handlers
3. **Re-render triggered** - Automatically or via `renderRealtimeClients()`
4. **Clients re-render** - Server code runs, latest state delivered

No manual subscriptions or diff tracking - just write normal RSC code.

## Setup

### 1. Client Setup

Initialize realtime connection with a key:

```ts
// src/client.tsx
import { initRealtimeClient } from "rwsdk/realtime/client";

initRealtimeClient({
  key: window.location.pathname, // Groups related clients
});
```

### 2. Export Durable Object

```ts
// src/worker.tsx
export { RealtimeDurableObject } from "rwsdk/realtime/durableObject";
```

### 3. Wire Up Worker Route

```ts
// src/worker.tsx
import { realtimeRoute } from "rwsdk/realtime/worker";
import { env } from "cloudflare:workers";

export default defineApp([
  realtimeRoute(() => env.REALTIME_DURABLE_OBJECT),
  // ... your routes
]);
```

### 4. Add to Wrangler Config

```jsonc
// wrangler.jsonc
{
  "durable_objects": {
    "bindings": [
      {
        "name": "REALTIME_DURABLE_OBJECT",
        "class_name": "RealtimeDurableObject",
      },
    ],
  },
}
```

Run `pnpm generate` after updating.

## Scoping Updates with Keys

Each realtime connection is scoped by a `key`. Clients with the same key share updates.

```ts
// All clients in room-42 receive same updates
initRealtimeClient({ key: "/chat/room-42" });
```

All clients with the same `key` connect to the same Durable Object instance.

## Client → Server → Client Updates

Updates from user interaction automatically propagate to all clients:

```tsx
// Server component
const Note = async ({ ctx }: RequestInfo) => {
  return <Editor content={ctx.content} />;
};
```

When one client triggers an action, all clients with the same `key` re-run this server logic.

## Server → Client Updates

Trigger updates for events not originating from user actions:

```ts
import { renderRealtimeClients } from "rwsdk/realtime/worker";
import { env } from "cloudflare:workers";

await renderRealtimeClients({
  durableObjectNamespace: env.REALTIME_DURABLE_OBJECT,
  key: "/note/some-id",
});
```

Use cases:
- Background events
- Notifications
- Admin triggers
- System updates

## Why WebSockets and Durable Objects?

**WebSockets**:
- Persistent, bidirectional connection
- Push updates to client
- Send actions back to server
- Reuse connection for both directions

**Durable Objects**:
- Persist across requests
- Maintain in-memory state
- Coordinate updates between clients
- Natural fit for managing connections

## API Reference

### initRealtimeClient()

```ts
initRealtimeClient({ key?: string }): Promise<void>
```

Initializes the realtime WebSocket client.

Parameters:
- `key` (optional) - Identifies which group of clients this user belongs to

### realtimeRoute()

```ts
realtimeRoute((env) => DurableObjectNamespace): RouteDefinition
```

Connects the WebSocket route in your worker to the Durable Object.

### renderRealtimeClients()

```ts
renderRealtimeClients({
  durableObjectNamespace: DurableObjectNamespace,
  key?: string,
}): Promise<void>
```

Triggers a re-render for all clients with a given key.

Parameters:
- `durableObjectNamespace` - Your binding to the Durable Object
- `key` (optional) - Scope of clients to re-render

## Common Patterns

### Chat Room

```tsx
// Client setup
initRealtimeClient({
  key: `/chat/${roomId}`,
});
```

```tsx
// Server component
export async function ChatRoom({ ctx, roomId }) {
  const messages = await db.message.findMany({
    where: { roomId },
    orderBy: { createdAt: "asc" },
  });

  return (
    <div>
      <MessageList messages={messages} />
      <MessageForm roomId={roomId} />
    </div>
  );
}
```

```tsx
// Server action
"use server";

import { requestInfo } from "rwsdk/worker";
import { renderRealtimeClients } from "rwsdk/realtime/worker";
import { env } from "cloudflare:workers";

export async function sendMessage(formData: FormData) {
  const { ctx } = requestInfo;
  const roomId = formData.get("roomId");
  const text = formData.get("text");

  await db.message.create({
    data: {
      roomId,
      userId: ctx.user.id,
      text,
    },
  });

  // Trigger update for all clients in this room
  await renderRealtimeClients({
    durableObjectNamespace: env.REALTIME_DURABLE_OBJECT,
    key: `/chat/${roomId}`,
  });
}
```

### Collaborative Editor

```tsx
// Client setup
initRealtimeClient({
  key: `/doc/${docId}`,
});
```

```tsx
// Server component
export async function CollaborativeDoc({ ctx, docId }) {
  const doc = await db.document.findUnique({
    where: { id: docId },
  });

  return (
    <div>
      <Editor content={doc.content} docId={docId} />
    </div>
  );
}
```

```tsx
// Server action for auto-save
"use server";

import { requestInfo } from "rwsdk/worker";
import { renderRealtimeClients } from "rwsdk/realtime/worker";
import { env } from "cloudflare:workers";

export async function saveDocument(docId: string, content: string) {
  await db.document.update({
    where: { id: docId },
    data: { content },
  });

  // Update all clients viewing this document
  await renderRealtimeClients({
    durableObjectNamespace: env.REALTIME_DURABLE_OBJECT,
    key: `/doc/${docId}`,
  });
}
```

### Live Dashboard

```tsx
// Client setup
initRealtimeClient({
  key: "/dashboard",
});
```

```tsx
// Server component
export async function Dashboard({ ctx }) {
  const stats = await getStats();

  return (
    <div>
      <h1>Live Dashboard</h1>
      <StatsWidget stats={stats} />
    </div>
  );
}
```

```tsx
// Background update (e.g., from queue handler)
import { renderRealtimeClients } from "rwsdk/realtime/worker";
import { env } from "cloudflare:workers";

export default {
  async queue(batch) {
    // Process queue messages
    for (const message of batch.messages) {
      await processMetric(message.body);
    }

    // Update all dashboard clients
    await renderRealtimeClients({
      durableObjectNamespace: env.REALTIME_DURABLE_OBJECT,
      key: "/dashboard",
    });
  },
};
```

### Presence Indicator

```tsx
// Client setup
initRealtimeClient({
  key: `/presence/${roomId}`,
});
```

```tsx
// Server component with user list
export async function PresenceWidget({ ctx, roomId }) {
  // Track active users in Durable Object
  const activeUsers = await getActiveUsers(roomId);

  return (
    <div>
      <h3>Active Users ({activeUsers.length})</h3>
      <ul>
        {activeUsers.map(user => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </div>
  );
}
```

### Notification System

```tsx
// Client setup
initRealtimeClient({
  key: `/user/${userId}`,
});
```

```tsx
// Server component
export async function NotificationBell({ ctx }) {
  const notifications = await db.notification.findMany({
    where: { userId: ctx.user.id, read: false },
  });

  return (
    <div>
      <Bell count={notifications.length} />
      <NotificationList notifications={notifications} />
    </div>
  );
}
```

```tsx
// Trigger notification from server
"use server";

import { renderRealtimeClients } from "rwsdk/realtime/worker";
import { env } from "cloudflare:workers";

export async function sendNotification(userId: string, message: string) {
  await db.notification.create({
    data: { userId, message, read: false },
  });

  // Update specific user's notifications
  await renderRealtimeClients({
    durableObjectNamespace: env.REALTIME_DURABLE_OBJECT,
    key: `/user/${userId}`,
  });
}
```

## Multiple Keys per Page

You can initialize multiple realtime connections:

```tsx
// Track both room activity and user notifications
initRealtimeClient({ key: `/chat/${roomId}` });
initRealtimeClient({ key: `/user/${userId}` });
```

## Performance Considerations

1. **Key Scoping** - Use specific keys to limit update scope
2. **Batching** - Group updates to minimize re-renders
3. **Selective Re-renders** - Only update affected components
4. **Connection Management** - Clients automatically reconnect
5. **Durable Object Isolation** - Each key gets its own DO instance

## Best Practices

1. **Use Meaningful Keys** - Keys should represent logical groupings
2. **Scope Updates** - Don't broadcast to all clients if not needed
3. **Handle Disconnections** - Clients automatically reconnect
4. **Server-Side Validation** - Always validate actions on server
5. **Optimistic Updates** - Update UI immediately, sync in background
6. **Error Handling** - Handle network errors gracefully
7. **Rate Limiting** - Implement rate limits for actions

## Limitations

- WebSocket connections are persistent (consider connection limits)
- Durable Objects run in single location (consider latency)
- All clients with same key receive same updates
- State is in-memory by default (implement persistence if needed)

## Integration with useSyncedState

For shared state management, see [useSyncedState](/core/usesyncedstate/) which builds on the realtime infrastructure:

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const SharedCounter = ({ roomId }) => {
  const [count, setCount] = useSyncedState(0, "counter", roomId);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
};
```

## Further Reading

- [Cloudflare Durable Objects](https://developers.cloudflare.com/durable-objects/)
- [WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [React Server Components](https://react.dev/reference/rsc/server-components)
