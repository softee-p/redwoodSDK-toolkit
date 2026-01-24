---
name: rwsdk-docs
description: Expert assistance for building full-stack React applications on Cloudflare Workers with RedwoodSDK. Use when working with RedwoodSDK projects, building React Server Components on Cloudflare, setting up routing/middleware, creating server functions, implementing authentication with passkeys, building realtime features with Durable Objects and WebSockets, integrating Cloudflare services (email, queues, R2 storage, cron), configuring environment variables, deploying to Cloudflare, or troubleshooting RSC/hydration/request context issues. Covers rwsdk package, defineApp, route, render, server actions, Durable Objects, and Cloudflare Workers platform integration.
---

# RedwoodSDK Coder

Expert assistance for building full-stack React applications with RedwoodSDK deployed to Cloudflare Workers.

## How to Use This Skill

This skill provides **progressive disclosure** - overview here, details in reference files:

1. **Start here** for quick start, core concepts, and common patterns
2. **Read reference files** when you need detailed documentation for specific features
3. **Use "When to Read Reference Files"** section below to find the right reference quickly

The skill will automatically read reference files when needed for your task.

## Overview

RedwoodSDK is a framework for building React Server Components applications on Cloudflare's edge network. It provides:

- **React Server Components** - Server-first rendering with client interactivity
- **Edge Routing** - Fast request handling at Cloudflare's edge
- **Cloudflare Integration** - Native access to D1, R2, Durable Objects, Queues, Email, etc.
- **TypeScript-first** - Full type safety across client and server
- **Vite-powered** - Fast local development with HMR

## Quick Start

### Creating a New Project

```bash
# Create new project
npx create-rwsdk my-project-name

# Install dependencies
cd my-project-name
npm install

# Start dev server
npm run dev
```

### Project Structure

```
my-project/
├── src/
│   ├── worker.tsx              # Main entry point, middleware, routes
│   ├── client.tsx              # Client initialization
│   ├── db.ts                   # Database client (if using DB)
│   ├── session/                # Session management (Durable Objects)
│   ├── app/
│   │   ├── Document.tsx        # HTML document template
│   │   ├── headers.ts          # Security headers middleware
│   │   ├── interruptors.ts     # Auth/validation middleware
│   │   ├── layouts/            # Layout components
│   │   ├── components/         # Shared UI components
│   │   └── pages/              # Route groups
│   │       ├── home/           # Home page routes
│   │       ├── user/           # User auth routes
│   │       └── api/            # API routes
├── wrangler.jsonc              # Cloudflare Workers configuration
├── prisma/schema.prisma        # Database schema (if using Prisma)
└── package.json
```

## Core Concepts

### 1. React Server Components (RSC)

**Default**: All components are server components (rendered on server, streamed as HTML).

```tsx
// Server component - async data fetching
export async function TodoList({ ctx }) {
  const todos = await db.todo.findMany({ where: { userId: ctx.user.id } });

  return (
    <ol>
      {todos.map((todo) => (
        <li key={todo.id}>{todo.title}</li>
      ))}
    </ol>
  );
}
```

**Client components**: Mark with `"use client"` for interactivity.

```tsx
"use client";

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>Count: {count}</button>;
}
```

### 2. Server Functions

Execute code on server from client components. Mark with `"use server"`.

```tsx
"use server";

import { requestInfo } from "rwsdk/worker";
import { getDbClient } from "@/db";

export async function addTodo(formData: FormData) {
  const { ctx } = requestInfo;
  const db = getDbClient();

  const title = formData.get("title");
  await db.todo.create({ data: { title, userId: ctx.user.id } });
}
```

Use in client component:

```tsx
"use client";

import { addTodo } from "./functions";

export function AddTodo() {
  return (
    <form action={addTodo}>
      <input type="text" name="title" />
      <button type="submit">Add</button>
    </form>
  );
}
```

### 3. Routing

Routes defined with `route()` function:

```tsx
import { defineApp, route, prefix, render } from "rwsdk/router";
import { Document } from "@/app/Document";

export default defineApp([
  // Middleware
  setCommonHeaders(),
  setupAuth(),

  // Routes
  render(Document, [
    route("/", HomePage),
    route("/about", AboutPage),
    route("/users/:id", UserProfilePage),  // Dynamic params
    route("/api/data", apiHandler),

    // Group routes with prefix
    prefix("/blog", [
      route("/", BlogListPage),
      route("/:slug", BlogPostPage),
    ]),
  ]),
]);
```

### 4. Middleware & Interruptors

Middleware runs on every request. Interruptors run before specific routes.

```tsx
// Middleware (runs on all requests)
async ({ ctx, request }) => {
  ctx.session = await sessions.load(request);
  ctx.user = await db.user.findUnique({ where: { id: ctx.session.userId } });
}

// Interruptor (runs before specific route)
async function requireAuth({ ctx }) {
  if (!ctx.user) {
    return Response.redirect("/user/login");
  }
}

// Use interruptor
route("/dashboard", [requireAuth, DashboardPage]);
```

### 5. Context

Context is request-scoped data available to server components and functions.

```tsx
// Set in middleware
async ({ ctx }) => {
  ctx.user = await getUser();
  ctx.session = await getSession();
}

// Access in server component
export async function Page({ ctx }) {
  return <h1>Hello, {ctx.user.name}</h1>;
}

// Access in server function
"use server";
import { requestInfo } from "rwsdk/worker";

export async function action() {
  const { ctx } = requestInfo;
  console.log(ctx.user);
}
```

## Common Tasks

Quick reference for common development tasks. See reference files for detailed documentation.

### Adding Features

**New route**: Create component in `src/app/pages/`, add to `worker.tsx` with `route()`. → [routing.md](references/routing.md)

**Server function**: Create `"use server"` file, access context via `requestInfo.ctx`. → [react-server-components.md](references/react-server-components.md)

**Database model**: Edit `schema.prisma`, run migrations, generate types. → [database.md](references/database.md)

**Authentication**: Implement passkeys with session management. → [authentication.md](references/authentication.md)

**Real-time features**: Use WebSockets with Durable Objects. → [realtime.md](references/realtime.md)

**Background jobs**: Set up Cloudflare Queues for async tasks. → [queues.md](references/queues.md)

**Scheduled tasks**: Configure cron triggers in `wrangler.jsonc`. → [cron.md](references/cron.md)

**Email**: Send/receive email with Cloudflare Email. → [email.md](references/email.md)

**File storage**: Upload/download files with R2. → [storage.md](references/storage.md)

### Critical Patterns

**Database client**: Always use `getDbClient()` for request-scoped connections (never import global `db`).

**Server functions**: Access context via `requestInfo.ctx`, not `getRequestInfo()`.

**Real-time updates**: Call `refreshCacheAndSyncClients()` after mutations for atomic updates.

### Deployment

```bash
# Quick deployment
npm run migrate:prd        # Apply migrations
npx wrangler secret put KEY  # Set secrets
npm run release            # Deploy

# Staging
CLOUDFLARE_ENV=staging npm run release
```

See [hosting.md](references/hosting.md) for complete deployment guide including custom domains, environments, and CI/CD.

## Reference Documentation

This skill includes comprehensive reference files for all RedwoodSDK features. Load them as needed:

### Getting Started
- **[quick-start.md](references/quick-start.md)** - Creating projects, development workflow, first routes
- **[api-reference.md](references/api-reference.md)** - Complete API docs for rwsdk packages (worker, router, client)
- **[migrating.md](references/migrating.md)** - Migration guide from 0.x to 1.x versions

### Core Features
- **[routing.md](references/routing.md)** - Routes, middleware, interruptors, HTTP methods, documents
- **[react-server-components.md](references/react-server-components.md)** - RSC, server functions, data fetching
- **[database.md](references/database.md)** - Durable Objects with SQLite, migrations, Kysely queries

### Frontend Features
- **[frontend.md](references/frontend.md)** - Client-side navigation, dark mode, layouts, metadata, styling, shadcn/ui

### Cloudflare Services
- **[storage.md](references/storage.md)** - R2 object storage, file uploads/downloads
- **[queues.md](references/queues.md)** - Background tasks, message queues
- **[email.md](references/email.md)** - Sending/receiving email
- **[cron.md](references/cron.md)** - Scheduled tasks, cron triggers

### Real-time & State
- **[realtime.md](references/realtime.md)** - WebSockets, Durable Objects, renderRealtimeClients
- **[useSyncedState.md](references/useSyncedState.md)** - Bidirectional state sync across clients

### Security & Deployment
- **[authentication.md](references/authentication.md)** - Passkeys, session management
- **[security.md](references/security.md)** - Security headers, CSP, nonces
- **[env-vars.md](references/env-vars.md)** - Environment variables and secrets
- **[hosting.md](references/hosting.md)** - Cloudflare deployment, custom domains

### Advanced Topics
- **[advanced-guides.md](references/advanced-guides.md)** - Debugging, streaming responses, troubleshooting

## Best Practices

### Architecture Principles

1. **Keep it simple** - Avoid over-engineering and unnecessary abstractions
2. **Server-first** - Default to server components, use `"use client"` only when needed
3. **Use native APIs** - Prefer Web APIs over external dependencies
4. **Co-locate code** - Group related features in folders with `routes.ts` files
5. **Edge-optimized** - Leverage Cloudflare's edge network for low latency

### Key Patterns

**Route organization**: Group by feature in `src/app/pages/<feature>/routes.ts`, import with `prefix()`.

**Database**: Always use `getDbClient()` for request-scoped connections (never global `db`).

**Caching**: Implement TTL-based caching to reduce DB/DO calls.

**Security**: Set headers in middleware (see [security.md](references/security.md)), use passkeys for auth.

**Real-time**: Call `refreshCacheAndSyncClients()` after mutations for atomic updates.

**Migrations**: Test locally (`migrate:dev`), then production (`migrate:prd`).

## Critical Requirements

### React Canary (RSC Support)

RedwoodSDK requires React canary releases for Server Components:

```json
{
  "react": "19.3.0-canary-d2908752-20260119",
  "react-dom": "19.3.0-canary-d2908752-20260119",
  "react-server-dom-webpack": "19.3.0-canary-d2908752-20260119"
}
```

**Never** use stable React versions - RSC will break.

### Database Client Pattern

**Always** use request-scoped database clients:

```tsx
// ✅ Correct
const db = getDbClient();

// ❌ Wrong - global client
import { db } from "@/db";
```

### Generate Types After Config Changes

After editing `wrangler.jsonc` or `schema.prisma`:

```bash
npm run generate
# or
npx wrangler types
```

## Troubleshooting

### Quick Fixes

**Database issues**: Use `getDbClient()`, check `wrangler.jsonc` bindings, apply migrations.

**Real-time not working**: Verify `initRealtimeClient()` called, check WebSocket in DevTools, call `renderRealtimeClients()` after mutations.

**RSC errors**: Verify React canary versions, add `"use client"` / `"use server"` directives correctly.

**Build/dev errors**: Clear cache (`rm -rf node_modules/.vite`), regenerate types (`npm run generate`).

### Debug Commands

```bash
VERBOSE=1 npm run dev          # Verbose logging
npx wrangler tail              # View worker logs
npm run types                  # Check TypeScript
rm -rf node_modules/.vite      # Clear cache
```

For detailed troubleshooting including RSC configuration errors, directive scan failures, and request context issues, see [advanced-guides.md](references/advanced-guides.md).

## When to Read Reference Files

Load reference documentation as needed for specific features:

- **Getting started?** → Read [quick-start.md](references/quick-start.md)
- **API questions?** → Read [api-reference.md](references/api-reference.md)
- **Upgrading from 0.x?** → Read [migrating.md](references/migrating.md)
- **Building routes?** → Read [routing.md](references/routing.md)
- **Frontend features?** → Read [frontend.md](references/frontend.md)
- **Adding database?** → Read [database.md](references/database.md)
- **Need auth?** → Read [authentication.md](references/authentication.md)
- **Real-time features?** → Read [realtime.md](references/realtime.md) or [useSyncedState.md](references/useSyncedState.md)
- **Background jobs?** → Read [queues.md](references/queues.md)
- **Scheduled tasks?** → Read [cron.md](references/cron.md)
- **Email handling?** → Read [email.md](references/email.md)
- **File storage?** → Read [storage.md](references/storage.md)
- **Security headers?** → Read [security.md](references/security.md)
- **Deploying?** → Read [hosting.md](references/hosting.md)
- **Environment vars?** → Read [env-vars.md](references/env-vars.md)
- **Debugging or troubleshooting?** → Read [advanced-guides.md](references/advanced-guides.md)

## Summary

This skill provides expert assistance for RedwoodSDK development using **progressive disclosure**:

- **Start here** for overview, quick start, and core concepts
- **Reference files** provide detailed documentation for specific features
- **Use the guide above** to find the right reference file for your task

The skill automatically reads reference files when needed, so you don't need to request them explicitly.

## Resources

- **RedwoodSDK Docs**: https://redwoodsdk.com/
- **Cloudflare Workers**: https://developers.cloudflare.com/workers/
- **React Server Components**: https://react.dev/reference/rsc/server-components
- **Starter Template**: https://github.com/redwoodjs/sdk/tree/main/starter
