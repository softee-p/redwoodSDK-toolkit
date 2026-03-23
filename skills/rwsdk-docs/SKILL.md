---
name: rwsdk-docs
description: Expert assistance for building full-stack React applications on Cloudflare Workers with RedwoodSDK. Use when working with RedwoodSDK projects, building React Server Components on Cloudflare, setting up routing/middleware, creating server functions, implementing authentication with passkeys, building realtime features with Durable Objects and WebSockets, integrating Cloudflare services (email, queues, R2 storage, cron), configuring environment variables, deploying to Cloudflare, or troubleshooting RSC/hydration/request context issues. Covers rwsdk package, defineApp, route, render, server actions, Durable Objects, and Cloudflare Workers platform integration.
---

# RedwoodSDK Documentation

RedwoodSDK is a React framework for Cloudflare Workers that works as a Vite plugin. It provides SSR, React Server Components, server functions, streaming, and full integration with Cloudflare's platform (D1, R2, Queues, Durable Objects, Email Workers, Cron Triggers).

## How to Use This Skill

Read the relevant reference file(s) based on the user's question. All reference files are `.mdx` (Astro Starlight format) and contain code examples, configuration snippets, and explanations.

**Lookup strategy:** Match the user's question to the closest topic in the index below, then read that file. For broad questions, start with `core/overview.mdx` or `core/routing.mdx`.

**Updating existing projects:** When working on a project that may have been built with an older version of RedwoodSDK or this skill, read [CHANGELOG.md](CHANGELOG.md) first. It lists breaking changes, deprecated patterns, and migration steps ordered newest-first. Apply any relevant updates to the project's code.

## Documentation Index

### Getting Started
| File | Topics |
|------|--------|
| [references/index.mdx](references/index.mdx) | Introduction, design principles (zero magic, composability, web-first), what RedwoodSDK is |
| [references/getting-started/quick-start.mdx](references/getting-started/quick-start.mdx) | Project setup, `create-rwsdk`, `pnpm dev`, `pnpm release`, first route, deployment |
| [references/migrating.mdx](references/migrating.mdx) | Upgrading 0.x to 1.x, breaking changes, peerDependencies migration, `compatibility_date` update, `requestInfo.response.headers` change, `isAction` flag, `resolveSSRValue` removal, D1/Prisma to SQLite DO passkey migration |

### Core Concepts
| File | Topics |
|------|--------|
| [references/core/overview.mdx](references/core/overview.mdx) | Table of contents for all core docs, overview video |
| [references/core/routing.mdx](references/core/routing.mdx) | `defineApp`, `route`, middleware, `ctx`, interrupters, static/parameter/wildcard routes, query parameters, `searchParams`, HTTP methods, `custom` methods, `config.disableOptions`/`config.disable405`, explicit HEAD handling, `render()`, `requestInfo`, `getRequestInfo()`, `DefaultAppContext` type extension, `linkFor`, prefetch, generation-based cache eviction |
| [references/core/react-server-components.mdx](references/core/react-server-components.mdx) | RSC, `"use client"`, `"use server"`, `serverQuery`, `serverAction`, middleware arrays, `x-rsc-data-only` header, Response returns (redirects), Suspense, streaming, `renderToStream`, `renderToString`, `onActionResponse` |
| [references/core/authentication.mdx](references/core/authentication.mdx) | Session management, `defineDurableSession`, Durable Objects, passkey addon, cookies, `sessionStore`, middleware auth, `ErrorResponse` |
| [references/core/security.mdx](references/core/security.mdx) | CSP, nonce (`rw.nonce`), `RouteMiddleware` type, `img-src` directive, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, `setCommonHeaders`, `response.headers` |
| [references/core/storage.mdx](references/core/storage.mdx) | R2 object storage, file upload/download, streaming, `r2_buckets` binding |
| [references/core/email.mdx](references/core/email.mdx) | Cloudflare Email Workers, `send_email` binding, inbound/outbound email, `PostalMime`, `mimetext`, `message.reply()`, `WorkerEntrypoint`, Email Service beta, local testing |
| [references/core/queues.mdx](references/core/queues.mdx) | Cloudflare Queues, `env.QUEUE.send()`, producers/consumers, message payloads (direct/R2/KV), batch processing |
| [references/core/cron.mdx](references/core/cron.mdx) | Cron Triggers, `triggers.crons`, `scheduled` handler, `ScheduledController`, local testing |
| [references/core/env-vars.mdx](references/core/env-vars.mdx) | `.env`, `.dev.vars`, `wrangler types`, `wrangler secret put`, `cloudflare:workers`, staging/production config |
| [references/core/hosting.mdx](references/core/hosting.mdx) | Deployment, `pnpm release`, `CLOUDFLARE_ENV`, staging deployment workflow, `env.staging` config, custom domains, DNS, nameservers, Cloudflare dashboard |

### Guides - Frontend
| File | Topics |
|------|--------|
| [references/guides/frontend/client-side-nav.mdx](references/guides/frontend/client-side-nav.mdx) | SPA navigation, `initClientNavigation`, `navigate`, View Transitions, `scrollBehavior`/`scrollToTop` options, `onNavigate` callback, `history: "replace"`, prefetching, `x-prefetch`, Cache API |
| [references/guides/frontend/layouts.mdx](references/guides/frontend/layouts.mdx) | `layout()` function, `LayoutProps`, nested layouts, `prefix()`, `render()` composition |
| [references/guides/frontend/documents.mdx](references/guides/frontend/documents.mdx) | Custom Document components, HTML structure, per-route documents, hydration |
| [references/guides/frontend/error-handling.mdx](references/guides/frontend/error-handling.mdx) | `onUncaughtError`, `onCaughtError`, `except`, error boundaries, Sentry, React 19 error handling |
| [references/guides/frontend/metadata.mdx](references/guides/frontend/metadata.mdx) | Meta tags, SEO, `<title>`, Open Graph, Twitter cards, React 19 metadata |
| [references/guides/frontend/og-images.mdx](references/guides/frontend/og-images.mdx) | Dynamic OG images, `workers-og`, `ImageResponse`, social sharing |
| [references/guides/frontend/dark-mode.mdx](references/guides/frontend/dark-mode.mdx) | Theme toggle, cookies, FOUC prevention, `prefers-color-scheme`, Tailwind `dark:` variant |
| [references/guides/frontend/public-assets.mdx](references/guides/frontend/public-assets.mdx) | Static files, `public/` directory, images, fonts, favicon |
| [references/guides/frontend/tailwind.mdx](references/guides/frontend/tailwind.mdx) | Tailwind CSS v4, `@tailwindcss/vite`, `@theme` block, `styles.css`, SSR environment stub |
| [references/guides/frontend/shadcn.mdx](references/guides/frontend/shadcn.mdx) | shadcn/ui setup, `components.json`, Toaster/sonner workaround for server components |
| [references/guides/frontend/chakra-ui.mdx](references/guides/frontend/chakra-ui.mdx) | Chakra UI v3, `ChakraProvider`, theming, `createSystem`, color mode, `next-themes` |
| [references/guides/frontend/ark-ui.mdx](references/guides/frontend/ark-ui.mdx) | Ark UI headless components, state machines, accessibility, data attributes, Park UI |
| [references/guides/frontend/storybook.mdx](references/guides/frontend/storybook.mdx) | Storybook setup, stories, `RequestInfo` type, component isolation |

### Guides - Backend & Tooling
| File | Topics |
|------|--------|
| [references/guides/database/drizzle.mdx](references/guides/database/drizzle.mdx) | Drizzle ORM, Cloudflare D1, SQLite, schema, migrations, `drizzle-kit` |
| [references/guides/email/1-sending-email.mdx](references/guides/email/1-sending-email.mdx) | Resend email service, API key setup, text/React/HTML emails |
| [references/guides/email/2-email-templates.mdx](references/guides/email/2-email-templates.mdx) | React Email templates, `@react-email/components`, email preview, Tailwind in email |
| [references/guides/build-with-ai.mdx](references/guides/build-with-ai.mdx) | AI-powered development, `llms.txt`, `llms-full.txt`, AI context files, zero magic, `create-rwsdk`, RSC tips, Cloudflare runtime |
| [references/guides/rsc-streams.mdx](references/guides/rsc-streams.mdx) | Streaming responses, `ReadableStream`, `consumeEventStream`, SSE, Cloudflare AI chat |
| [references/guides/vitest.mdx](references/guides/vitest.mdx) | Vitest integration tests, `rwsdk-community/worker` package, test bridge pattern, `handleVitestRequest`, `vitestInvoke`, `vitest-pool-workers`, `defineWorkersConfig` |
| [references/guides/debugging.mdx](references/guides/debugging.mdx) | VS Code / Cursor debugging, `launch.json`, client/worker breakpoints |
| [references/guides/troubleshooting.mdx](references/guides/troubleshooting.mdx) | RSC config errors, directive scan failures, export conditions (`react-server`/`default`), MDX compilation errors, file encoding issues, `VERBOSE=1` logging, `getRequestInfo()` outside request context, circular dependencies |
| [references/guides/optimize/react-compiler.mdx](references/guides/optimize/react-compiler.mdx) | React Compiler, `babel-plugin-react-compiler`, `@vitejs/plugin-react`, automatic memoization, Vite config, cache clearing, DevTools verification |

### Experimental Features
| File | Topics |
|------|--------|
| [references/experimental/authentication.mdx](references/experimental/authentication.mdx) | Passkey addon, WebAuthn, passwordless auth, biometric login, `npx rwsdk addon passkey` |
| [references/experimental/database.mdx](references/experimental/database.mdx) | SQLite Durable Objects, `rwsdk/db` module, Kysely query builder, `createDb`, migrations, type inference from migrations, `Migrations` type, rollback `down()` functions, CRUD, `SqliteDurableObject` |
| [references/experimental/realtime.mdx](references/experimental/realtime.mdx) | `useSyncedState`, `rwsdk/use-synced-state/worker`/`client` imports, `syncedStateRoutes`, `SYNCED_STATE_SERVER` binding, real-time bidirectional state, rooms, in-memory persistence |

### Legacy
| File | Topics |
|------|--------|
| [references/legacy/realtime.mdx](references/legacy/realtime.mdx) | Deprecated realtime API, `initRealtimeClient`, `realtimeRoute`, `renderRealtimeClients` |

### API Reference
| File | Topics |
|------|--------|
| [references/reference/create-rwsdk.mdx](references/reference/create-rwsdk.mdx) | `create-rwsdk` CLI, `--force`, `--release`, `--pre` flags, project scaffolding |
| [references/reference/sdk-client.mdx](references/reference/sdk-client.mdx) | `initClient`, `transport` parameter, `initClientNavigation`, `ClientNavigationOptions`, `scrollToTop`/`scrollBehavior`/`onNavigate`, `navigate()` with `history`/scroll options, `onActionResponse`, `onRecoverableError`, hydration |
| [references/reference/sdk-router.mdx](references/reference/sdk-router.mdx) | `route`, `prefix`, `render` with `rscPayload`/`ssr` options, `except` with JSX returns and error bubbling, `ErrorResponse`, `MethodHandlers` type, `config.disable405`/`config.disableOptions`, `custom` methods, explicit HEAD handling |
| [references/reference/sdk-worker.mdx](references/reference/sdk-worker.mdx) | `defineApp`, `app.fetch` pattern, `ErrorResponse`, `requestInfo` (`response`, `rw`, `cf` properties), middleware, `ctx`, `ctx.waitUntil()`, global error handling |

## Topic Quick-Lookup

Use this to find the right file for common questions:

- **Project setup / new project** -> `getting-started/quick-start.mdx`
- **Routing, middleware, defineApp** -> `core/routing.mdx` or `reference/sdk-router.mdx`
- **Server components, "use client", "use server"** -> `core/react-server-components.mdx`
- **Server functions, serverQuery, serverAction** -> `core/react-server-components.mdx`
- **Authentication, sessions, login** -> `core/authentication.mdx` + `experimental/authentication.mdx`
- **Database, D1, Drizzle, SQL** -> `guides/database/drizzle.mdx` + `experimental/database.mdx`
- **File upload/download, R2 storage** -> `core/storage.mdx`
- **Email, sending/receiving** -> `core/email.mdx` + `guides/email/*.mdx`
- **Background jobs, queues** -> `core/queues.mdx`
- **Scheduled tasks, cron** -> `core/cron.mdx`
- **Environment variables, secrets** -> `core/env-vars.mdx`
- **Deployment, hosting, domains** -> `core/hosting.mdx`
- **Security headers, CSP** -> `core/security.mdx`
- **Client navigation, SPA behavior** -> `guides/frontend/client-side-nav.mdx`
- **Layouts, shared UI** -> `guides/frontend/layouts.mdx`
- **Error handling** -> `guides/frontend/error-handling.mdx` + `reference/sdk-router.mdx`
- **SEO, meta tags, OG images** -> `guides/frontend/metadata.mdx` + `guides/frontend/og-images.mdx`
- **Dark mode, theming** -> `guides/frontend/dark-mode.mdx`
- **Tailwind CSS** -> `guides/frontend/tailwind.mdx`
- **shadcn/ui** -> `guides/frontend/shadcn.mdx`
- **Streaming, SSE, AI responses** -> `guides/rsc-streams.mdx`
- **Testing, Vitest** -> `guides/vitest.mdx`
- **Debugging** -> `guides/debugging.mdx`
- **Troubleshooting errors** -> `guides/troubleshooting.mdx`
- **Realtime, WebSockets, synced state** -> `experimental/realtime.mdx`
- **View Transitions** -> `guides/frontend/client-side-nav.mdx`
- **Custom HTTP methods, HEAD requests** -> `core/routing.mdx` + `reference/sdk-router.mdx`
- **Query parameters, searchParams** -> `core/routing.mdx`
- **Building with AI, llms.txt** -> `guides/build-with-ai.mdx`
- **Migration from 0.x** -> `migrating.mdx`
- **API reference (client)** -> `reference/sdk-client.mdx`
- **API reference (router)** -> `reference/sdk-router.mdx`
- **API reference (worker)** -> `reference/sdk-worker.mdx`
