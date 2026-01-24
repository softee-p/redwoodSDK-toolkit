# RedwoodSDK API Reference

Complete API reference for RedwoodSDK packages: `rwsdk/worker`, `rwsdk/router`, `rwsdk/client`, and `create-rwsdk`.

## Table of Contents
- [create-rwsdk CLI](#create-rwsdk-cli)
- [rwsdk/worker](#rwsdkworker)
- [rwsdk/router](#rwsdkrouter)
- [rwsdk/client](#rwsdkclient)

---

## create-rwsdk CLI

Command line tool for creating new RedwoodSDK projects.

### Usage

```bash
npx create-rwsdk [project-name] [options]
```

### Arguments

- `[project-name]`: Name of the project directory (optional, prompts if not provided)

### Options

- `-f, --force`: Force overwrite if directory exists
- `--release <version>`: Use specific release version (e.g., `v1.0.0-alpha.1`)
- `--pre`: Use latest pre-release (alpha, beta, rc)
- `-h, --help`: Display help information
- `-V, --version`: Display version number

### Examples

```bash
# Create project with prompt
npx create-rwsdk

# Create project with name
npx create-rwsdk my-awesome-app

# Force overwrite existing directory
npx create-rwsdk my-app --force

# Use latest pre-release
npx create-rwsdk my-app --pre

# Use specific release
npx create-rwsdk my-app --release v1.0.0-alpha.10
```

### After Creation

```bash
cd <project-name>
pnpm install
pnpm dev
```

### How It Works

The CLI:
1. Fetches the latest GitHub release
2. Downloads the attached `tar.gz` file
3. Extracts it to the specified directory
4. Sets up the project structure

---

## rwsdk/worker

The worker module is the entry point for your Cloudflare Worker application.

### defineApp

Main function to define your web application.

**Basic usage:**

```tsx
import { defineApp } from "rwsdk/worker";
import { route } from "rwsdk/router";

const app = defineApp([
  // Middleware
  ({ ctx }) => {
    ctx.timestamp = Date.now();
  },

  // Routes
  route("/", () => new Response("Hello, World!")),
]);

export default {
  fetch: app.fetch,
};
```

**With global error handling:**

```tsx
import { defineApp, ErrorResponse } from "rwsdk/worker";

const app = defineApp([/* routes */]);

export default {
  fetch: async (request: Request, env: Env, ctx: ExecutionContext) => {
    try {
      return await app.fetch(request, env, ctx);
    } catch (error) {
      if (error instanceof ErrorResponse) {
        return new Response(error.message, { status: error.code });
      }

      // Send to monitoring asynchronously
      ctx.waitUntil(
        sendToMonitoring(error).catch((err) => {
          console.error("Failed to send to monitoring:", err);
        })
      );

      console.error("Unhandled error:", error);
      return new Response("Internal Server Error", { status: 500 });
    }
  },
};
```

**Important:** Use `ctx.waitUntil()` when sending errors to monitoring services to prevent worker termination before async operations complete.

### ErrorResponse

Class for structured error responses with status codes.

**Constructor:**

```ts
new ErrorResponse(code: number, message: string)
```

**Usage:**

```tsx
import { ErrorResponse } from "rwsdk/worker";

route("/api/users/:id", async ({ params }) => {
  const user = await getUserById(params.id);
  if (!user) {
    throw new ErrorResponse(404, "User not found");
  }
  return Response.json(user);
});
```

**In middleware:**

```tsx
defineApp([
  async ({ ctx, request, response }) => {
    try {
      ctx.session = await sessions.load(request);
    } catch (error) {
      if (error instanceof ErrorResponse && error.code === 401) {
        await sessions.remove(request, response.headers);
        response.headers.set("Location", "/user/login");
        return new Response(null, {
          status: 302,
          headers: response.headers,
        });
      }
      throw error;
    }
  },
  // Routes...
]);
```

### requestInfo

Singleton object containing request information, available in server functions.

**Properties:**

- `request`: The incoming HTTP [Request](https://developer.mozilla.org/en-US/docs/Web/API/Request)
- `response`: A [ResponseInit](https://fetch.spec.whatwg.org/#responseinit) for configuring response
- `ctx`: Application context
- `rw`: RedwoodSDK-specific context
- `cf`: Cloudflare Execution Context API

**Usage in server functions:**

```tsx
"use server";

import { requestInfo } from "rwsdk/worker";

export async function addTodo(formData: FormData) {
  const { ctx } = requestInfo;
  const title = formData.get("title");
  await db.todo.create({
    data: { title, userId: ctx.user.id }
  });
}
```

---

## rwsdk/router

Lightweight server-side router for RedwoodSDK.

### route

Define routes with path patterns and handlers.

**Basic usage:**

```tsx
import { route } from "rwsdk/router";

route("/", () => new Response("Hello, World!"));
route("/about", () => <AboutPage />);
route("/users/:id", ({ params }) => <UserProfile id={params.id} />);
```

**Method-based routing:**

```tsx
route("/api/users", {
  get: () => Response.json(users),
  post: async ({ request }) => {
    const data = await request.json();
    const user = await createUser(data);
    return Response.json(user, { status: 201 });
  },
  delete: () => new Response("Deleted", { status: 204 }),
});
```

**With middleware:**

```tsx
route("/api/users", {
  get: [isAuthenticated, getUsersHandler],
  post: [isAuthenticated, validateUser, createUserHandler],
});
```

**Custom methods:**

```tsx
route("/api/search", {
  custom: {
    report: () => new Response("Report data"),
  },
});
```

**Configuration:**

```tsx
route("/api/users", {
  get: getHandler,
  config: {
    disable405: true,    // Disable 405 Method Not Allowed
    disableOptions: true, // Disable OPTIONS handling
  },
});
```

**Default behavior:**
- OPTIONS requests return `204 No Content` with `Allow` header
- Unsupported methods return `405 Method Not Allowed` with `Allow` header

**Important:** HEAD requests are NOT automatically mapped to GET handlers. Define HEAD explicitly:

```tsx
route("/api/users", {
  get: getHandler,
  head: getHandler, // Explicit HEAD handler
});
```

### prefix

Group routes with a path prefix.

**Usage:**

```tsx title="app/pages/user/routes.ts"
import { route } from "rwsdk/router";

export const routes = [
  route("/login", LoginPage),
  route("/logout", handleLogout),
];
```

```tsx title="worker.tsx"
import { prefix } from "rwsdk/router";
import { routes as userRoutes } from "@/app/pages/user/routes";

defineApp([
  prefix("/user", userRoutes)
]);

// Matches: /user/login, /user/logout
```

### render

Statically render JSX with configurable SSR and RSC options.

**Signature:**

```ts
render(Document, routes, options?)
```

**Options:**

- `rscPayload` (boolean, default: `true`): Include RSC payload for interactivity
- `ssr` (boolean, default: `true`): Enable SSR beyond 'use client' boundary

**Usage:**

```tsx
import { render } from "rwsdk/router";

export default defineApp([
  // Default: SSR enabled with RSC payload
  render(ReactDocument, [prefix("/app", appRoutes)]),

  // Static rendering: SSR enabled, RSC payload disabled
  render(StaticDocument, [prefix("/docs", docsRoutes)], {
    rscPayload: false
  }),

  // Client-side only: SSR disabled, RSC payload enabled
  render(ReactDocument, [prefix("/spa", spaRoutes)], {
    ssr: false
  }),
]);
```

**When to use:**
- `rscPayload: false`: For static marketing pages with no interactivity
- `ssr: false`: For client components that only work in browser (e.g., canvas, WebGL)

**Note:** Disabling `ssr` requires `rscPayload` to be enabled.

### except

Define error handlers for catching errors in routes, middleware, and RSC actions.

**Basic usage:**

```tsx
import { except, route } from "rwsdk/router";
import { defineApp } from "rwsdk/worker";

export default defineApp([
  except((error) => {
    console.error(error);
    return new Response("Something went wrong", { status: 500 });
  }),

  route("/", () => <HomePage />),
  route("/api/users", async () => {
    throw new Error("Database connection failed");
  }),
]);
```

**Return JSX:**

```tsx
except((error) => {
  return <ErrorPage error={error} />;
})
```

**Nested handlers:**

```tsx
export default defineApp([
  // Global handler
  except((error) => {
    return <GlobalErrorPage error={error} />;
  }),

  prefix("/admin", [
    // Admin-specific handler
    except((error) => {
      if (error instanceof PermissionError) {
        return new Response("Admin Access Denied", { status: 403 });
      }
      // Return void to bubble up to global handler
    }),

    route("/dashboard", AdminDashboard),
  ]),

  route("/", Home),
]);
```

**Error bubbling:**
- Handlers are searched backwards from where error occurred
- Return `void` to let error bubble to next handler
- If handler throws, error bubbles to next handler

**What is caught:**
- Global middleware errors
- Route handler errors
- Route-specific middleware errors
- RSC action errors

**Type signature:**

```ts
function except<T extends RequestInfo = RequestInfo>(
  handler: (
    error: unknown,
    requestInfo: T,
  ) => MaybePromise<React.JSX.Element | Response | void>
): ExceptHandler<T>;
```

### layout

Create shared UI layouts across routes.

**Basic usage:**

```tsx
import { layout, route, render } from "rwsdk/router";

export default defineApp([
  render(Document, [
    layout(AppLayout, [
      route("/", HomePage),
      route("/about", AboutPage),
    ])
  ])
]);
```

**Nested layouts:**

```tsx
export default defineApp([
  render(Document, [
    layout(AppLayout, [
      route("/", HomePage),
      prefix("/admin", [
        layout(AdminLayout, [
          route("/", AdminDashboard),
          route("/users", UserManagement),
        ])
      ])
    ])
  ])
]);

// Result: <AppLayout><AdminLayout><Page /></AdminLayout></AppLayout>
```

**Layout props:**

```tsx
import type { LayoutProps } from "rwsdk/router";

export function AppLayout({ children, requestInfo }: LayoutProps) {
  // children: Wrapped route content
  // requestInfo: Request context (server components only)

  return (
    <div className="app">
      <header>Navigation</header>
      <main>{children}</main>
      <footer>Footer</footer>
    </div>
  );
}
```

**Note:** `requestInfo` is automatically omitted for client components.

---

## rwsdk/client

Client-side functions for hydration, navigation, and interactivity.

### initClient

Initialize React Client to hydrate RSC flight payload.

**Signature:**

```ts
initClient(options?: {
  transport?: Transport;
  hydrateRootOptions?: HydrationOptions;
  handleResponse?: (response: Response) => boolean;
  onHydrated?: () => void;
  onActionResponse?: (response) => boolean | void;
})
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `transport` | `Transport` | Custom transport for server communication (default: `fetchTransport`) |
| `hydrateRootOptions` | `HydrationOptions` | Options passed to React's `hydrateRoot` (includes error handlers) |
| `handleResponse` | `(response: Response) => boolean` | Custom response handler for navigation errors |
| `onHydrated` | `() => void` | Callback after RSC payload committed on client |
| `onActionResponse` | `(response) => boolean \| void` | Hook for action responses; return `true` if handled |

**Basic usage:**

```tsx
import { initClient } from "rwsdk/client";

initClient();
```

**With error handling:**

```tsx
import { initClient } from "rwsdk/client";

initClient({
  hydrateRootOptions: {
    onUncaughtError: (error, errorInfo) => {
      console.error("Uncaught error:", error);
      console.error("Component stack:", errorInfo.componentStack);
      sendToSentry(error, errorInfo);
    },
    onCaughtError: (error, errorInfo) => {
      console.error("Caught error:", error);
      sendToSentry(error, errorInfo);
    },
  },
});
```

**With Sentry:**

```tsx
import { initClient } from "rwsdk/client";
import * as Sentry from "@sentry/browser";

initClient({
  hydrateRootOptions: {
    onUncaughtError: (error, errorInfo) => {
      Sentry.captureException(error, {
        contexts: {
          react: {
            componentStack: errorInfo.componentStack,
            errorBoundary: errorInfo.errorBoundary?.constructor.name,
          },
        },
        tags: { errorType: "uncaught" },
      });
    },
  },
});
```

**Error handler types:**
- `onUncaughtError`: Async errors, event handlers, errors escaping boundaries
- `onCaughtError`: Errors caught by error boundaries
- `onRecoverableError`: Recoverable rendering errors

**Note:** These handlers are client-side only. For server-side errors, use `except`.

**With client-side navigation:**

```tsx
import { initClient, initClientNavigation } from "rwsdk/client";

const { handleResponse, onHydrated } = initClientNavigation();
initClient({ handleResponse, onHydrated });
```

### initClientNavigation

Initialize client-side navigation (SPA behavior).

**Signature:**

```ts
initClientNavigation(options?: ClientNavigationOptions)
```

**Returns:** `{ handleResponse, onHydrated }`

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `scrollToTop` | `boolean` | `true` | Scroll to top after navigation |
| `scrollBehavior` | `'instant' \| 'smooth' \| 'auto'` | `'instant'` | How scrolling happens |
| `onNavigate` | `() => Promise<void> \| void` | — | Callback after history push, before RSC fetch |

**Usage:**

```tsx
import { initClientNavigation, initClient } from "rwsdk/client";

// Default behavior - instant scroll to top
const { handleResponse, onHydrated } = initClientNavigation();
initClient({ handleResponse, onHydrated });
```

```tsx
// Smooth scrolling
initClientNavigation({
  scrollBehavior: "smooth",
});
```

```tsx
// Preserve scroll position
initClientNavigation({
  scrollToTop: false,
});
```

```tsx
// With analytics
initClientNavigation({
  scrollBehavior: "auto",
  onNavigate: async () => {
    await myAnalytics.track(window.location.pathname);
  },
});
```

**How it works:**
1. Intercepts link clicks on `<a>` tags
2. Pushes new URL to browser history
3. Fetches RSC payload with `?__rsc` query parameter
4. Hydrates content on client

**Note:** `onHydrated` callback is required for prefetching and cache management.

### navigate

Programmatically navigate to a new page.

**Signature:**

```ts
navigate(href: string, options?: {
  history?: 'push' | 'replace';
  info?: {
    scrollToTop?: boolean;
    scrollBehavior?: 'instant' | 'smooth' | 'auto';
  };
})
```

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `history` | `'push' \| 'replace'` | `'push'` | How history stack is updated |
| `info.scrollToTop` | `boolean` | `true` | Scroll to top after navigation |
| `info.scrollBehavior` | `'instant' \| 'smooth' \| 'auto'` | `'instant'` | How scrolling happens |

**Usage:**

```tsx
import { navigate } from "rwsdk/client";

// Basic navigation
navigate("/about");

// Replace history entry
navigate("/profile", { history: "replace" });

// Custom scroll behavior
navigate("/dashboard", {
  info: {
    scrollBehavior: "smooth",
  },
});

// Preserve scroll position
navigate("/feed", {
  info: {
    scrollToTop: false,
  },
});
```

**Common use cases:**

```tsx
// After form submission
function handleFormSubmit(event: FormEvent) {
  event.preventDefault();
  navigate("/dashboard");
}

// After login (replace history)
async function handleLogin(credentials: Credentials) {
  await loginUser(credentials);
  navigate("/account", { history: "replace" });
}
```

---

## Error Handling Patterns

### Client-Side Errors

```tsx
// Universal error handling
const redirectToError = () => {
  window.location.replace("/error");
};

// 1. Imperative errors (event handlers, timeouts)
window.addEventListener("error", (event) => {
  console.error("Global error:", event.message);
  redirectToError();
});

// 2. Unhandled promise rejections
window.addEventListener("unhandledrejection", (event) => {
  console.error("Unhandled rejection:", event.reason);
  redirectToError();
});

// 3. React errors
initClient({
  hydrateRootOptions: {
    onUncaughtError: (error, errorInfo) => {
      console.error("React uncaught:", error, errorInfo);
      redirectToError();
    },
    onCaughtError: (error, errorInfo) => {
      console.error("React caught:", error, errorInfo);
      redirectToError();
    },
  },
});
```

### Server-Side Errors

```tsx
// Route-level error handling
export default defineApp([
  except((error) => {
    return <ErrorPage error={error} />;
  }),
  // Routes...
]);

// Global error handling
const app = defineApp([/* routes */]);

export default {
  fetch: async (request, env, ctx) => {
    try {
      return await app.fetch(request, env, ctx);
    } catch (error) {
      if (error instanceof ErrorResponse) {
        return new Response(error.message, { status: error.code });
      }

      ctx.waitUntil(sendToMonitoring(error));

      console.error("Unhandled error:", error);
      return new Response("Internal Server Error", { status: 500 });
    }
  },
};
```

---

## Type Signatures

### RequestInfo

```ts
interface RequestInfo {
  request: Request;
  response: ResponseInit;
  ctx: AppContext;
  rw: RedwoodContext;
  cf: ExecutionContext;
}
```

### RouteHandler

```ts
type RouteHandler =
  | ((requestInfo: RequestInfo) => MaybePromise<Response | React.JSX.Element>)
  | Array<(requestInfo: RequestInfo) => MaybePromise<Response | React.JSX.Element | void>>;
```

### LayoutProps

```ts
interface LayoutProps {
  children: React.ReactNode;
  requestInfo?: RequestInfo; // Only for server components
}
```

### MethodHandlers

```ts
interface MethodHandlers {
  delete?: RouteHandler;
  get?: RouteHandler;
  head?: RouteHandler;
  patch?: RouteHandler;
  post?: RouteHandler;
  put?: RouteHandler;
  config?: {
    disable405?: true;
    disableOptions?: true;
  };
  custom?: {
    [method: string]: RouteHandler;
  };
}
```

---

## Summary

This API reference covers:

- **create-rwsdk**: CLI for project creation
- **rwsdk/worker**: Entry point with `defineApp`, `ErrorResponse`, `requestInfo`
- **rwsdk/router**: Routing with `route`, `prefix`, `render`, `except`, `layout`
- **rwsdk/client**: Client-side with `initClient`, `initClientNavigation`, `navigate`

All APIs are designed to work seamlessly with React Server Components on Cloudflare Workers.
