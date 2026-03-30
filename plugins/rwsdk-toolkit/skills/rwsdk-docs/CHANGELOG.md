# RedwoodSDK Documentation Changelog

This changelog tracks breaking changes, new patterns, and deprecations in the official RedwoodSDK docs. When working on a project that may have been built with an older version of this skill, review the entries below to identify code that needs updating.

**How to use:** Check the project's code against each entry. If the project uses an old pattern listed under "Before", update it to the "After" pattern. Entries are ordered newest-first.

---

## 2026-03-30 — Docs sync: expanded database, realtime, and error handling docs

Synced all 44 reference files from the official RedwoodSDK repo. Key changes:

### Email guide filenames renamed

The email guide files were renamed upstream (content unchanged):
- `guides/email/1-sending-email.mdx` -> `guides/email/sending-email.mdx`
- `guides/email/2-email-templates.mdx` -> `guides/email/email-templates.mdx`

**Files to check:** Any links or references to the old `1-sending-email.mdx` or `2-email-templates.mdx` filenames.

### Experimental database: new Patterns, Seeding, API Reference, and FAQ sections

`experimental/database.mdx` now includes:
- **Patterns** section: Nesting relational data using Kysely's `jsonObjectFrom` and `jsonArrayFrom` helpers for ORM-like join behavior.
- **Seeding Your Database** section: Using `rwsdk worker-run` to run seed scripts with access to Durable Object bindings.
- **API Reference** section: Formal documentation for `createDb()`, `Database<T>` type, `Migrations` type, and `SqliteDurableObject` base class.
- **FAQ** section: Covers why SQL over ORM, latency considerations, production readiness, backups, and auto-rollback rationale.

**Pattern (database seeding):**
```tsx
// src/scripts/seed.ts
import { db } from "@/db";
export default async () => {
  await db.insertInto("todos").values([...]).execute();
};
```
```json
// package.json
{ "scripts": { "seed": "rwsdk worker-run ./src/scripts/seed.ts" } }
```

**Pattern (relational data):**
```tsx
import { jsonObjectFrom } from "kysely/helpers/sqlite";
const posts = await db.selectFrom("posts").selectAll("posts")
  .select((eb) => [
    jsonObjectFrom(
      eb.selectFrom("users").select(["id", "username"])
        .whereRef("users.id", "=", "posts.userId")
    ).as("author"),
  ]).execute();
```

### Experimental realtime: advanced scoping and persistence

`experimental/realtime.mdx` now includes a full "Advanced: Scoping and Persistence" section:
- **Room IDs** (client-side): Pass a room ID as the third argument to `useSyncedState` for client-side state isolation.
- **Key Handlers** (server-side): `SyncedStateServer.registerKeyHandler()` for server-enforced key scoping based on auth context.
- **Room Transformation**: `SyncedStateServer.registerRoomHandler()` to transform room IDs server-side (e.g., "private" rooms scoped per user).
- **Persisting State**: `registerSetStateHandler()` and `registerGetStateHandler()` for saving/loading state to/from a database.
- **Future Plans**: Offline support (IndexedDB) and durable storage (DO SQLite persistence).

### Router API reference: expanded `except` and error handling

`reference/sdk-router.mdx` now includes comprehensive error handling documentation:
- **`except`**: Expanded with JSX element returns, multiple handlers & nesting, error bubbling between handlers, what errors are caught (middleware, routes, RSC actions), and full type signature.
- **Error Handling** section: `ErrorResponse` class usage, try-catch in route handlers, `except`-based error handling, server-side rendering errors, global error handling via `app.fetch` wrapping with `ctx.waitUntil()` for async monitoring (Sentry, DataDog), and unhandled error behavior.

**Pattern (global error handling):**
```tsx
const app = defineApp([...]);
export default {
  fetch: async (request, env, ctx) => {
    try {
      return await app.fetch(request, env, ctx);
    } catch (error) {
      if (error instanceof ErrorResponse) {
        return new Response(error.message, { status: error.code });
      }
      ctx.waitUntil(sendToMonitoring(error));
      return new Response("Internal Server Error", { status: 500 });
    }
  },
};
```

**Files to check:** Projects referencing the old email guide filenames. Projects using `rwsdk/db` should review the new seeding and patterns sections. Projects with realtime features should review the new scoping and persistence APIs.

---

## 2026-03-23 — Docs sync: new APIs and updated patterns

Synced all 44 reference files from the official RedwoodSDK repo. Key changes:

### Routing: custom HTTP methods and HEAD handling

`route()` method routing now supports a `custom` handler for non-standard HTTP methods (e.g., WebDAV), `config.disableOptions` and `config.disable405` options, and explicit HEAD request handling (HEAD is not auto-mapped from GET).

**Pattern:**
```tsx
route("/resource", {
  GET: () => new Response("OK"),
  custom: (method) => new Response(`Handled ${method}`),
  config: { disableOptions: true },
});
```

### Routing: `DefaultAppContext` type extension

Extend the app context type globally via `global.d.ts`:

```tsx
declare module "rwsdk" {
  interface DefaultAppContext {
    user?: User;
  }
}
```

### Client navigation: View Transitions and new options

`initClientNavigation()` now accepts `scrollToTop`, `scrollBehavior`, and `onNavigate` options. `navigate()` accepts `history: "replace"` and per-call scroll config. View Transitions are supported via React 19.

**Before:**
```tsx
initClientNavigation();
```

**After:**
```tsx
initClientNavigation({
  scrollToTop: true,
  scrollBehavior: "smooth",
  onNavigate: (url) => analytics.track(url),
});
```

### RSC: middleware arrays in serverQuery/serverAction

`serverQuery` and `serverAction` now accept middleware arrays. The `x-rsc-data-only` header enables data-only fetches. Server functions can return `Response` objects for redirects.

**Pattern:**
```tsx
const getData = serverQuery([authMiddleware], async () => {
  return db.query(...);
});
```

### Security: `response.headers` replaces `headers`

Security middleware now uses `requestInfo.response.headers` instead of the old `headers` property.

**Before:**
```tsx
(rw) => { rw.headers.set("X-Frame-Options", "DENY"); }
```

**After:**
```tsx
({ requestInfo }) => { requestInfo.response.headers.set("X-Frame-Options", "DENY"); }
```

### Vitest: `rwsdk-community/worker` package

Test utilities moved from `rwsdk` to `rwsdk-community/worker`. Uses `vitest-pool-workers` and `defineWorkersConfig` from `@cloudflare/vitest-pool-workers/config`.

**Before:**
```tsx
import { handleVitestRequest } from "rwsdk";
```

**After:**
```tsx
import { handleVitestRequest } from "rwsdk-community/worker";
```

### Experimental database: `rwsdk/db` module and migration rollbacks

Import from `rwsdk/db` module. Migrations now support type inference (no code generation), `Migrations` type, and rollback via `down()` functions.

### Experimental realtime: new import paths and helpers

Import from `rwsdk/use-synced-state/worker` and `rwsdk/use-synced-state/client`. New `syncedStateRoutes` helper and `SYNCED_STATE_SERVER` binding. State is in-memory (wiped on eviction).

### Storybook: simplified setup

Storybook guide no longer references `experimentalRSC` or Prisma mocking. Uses `RequestInfo` type pattern instead.

### Troubleshooting: new sections

Added sections on export conditions (`react-server` vs `default`), MDX compilation errors, file encoding issues, and `VERBOSE=1 pnpm dev` for verbose logging.

**Files to check:** Projects using any of the patterns listed above — especially `headers` → `response.headers`, `rwsdk` → `rwsdk-community/worker` for tests, and old `initClientNavigation()` calls without options.

---

## 2026-02-17 — Document component: remove `<div id="root">` wrapper

The Document component no longer wraps children in a `<div id="root">`. Children render directly inside `<body>`.

**Before:**
```tsx
export const Document = ({ children }) => (
  <html>
    <head>...</head>
    <body>
      <div id="root">{children}</div>
    </body>
  </html>
);
```

**After:**
```tsx
export const Document = ({ children }) => (
  <html>
    <head>...</head>
    <body>
      {children}
    </body>
  </html>
);
```

**Files to check:** Any `Document` component (commonly `src/Document.tsx` or inline in route files). Search for `id="root"` in JSX.

---

## 2026-02-16 — Query parameters: use standard Web API

RedwoodSDK now documents the standard `URL` / `searchParams` API for accessing query parameters. There is no framework-specific query param helper — use the Web API directly.

**Pattern:**
```tsx
route("/search", ({ request }) => {
  const url = new URL(request.url);
  const name = url.searchParams.get("name");
  return <div>Hello, {name}!</div>;
});
```

**Files to check:** Any route handlers that parse query strings. Replace custom parsing with `new URL(request.url).searchParams`.

---

## 2026-02-16 — Client-side navigation is now the default recommendation

`initClientNavigation()` is now the standard way to enable SPA-like navigation. RedwoodSDK uses RSC RPC to emulate client-side navigation.

**Pattern (src/client.tsx):**
```tsx
import { initClient, initClientNavigation } from "rwsdk/client";

initClient();
initClientNavigation();
```

**Files to check:** `src/client.tsx` — ensure `initClientNavigation()` is called after `initClient()`.

---

## 2026-02-16 — Branding: "Redwood" → "RedwoodSDK"

The canonical name is now **RedwoodSDK** (one word, capital R, capital SDK). Update any user-facing text, comments, or documentation that refers to "Redwood SDK" (with space) or just "Redwood" when meaning the SDK.

---

## 2026-02-16 — New guide: Building with AI

A new `guides/build-with-ai.mdx` guide documents:
- `llms.txt` and `llms-full.txt` context files at `https://docs.rwsdk.com/llms.txt`
- Tips for AI-powered development with RedwoodSDK
- Emphasis on "Zero Magic" making code predictable for AI tools

No migration action needed — this is additive.

---

## 2026-02-10 — Dark mode playground moved to community

The dark mode playground example moved from `playground/dark-mode` to `community/playground/dark-mode` in the official repo.

**Files to check:** Any references or links to the dark mode playground path.

---

## 2026-01-27 — Initial skill version

Baseline version of the rwsdk-docs skill covering RedwoodSDK 1.x documentation. Includes all core concepts, guides, experimental features, legacy docs, and API reference.
