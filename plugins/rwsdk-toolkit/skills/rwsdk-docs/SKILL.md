---
name: rwsdk-docs
description: >
  This skill should be used when the user is building, debugging, or asking questions about a
  RedwoodSDK (rwsdk) application on Cloudflare Workers. Trigger on any mention of RedwoodSDK,
  rwsdk, defineApp, route(), render(), React Server Components on Cloudflare, server functions,
  serverQuery, serverAction, "use server", Durable Objects, passkey authentication, Cloudflare
  Workers email/queues/R2/cron, wrangler.jsonc, D1 database, requestInfo, getRequestInfo, client
  navigation, prefetch, or RSC hydration issues. Also trigger when the user asks about routing
  patterns, middleware, layouts, error handling, environment variables, deployment, or any
  Cloudflare Workers + React full-stack development — even if they don't explicitly say
  "RedwoodSDK". This is the primary reference for all RedwoodSDK documentation and should be
  consulted before writing or modifying any rwsdk project code.
---

# RedwoodSDK Documentation

RedwoodSDK is a React framework for Cloudflare Workers that works as a Vite plugin. It provides SSR, React Server Components, server functions, streaming, and full integration with Cloudflare's platform (D1, R2, Queues, Durable Objects, Email Workers, Cron Triggers).

## How to Use This Skill

Read the relevant reference file(s) based on the user's question. All reference files are `.mdx` (Astro Starlight format) and contain code examples, configuration snippets, and explanations.

**Lookup strategy:** Match the user's question to the closest topic in the index below, then read that file. For broad questions, start with `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/overview.mdx` or `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/routing.mdx`.

**Updating existing projects:** When working on a project that may have been built with an older version of RedwoodSDK or this skill, read [CHANGELOG.md](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/CHANGELOG.md) first. It lists breaking changes, deprecated patterns, and migration steps ordered newest-first. Apply any relevant updates to the project's code.

## Documentation Index

### Getting Started
| File | Topics |
|------|--------|
| [references/index.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/index.mdx) | Introduction, design principles (zero magic, composability, web-first), what RedwoodSDK is |
| [references/getting-started/quick-start.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/getting-started/quick-start.mdx) | Project setup, `create-rwsdk`, `pnpm dev`, `pnpm release`, first route, deployment |
| [references/migrating.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/migrating.mdx) | Upgrading 0.x to 1.x, breaking changes, peerDependencies migration, `compatibility_date` update, `requestInfo.response.headers` change, `isAction` flag, `resolveSSRValue` removal, D1/Prisma to SQLite DO passkey migration |

### Core Concepts
| File | Topics |
|------|--------|
| [references/core/overview.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/overview.mdx) | Table of contents for all core docs, overview video |
| [references/core/routing.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/routing.mdx) | `defineApp`, `route`, middleware, `ctx`, interrupters, static/parameter/wildcard routes, query parameters, `searchParams`, HTTP methods, `custom` methods, `config.disableOptions`/`config.disable405`, explicit HEAD handling, `render()`, `requestInfo`, `getRequestInfo()`, `DefaultAppContext` type extension, `linkFor`, prefetch, generation-based cache eviction |
| [references/core/react-server-components.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/react-server-components.mdx) | RSC, `"use client"`, `"use server"`, `serverQuery`, `serverAction`, middleware arrays, `x-rsc-data-only` header, Response returns (redirects), Suspense, streaming, `renderToStream`, `renderToString`, `onActionResponse` |
| [references/core/authentication.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/authentication.mdx) | Session management, `defineDurableSession`, Durable Objects, passkey addon, cookies, `sessionStore`, middleware auth, `ErrorResponse` |
| [references/core/security.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/security.mdx) | CSP, nonce (`rw.nonce`), `RouteMiddleware` type, `img-src` directive, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, `setCommonHeaders`, `response.headers` |
| [references/core/storage.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/storage.mdx) | R2 object storage, file upload/download, streaming, `r2_buckets` binding |
| [references/core/email.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/email.mdx) | Cloudflare Email Workers, `send_email` binding, inbound/outbound email, `PostalMime`, `mimetext`, `message.reply()`, `WorkerEntrypoint`, Email Service beta, local testing |
| [references/core/queues.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/queues.mdx) | Cloudflare Queues, `env.QUEUE.send()`, producers/consumers, message payloads (direct/R2/KV), batch processing |
| [references/core/cron.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/cron.mdx) | Cron Triggers, `triggers.crons`, `scheduled` handler, `ScheduledController`, local testing |
| [references/core/env-vars.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/env-vars.mdx) | `.env`, `.dev.vars`, `wrangler types`, `wrangler secret put`, `cloudflare:workers`, staging/production config |
| [references/core/hosting.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/hosting.mdx) | Deployment, `pnpm release`, `CLOUDFLARE_ENV`, staging deployment workflow, `env.staging` config, custom domains, DNS, nameservers, Cloudflare dashboard |

### Guides - Frontend
| File | Topics |
|------|--------|
| [references/guides/frontend/client-side-nav.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/client-side-nav.mdx) | SPA navigation, `initClientNavigation`, `navigate`, View Transitions, `scrollBehavior`/`scrollToTop` options, `onNavigate` callback, `history: "replace"`, prefetching, `x-prefetch`, Cache API |
| [references/guides/frontend/layouts.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/layouts.mdx) | `layout()` function, `LayoutProps`, nested layouts, `prefix()`, `render()` composition |
| [references/guides/frontend/documents.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/documents.mdx) | Custom Document components, HTML structure, per-route documents, hydration |
| [references/guides/frontend/error-handling.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/error-handling.mdx) | `onUncaughtError`, `onCaughtError`, `except`, error boundaries, Sentry, React 19 error handling |
| [references/guides/frontend/metadata.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/metadata.mdx) | Meta tags, SEO, `<title>`, Open Graph, Twitter cards, React 19 metadata |
| [references/guides/frontend/og-images.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/og-images.mdx) | Dynamic OG images, `workers-og`, `ImageResponse`, social sharing |
| [references/guides/frontend/dark-mode.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/dark-mode.mdx) | Theme toggle, cookies, FOUC prevention, `prefers-color-scheme`, Tailwind `dark:` variant |
| [references/guides/frontend/public-assets.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/public-assets.mdx) | Static files, `public/` directory, images, fonts, favicon |
| [references/guides/frontend/tailwind.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/tailwind.mdx) | Tailwind CSS v4, `@tailwindcss/vite`, `@theme` block, `styles.css`, SSR environment stub |
| [references/guides/frontend/shadcn.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/shadcn.mdx) | shadcn/ui setup, `components.json`, Toaster/sonner workaround for server components |
| [references/guides/frontend/chakra-ui.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/chakra-ui.mdx) | Chakra UI v3, `ChakraProvider`, theming, `createSystem`, color mode, `next-themes` |
| [references/guides/frontend/ark-ui.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/ark-ui.mdx) | Ark UI headless components, state machines, accessibility, data attributes, Park UI |
| [references/guides/frontend/storybook.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/storybook.mdx) | Storybook setup, stories, `RequestInfo` type, component isolation |

### Guides - Backend & Tooling
| File | Topics |
|------|--------|
| [references/guides/database/drizzle.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/database/drizzle.mdx) | Drizzle ORM, Cloudflare D1, SQLite, schema, migrations, `drizzle-kit` |
| [references/guides/email/sending-email.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/email/sending-email.mdx) | Resend email service, API key setup, text/React/HTML emails |
| [references/guides/email/email-templates.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/email/email-templates.mdx) | React Email templates, `@react-email/components`, email preview, Tailwind in email |
| [references/guides/build-with-ai.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/build-with-ai.mdx) | AI-powered development, `llms.txt`, `llms-full.txt`, AI context files, zero magic, `create-rwsdk`, RSC tips, Cloudflare runtime |
| [references/guides/rsc-streams.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/rsc-streams.mdx) | Streaming responses, `ReadableStream`, `consumeEventStream`, SSE, Cloudflare AI chat |
| [references/guides/vitest.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/vitest.mdx) | Vitest integration tests, `rwsdk-community/worker` package, test bridge pattern, `handleVitestRequest`, `vitestInvoke`, `vitest-pool-workers`, `defineWorkersConfig` |
| [references/guides/debugging.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/debugging.mdx) | VS Code / Cursor debugging, `launch.json`, client/worker breakpoints |
| [references/guides/troubleshooting.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/troubleshooting.mdx) | RSC config errors, directive scan failures, export conditions (`react-server`/`default`), MDX compilation errors, file encoding issues, `VERBOSE=1` logging, `getRequestInfo()` outside request context, circular dependencies |
| [references/guides/optimize/react-compiler.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/optimize/react-compiler.mdx) | React Compiler, `babel-plugin-react-compiler`, `@vitejs/plugin-react`, automatic memoization, Vite config, cache clearing, DevTools verification |

### Experimental Features
| File | Topics |
|------|--------|
| [references/experimental/authentication.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/authentication.mdx) | Passkey addon, WebAuthn, passwordless auth, biometric login, `npx rwsdk addon passkey` |
| [references/experimental/database.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/database.mdx) | SQLite Durable Objects, `rwsdk/db` module, Kysely query builder, `createDb`, migrations, type inference from migrations, `Migrations` type, rollback `down()` functions, CRUD, `SqliteDurableObject`, nesting relational data (`jsonObjectFrom`/`jsonArrayFrom`), database seeding (`rwsdk worker-run`), API reference (`createDb()`, `Database<T>`, `Migrations`, `SqliteDurableObject`), FAQ |
| [references/experimental/realtime.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/realtime.mdx) | `useSyncedState`, `rwsdk/use-synced-state/worker`/`client` imports, `syncedStateRoutes`, `SYNCED_STATE_SERVER` binding, real-time bidirectional state, rooms, in-memory persistence, advanced scoping (Room IDs, `registerKeyHandler`, `registerRoomHandler`), persisting state (`registerSetStateHandler`, `registerGetStateHandler`), future plans (offline support, durable storage) |

### Legacy
| File | Topics |
|------|--------|
| [references/legacy/realtime.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/legacy/realtime.mdx) | Deprecated realtime API, `initRealtimeClient`, `realtimeRoute`, `renderRealtimeClients` |

### API Reference
| File | Topics |
|------|--------|
| [references/reference/create-rwsdk.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/create-rwsdk.mdx) | `create-rwsdk` CLI, `--force`, `--release`, `--pre` flags, project scaffolding |
| [references/reference/sdk-client.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-client.mdx) | `initClient`, `transport` parameter, `initClientNavigation`, `ClientNavigationOptions`, `scrollToTop`/`scrollBehavior`/`onNavigate`, `navigate()` with `history`/scroll options, `onActionResponse`, `onRecoverableError`, hydration |
| [references/reference/sdk-router.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx) | `route`, `prefix`, `render` with `rscPayload`/`ssr` options, `except` with JSX returns, multiple handlers & nesting, error bubbling, type signature, `ErrorResponse`, `MethodHandlers` type, `config.disable405`/`config.disableOptions`, `custom` methods, explicit HEAD handling, comprehensive error handling (try-catch, global `app.fetch` wrapping, `ctx.waitUntil()` for monitoring, unhandled errors) |
| [references/reference/sdk-worker.mdx](${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-worker.mdx) | `defineApp`, `app.fetch` pattern, `ErrorResponse`, `requestInfo` (`response`, `rw`, `cf` properties), middleware, `ctx`, `ctx.waitUntil()`, global error handling |

## Topic Quick-Lookup

Use this to find the right file for common questions:

- **Project setup / new project** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/getting-started/quick-start.mdx`
- **Routing, middleware, defineApp** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/routing.mdx` or `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx`
- **Server components, "use client", "use server"** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/react-server-components.mdx`
- **Server functions, serverQuery, serverAction** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/react-server-components.mdx`
- **Authentication, sessions, login** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/authentication.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/authentication.mdx`
- **Database, D1, Drizzle, SQL** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/database/drizzle.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/database.mdx`
- **File upload/download, R2 storage** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/storage.mdx`
- **Email, sending/receiving** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/email.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/email/sending-email.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/email/email-templates.mdx`
- **Background jobs, queues** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/queues.mdx`
- **Scheduled tasks, cron** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/cron.mdx`
- **Environment variables, secrets** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/env-vars.mdx`
- **Deployment, hosting, domains** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/hosting.mdx`
- **Security headers, CSP** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/security.mdx`
- **Client navigation, SPA behavior** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/client-side-nav.mdx`
- **Layouts, shared UI** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/layouts.mdx`
- **Error handling** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/error-handling.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx`
- **SEO, meta tags, OG images** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/metadata.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/og-images.mdx`
- **Dark mode, theming** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/dark-mode.mdx`
- **Tailwind CSS** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/tailwind.mdx`
- **shadcn/ui** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/shadcn.mdx`
- **Streaming, SSE, AI responses** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/rsc-streams.mdx`
- **Testing, Vitest** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/vitest.mdx`
- **Debugging** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/debugging.mdx`
- **Troubleshooting errors** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/troubleshooting.mdx`
- **Realtime, WebSockets, synced state** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/realtime.mdx`
- **View Transitions** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/frontend/client-side-nav.mdx`
- **Custom HTTP methods, HEAD requests** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/routing.mdx` + `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx`
- **Query parameters, searchParams** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/core/routing.mdx`
- **Building with AI, llms.txt** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/guides/build-with-ai.mdx`
- **Database seeding, seed script** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/database.mdx`
- **Relational data, joins, jsonObjectFrom** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/experimental/database.mdx`
- **Global error handling, app.fetch wrapping** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx`
- **except handler, error bubbling** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx`
- **Migration from 0.x** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/migrating.mdx`
- **API reference (client)** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-client.mdx`
- **API reference (router)** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-router.mdx`
- **API reference (worker)** -> `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-docs/references/reference/sdk-worker.mdx`
