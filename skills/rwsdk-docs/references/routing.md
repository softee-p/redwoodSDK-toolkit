# RedwoodSDK Routing Reference

## Core Concepts

RedwoodSDK uses `defineApp` to handle requests and return responses. Routes are matched in order, and you can use middleware, interruptors, and HTTP method routing to build your application.

## Basic Setup

```tsx
import { defineApp } from "rwsdk/worker";
import { route } from "rwsdk/router";

export default defineApp([
  // Middleware runs before routes
  function middleware({ request, ctx }) {
    // Modify context
  },

  // Routes
  route("/", () => new Response("Hello, world!")),
  route("/ping", () => new Response("Pong!")),
]);
```

## Matching Patterns

### Static Routes
Match exact pathnames:

```tsx
route("/", ...)
route("/about", ...)
route("/contact", ...)
```

### Parameter Routes
Match dynamic segments with `:param`:

```tsx
route("/users/:id", ({ params }) => {
  return new Response(`User ID: ${params.id}`);
});

route("/users/:id/groups/:groupId", ({ params }) => {
  return new Response(`User ${params.id}, Group ${params.groupId}`);
});
```

### Wildcard Routes
Match remaining segments with `*`:

```tsx
route("/files/*", ({ params }) => {
  return new Response(`File path: ${params.$0}`);
});

route("/docs/*/version/*", ({ params }) => {
  return new Response(`Doc: ${params.$0}, Version: ${params.$1}`);
});
```

## Request Handlers

Handlers receive a RequestInfo object and can return:
- `Response` - Standard HTTP response
- `JSX` - React component (rendered and streamed to client)

```tsx
route("/text", () => {
  return new Response("Plain text");
});

route("/json", () => {
  return Response.json({ message: "JSON response" });
});

route("/jsx", () => {
  return <div>React component</div>;
});
```

## HTTP Method Routing

Handle different methods on the same path:

```tsx
route("/api/users", {
  get: () => Response.json(users),
  post: ({ request }) => {
    // Create user
    return new Response("Created", { status: 201 });
  },
  delete: () => new Response("Deleted", { status: 204 }),
});
```

### With Interruptors

```tsx
route("/api/users", {
  get: [isAuthenticated, () => Response.json(users)],
  post: [isAuthenticated, validateUser, createUserHandler],
});
```

### Custom Methods

```tsx
route("/api/search", {
  custom: {
    report: () => new Response("Report data"),
  },
});
```

### Configuration

```tsx
route("/api/users", {
  get: () => new Response("OK"),
  config: {
    disableOptions: true,  // OPTIONS returns 405
    disable405: true,      // Unsupported methods fall through to 404
  },
});
```

## Interruptors (Route Middleware)

Execute functions in sequence before the final handler:

```tsx
function isAuthenticated({ ctx }) {
  if (!ctx.user) {
    return new Response("Unauthorized", { status: 401 });
  }
}

route("/blog/:slug/edit", [
  isAuthenticated,
  EditBlogPage
]);
```

Interruptors can:
- Modify context
- Short-circuit with a Response
- Run validation logic
- Check permissions

## Middleware & Context

Middleware runs before route matching and populates `ctx`:

```tsx
defineApp([
  // Middleware
  async function sessionMiddleware({ request, ctx }) {
    const session = await sessionStore.load(request);
    ctx.session = session;
  },

  async function getUserMiddleware({ request, ctx }) {
    if (ctx.session?.userId) {
      ctx.user = await db.user.findUnique({
        where: { id: ctx.session.userId }
      });
    }
  },

  // Routes
  route("/hello", ({ ctx }) => {
    if (!ctx.user) {
      return new Response("Unauthorized", { status: 401 });
    }
    return new Response(`Hello ${ctx.user.username}!`);
  }),
]);
```

## Documents

Documents define the HTML shell for your application:

```tsx
import { render } from "rwsdk/router";
import { Document } from "@/pages/Document";
import { HomePage } from "@/pages/HomePage";

export default defineApp([
  render(Document, [
    route("/", HomePage)
  ])
]);
```

Document component:

```tsx
export const Document = ({ children }) => (
  <html lang="en">
    <head>
      <meta charSet="utf-8" />
      <script type="module" src="/src/client.tsx"></script>
    </head>
    <body>
      <div id="root">{children}</div>
    </body>
  </html>
);
```

## Request Info

Access request details in server functions:

```tsx
import { requestInfo } from "rwsdk/worker";

export async function myServerFunction() {
  const { request, response, ctx } = requestInfo;

  // Modify response
  response.status = 404;
  response.headers.set("Cache-Control", "no-store");
}
```

RequestInfo contains:
- `request` - HTTP Request object
- `response` - ResponseInit object
- `ctx` - App context
- `rw` - RedwoodSDK context (includes `nonce`)
- `cf` - Cloudflare Execution Context

## Generating Links

Create type-safe route links:

```tsx
// src/app/shared/links.ts
import { linkFor } from "rwsdk/router";
import type * as Worker from "../../worker";

type App = typeof Worker.default;
export const link = linkFor<App>();
```

Usage:

```tsx
import { link } from "@/shared/links";

// Static route
const accountsHref = link("/accounts");

// Dynamic route
const callDetailsHref = link("/calls/details/:id", { id: call.id });
```

### Prefetching

```tsx
import { link } from "@/shared/links";

export function AboutPageLayout() {
  const aboutHref = link("/about/");

  return (
    <>
      <link rel="x-prefetch" href={aboutHref} />
      {/* rest of page */}
    </>
  );
}
```

## Route Organization

Co-locate routes in dedicated files:

```tsx
// src/app/pages/blog/routes.ts
import { route } from "rwsdk/router";

export const routes = [
  route('/', BlogLandingPage),
  route('/post/:postId', BlogPostPage),
  route('/post/:postId/edit', [isAdminUser, BlogAdminPage])
];
```

Import with prefix:

```tsx
// src/worker.tsx
import { prefix } from "rwsdk/router";
import { routes as blogRoutes } from '@/app/pages/blog/routes';

export default defineApp([
  render(Document, [
    route('/', HomePage),
    prefix('/blog', blogRoutes)
  ])
]);
```

## ExportedHandler Pattern

When using Cron, Queues, or Email:

```tsx
export const app = defineApp([
  // routes...
]);

export default {
  fetch: app.fetch,
  async queue(batch) { /* ... */ },
  async scheduled(controller) { /* ... */ },
} satisfies ExportedHandler<Env>;
```

Link generation:

```tsx
import type * as Worker from "../../worker";
type App = typeof Worker.app; // Note: .app instead of .default
export const link = linkFor<App>();
```

## Best Practices

1. **Route Order** - More specific routes before generic ones
2. **Middleware First** - Put middleware at the top of defineApp
3. **Context Population** - Use middleware to populate shared data
4. **Co-location** - Group related routes in separate files
5. **Type Safety** - Use linkFor for type-safe route generation
6. **Interruptors** - Use for route-specific authentication/validation
7. **Error Handling** - Return appropriate status codes
8. **Trailing Slashes** - Optional and normalized internally
