# RedwoodSDK useSyncedState

Bidirectional state synchronization across multiple clients using Durable Objects.

**Status**: Experimental

## Overview

`useSyncedState` looks exactly like `useState`, except it has bidirectional syncing with the server.

### What is it?

- Hook that synchronizes state across multiple clients (tabs, devices, users) in real-time
- Server is the source of truth
- Build collaborative features without external realtime service

### Why use it?

- **Realtime**: Updates are instant for all users
- **Native**: Built into RedwoodSDK
- **Cloudflare**: Leverages Durable Objects for coordination

### Use cases

- Chat applications
- Collaborative forms
- Live dashboards
- Presence indicators
- Shared counters
- Collaborative documents

**Note**: Currently stores values in memory within the Durable Object. State is lost if DO is evicted or worker restarts. Use callbacks to persist to database if needed.

## Quick Start

### 1. Setup the Worker

Export `SyncedStateServer` and register its routes:

```tsx
// src/worker.tsx
import { env } from "cloudflare:workers";
import {
  SyncedStateServer,
  syncedStateRoutes,
} from "rwsdk/use-synced-state/worker";
import { defineApp } from "rwsdk/worker";

// 1. Export the Durable Object
export { SyncedStateServer };

export default defineApp([
  // 2. Register the synced state routes
  ...syncedStateRoutes(() => env.SYNCED_STATE_SERVER),
  // ... your other routes
]);
```

### 2. Update Wrangler Config

Add Durable Object binding:

```jsonc
// wrangler.jsonc
{
  "durable_objects": {
    "bindings": [
      {
        "name": "SYNCED_STATE_SERVER",
        "class_name": "SyncedStateServer"
      }
    ]
  },
  "migrations": [
    {
      "tag": "v1",
      "new_sqlite_classes": ["SyncedStateServer"]
    }
  ]
}
```

Run `pnpm generate` to update types.

### 3. Use the Hook

```tsx
// src/components/SharedCounter.tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const SharedCounter = () => {
  // "counter" is the unique key for this piece of state
  // Without a room ID, this state is global across all clients
  const [count, setCount] = useSyncedState(0, "counter");

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount((c) => c + 1)}>Increment</button>
    </div>
  );
};
```

Open component in two browser windows. Clicking increment in one updates the other instantly!

## Rooms: Scoping State

By default, state is global. Use room IDs to scope state to different groups:

```tsx
// src/components/RoomCounter.tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const RoomCounter = ({ roomId }: { roomId: string }) => {
  // State is scoped to this specific room
  // Users in different rooms won't see each other's updates
  const [count, setCount] = useSyncedState(0, "counter", roomId);

  return (
    <div>
      <p>Room: {roomId}</p>
      <p>Count: {count}</p>
      <button onClick={() => setCount((c) => c + 1)}>Increment</button>
    </div>
  );
};
```

Users in `"room-1"` won't see updates from `"room-2"`.

## Advanced Patterns

### Client-Side Room IDs

Pass room ID as third argument to `useSyncedState`:

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const ChatRoom = ({ roomId }: { roomId: string }) => {
  // Each room has its own isolated state
  const [messages, setMessages] = useSyncedState<string[]>(
    [],
    "messages",
    roomId
  );

  return (
    <div>
      {messages.map((msg, i) => (
        <p key={i}>{msg}</p>
      ))}
      {/* Chat UI */}
    </div>
  );
};
```

### Server-Side Key Transformation

Transform keys on the server for server-enforced scoping:

```tsx
// src/worker.tsx
import { requestInfo } from "rwsdk/worker";

SyncedStateServer.registerKeyHandler(async (key, stub) => {
  // Access user ID from request context
  const userId = requestInfo.ctx.userId;

  // Scope keys that start with "user:" to the current user
  if (key.startsWith("user:")) {
    return `${key}:${userId}`;
  }

  return key;
});
```

Then in component:

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const UserSettings = () => {
  // The key handler will transform this to "user:settings:123" (where 123 is userId)
  // Each user gets their own isolated settings
  const [settings, setSettings] = useSyncedState({}, "user:settings");

  // ... settings UI
};
```

### Server-Side Room Transformation

Transform room IDs on the server:

```tsx
// src/worker.tsx
import { requestInfo } from "rwsdk/worker";

SyncedStateServer.registerRoomHandler(async (roomId, reqInfo) => {
  const userId = reqInfo?.ctx?.userId;

  // Transform "private" room requests to user-specific rooms
  if (roomId === "private" && userId) {
    return `user:${userId}`;
  }

  // Pass through other room IDs as-is
  return roomId ?? "syncedState";
});
```

Client requests "private" room, server scopes it to user:

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const PrivateNotes = () => {
  // Server transforms "private" to "user:${userId}" automatically
  const [notes, setNotes] = useSyncedState("", "notes", "private");

  // ... notes UI
};
```

### Persisting State to Database

Register handlers to save/load state:

```tsx
// src/worker.tsx

// Called when state is updated
SyncedStateServer.registerSetStateHandler((key, value) => {
  console.log("State updated:", key, value);

  // Save to database
  // await db.insertInto("synced_state")
  //   .values({ key, value: JSON.stringify(value) })
  //   .onConflict((oc) => oc.column("key").doUpdateSet({ value: JSON.stringify(value) }))
  //   .execute();
});

// Called when state is retrieved
SyncedStateServer.registerGetStateHandler(async (key, value) => {
  // Load from database if value is undefined
  // if (value === undefined) {
  //   const row = await db.selectFrom("synced_state")
  //     .selectAll()
  //     .where("key", "=", key)
  //     .executeTakeFirst();
  //   return row ? JSON.parse(row.value) : undefined;
  // }
  // return value;
});
```

## Common Patterns

### Shared Counter

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const SharedCounter = () => {
  const [count, setCount] = useSyncedState(0, "counter");

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
      <button onClick={() => setCount(count - 1)}>-</button>
    </div>
  );
};
```

### Chat Messages

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";
import { useState } from "react";

export const ChatRoom = ({ roomId }: { roomId: string }) => {
  const [messages, setMessages] = useSyncedState<Array<{ user: string; text: string }>>(
    [],
    "messages",
    roomId
  );
  const [input, setInput] = useState("");

  const sendMessage = () => {
    setMessages([...messages, { user: "Me", text: input }]);
    setInput("");
  };

  return (
    <div>
      <div>
        {messages.map((msg, i) => (
          <div key={i}>
            <strong>{msg.user}:</strong> {msg.text}
          </div>
        ))}
      </div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyPress={(e) => e.key === "Enter" && sendMessage()}
      />
      <button onClick={sendMessage}>Send</button>
    </div>
  );
};
```

### Presence Indicator

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";
import { useEffect } from "react";

export const OnlineUsers = ({ roomId }: { roomId: string }) => {
  const [users, setUsers] = useSyncedState<string[]>([], "online", roomId);
  const userId = "user-123"; // Get from auth context

  useEffect(() => {
    // Add self to online users
    setUsers((prev) => [...prev, userId]);

    // Remove self on unmount
    return () => {
      setUsers((prev) => prev.filter((id) => id !== userId));
    };
  }, []);

  return (
    <div>
      <h3>Online Users ({users.length})</h3>
      <ul>
        {users.map((id) => (
          <li key={id}>{id}</li>
        ))}
      </ul>
    </div>
  );
};
```

### Collaborative Toggle

```tsx
"use client";

import { useSyncedState } from "rwsdk/use-synced-state/client";

export const FeatureToggle = ({ feature }: { feature: string }) => {
  const [enabled, setEnabled] = useSyncedState(false, `feature:${feature}`);

  return (
    <label>
      <input
        type="checkbox"
        checked={enabled}
        onChange={(e) => setEnabled(e.target.checked)}
      />
      {feature} {enabled ? "enabled" : "disabled"}
    </label>
  );
};
```

## Best Practices

1. **Use descriptive keys**: `"chat-messages"` not `"data1"`
2. **Scope with rooms**: Use room IDs for multi-tenant features
3. **Keep state minimal**: Only store what needs to be synced
4. **Persist important data**: Use handlers to save to database
5. **Handle offline**: State syncs when connection returns
6. **Type your state**: Use TypeScript generics for type safety
7. **Clean up on unmount**: Remove data when component unmounts
8. **Use server transforms**: Enforce security with server-side handlers

## Limitations

- **Memory only**: State lost on Durable Object eviction/restart (use persistence handlers)
- **No offline support yet**: Planned for future
- **No built-in durable storage yet**: Planned for future

## Future Plans

- **Offline Support**: Local persistence (IndexedDB) with sync on reconnect
- **Durable Storage**: Built-in persistence to Durable Object's SQLite
- **Conflict Resolution**: Automatic conflict handling for concurrent edits
- **Optimistic Updates**: Client-side updates before server confirmation

## Further Reading

- [RedwoodSDK Realtime](/core/realtime/) - Core realtime infrastructure
- [Durable Objects](https://developers.cloudflare.com/durable-objects/) - Underlying coordination layer
