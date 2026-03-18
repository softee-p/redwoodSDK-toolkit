# Common RedwoodSDK Issues

Reference for diagnosing production errors in deployed RedwoodSDK applications.

## JSON Field Parsing

**Error:** `SyntaxError: "[object Object]" is not valid JSON`

**Cause:** SQLite stores JSON as TEXT. When passing from server to client via RSC, the field may already be parsed or incorrectly coerced.

**Pattern to verify:**
```typescript
// Correct - checks type before parsing
function parseJsonField(value: string | object): any {
  if (typeof value === 'string') {
    return JSON.parse(value);
  }
  return value;
}
```

**Common mistakes:**
- `JSON.parse(value)` without type check
- `String(object)` instead of `JSON.stringify(object)` when storing
- Template literals like `\`${object}\`` for serialization

## Server Function Context

**Error:** `Cannot read property 'user' of undefined` in server functions

**Cause:** Incorrect context access pattern.

**Correct pattern:**
```typescript
"use server";
import { requestInfo } from "rwsdk/worker";

export async function myAction() {
  const { ctx } = requestInfo;  // Correct
  // NOT: const { ctx } = getRequestInfo();  // Wrong
}
```

## waitUntil() for Background Tasks

**Error:** `A promise was resolved or rejected from a different request context`

**Cause:** Background tasks not properly wrapped in `waitUntil()`.

**Correct pattern:**
```typescript
"use server";
import { requestInfo } from "rwsdk/worker";

export async function myAction() {
  const { ctx } = requestInfo;

  // Wrap background work
  if (ctx && 'waitUntil' in ctx) {
    ctx.waitUntil(backgroundTask());
  }
}
```

## Realtime Sync

**Error:** Stale data after mutations, clients not updating

**Cause:** Missing or incorrect `renderRealtimeClients()` call.

**Correct pattern:**
```typescript
// After database mutation:
await renderRealtimeClients({
  durableObjectNamespace: env.REALTIME_DURABLE_OBJECT,
  key: "/your-route",  // Scope to specific route
});
```

**Order matters:**
1. Update database
2. Invalidate cache (if using)
3. Call `renderRealtimeClients()`

## Durable Object Initialization

**Error:** High latency on first request, timeouts

**Cause:** DO cold starts, especially for SQLite-backed DOs.

**Mitigations:**
- Enable Smart Placement in `wrangler.jsonc`
- Keep DO state minimal
- Use module-level DB client initialization

## React Canary Versions

**Error:** RSC rendering failures, hydration mismatches

**Cause:** Using stable React instead of canary releases.

**Required versions:**
```json
{
  "react": "19.x.x-canary-*",
  "react-dom": "19.x.x-canary-*",
  "react-server-dom-webpack": "19.x.x-canary-*"
}
```

All three must use the **same** canary version.

## Database Client Pattern

**Error:** Connection issues, "no database" errors

**Cause:** Incorrect database client initialization.

**Correct (module-level, reused):**
```typescript
// db/index.ts
import { createDb } from "rwsdk/db";
import { env } from "cloudflare:workers";

export const db = createDb<Database>(env.DATABASE_DURABLE_OBJECT, "app-db");
```

**Usage in server functions:**
```typescript
"use server";
import { db } from "@/db";

export async function myAction() {
  await db.selectFrom("users").execute();
}
```
