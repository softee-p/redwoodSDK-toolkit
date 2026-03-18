# RedwoodSDK Toolkit

A Claude Code plugin for building full-stack apps with [RedwoodSDK](https://github.com/redwoodjs/sdk) — React Server Components on Cloudflare Workers.

## Installation

Install via the Claude Code plugin menu:

```
/plugin install https://github.com/softee-p/redwoodSDK-toolkit
```

This installs the `rwsdk` plugin, which provides 6 slash commands and 5 skills.

---

## How It Works

The plugin provides two layers of assistance:

**Skills** — background knowledge layers that Claude loads automatically based on what you're working on. When you mention `defineApp`, `route()`, shadcn components, production errors, or any RedwoodSDK concept, the relevant skill activates without you having to ask for it. Skills carry documentation, workflows, and best practices that Claude uses to answer your questions correctly.

**Slash Commands** — explicit workflows you trigger when you want to kick off a structured multi-step task (scaffold a project, run a production audit, update components, etc.). Commands load the relevant skills internally and follow a defined sequence of steps.

---

## Skills

Skills auto-trigger based on keywords in your conversation. You don't need to invoke them manually.

### `rwsdk-docs` — RedwoodSDK Documentation Reference

The primary knowledge base for all RedwoodSDK development. Contains the full official documentation (50+ `.mdx` files) covering routing, RSC, authentication, storage, email, queues, cron, environment variables, deployment, and all frontend guides.

**Auto-triggers on:** `defineApp`, `route()`, `render()`, `serverQuery`, `serverAction`, `"use server"`, `"use client"`, `requestInfo`, `wrangler.jsonc`, `D1`, Durable Objects, passkey auth, Cloudflare Workers, RSC hydration — and any question about routing, middleware, layouts, deployment, or Cloudflare + React full-stack development.

**What it does:** Maintains a structured index of all doc files. When triggered, Claude reads the relevant reference file(s) for your specific question rather than guessing. It also tracks a `CHANGELOG.md` of breaking changes so that when you open an older project, Claude automatically applies migration fixes.

**Topic coverage:**
- Core: routing, RSC, auth, security, storage, email, queues, cron, env vars, hosting
- Frontend: layouts, dark mode, shadcn, Tailwind v4, client navigation, OG images, metadata, error handling
- Backend: Drizzle ORM/D1, email sending, Vitest, React Compiler
- Experimental: passkey auth, SQLite Durable Objects, realtime synced state
- API reference: `defineApp`, `route`, `render`, `prefix`, `ErrorResponse`, `initClient`

---

### `rwsdk-frontend` — Visual Frontend Debugging

A 4-phase structured workflow for diagnosing and fixing layout, styling, and visual issues in RedwoodSDK apps. Enforces that Claude actually *sees* the running app before making changes, rather than guessing at CSS fixes.

**Auto-triggers on:** "fix layout", "mobile looks broken", "Tailwind not working", "CSS issues", "shadcn component looks wrong", "UI is off", responsive design problems, dark mode issues, Tailwind v4 configuration in RSC.

**Workflow:**

1. **Context Gathering** — Loads `rwsdk-docs` for RSC styling constraints and Tailwind v4 patterns for RSC compatibility
2. **Visual Testing** — Uses browser automation to actually open the dev server and inspect the app at mobile/tablet/desktop viewports, documenting specific broken components with viewport sizes
3. **Design Solution** — Creates a concrete implementation plan based on visual evidence (not code guessing), specifying exact files, classes, and why each change fixes the observed problem
4. **Verification** — Re-tests in the browser after changes to confirm fixes and catch regressions at other breakpoints

**Why it matters:** Reading code alone misses visual problems. This skill enforces seeing the actual rendered output before and after changes.

---

### `rwsdk-shadcn-update` — Safe shadcn/ui Component Management

Manages shadcn/ui components in RedwoodSDK projects while preserving customizations and enforcing RSC compliance. Detects which components have been customized and uses a backup/restore workflow to prevent losing custom code during updates.

**Auto-triggers on:** "add a shadcn component", "update shadcn", "install shadcn", "fix shadcn", shadcn/ui + RedwoodSDK in the same context, "use client" directive questions for interactive components, Radix UI issues.

**Workflow:**

1. **Setup** — Checks for the shadcn MCP server (installs if wanted), fetches the latest shadcn guide from `rwsdk-docs`
2. **Project Analysis** — Reads `components.json`, lists all UI components, and classifies each as: *fully custom* (never update via CLI), *modified* (backup before updating), or *standard* (safe to overwrite)
3. **Component Operations** — For updates: backs up custom/modified components, runs the shadcn CLI or MCP tool, then restores customizations. For additions: adds the component and verifies RSC compliance (`"use client"` only when the component needs hooks or event handlers)
4. **Validation** — Type-checks and builds to confirm nothing broke

**Scripts included** (in `skills/rwsdk-shadcn-update/scripts/`):
- `backup-components.sh` — Backs up custom/modified components to `.shadcn-backup/`
- `restore-components.sh` — Restores from backup after a CLI update
- `safe-update.sh` — Full automated workflow: backup → update → restore → validate

**RSC compliance enforcement:** Defaults to server components. Only adds `"use client"` when the component genuinely needs React hooks, event handlers, or browser APIs.

---

### `rwsdk-audit-deployed` — Production Audit

A 6-phase audit of a deployed RedwoodSDK app using the [cloudflare-observability MCP](https://developers.cloudflare.com/workers/observability/) for real-time worker telemetry.

**Auto-triggers on:** "audit my deployed app", "check production errors", "is my worker healthy", "check logs", "investigate production issues", Cloudflare Worker error rates, latency problems, post-deployment verification.

**Workflow:**

1. **Setup & Discovery** — Auto-detects worker name from `wrangler.jsonc`/`wrangler.toml`, then lists workers via the MCP
2. **Error Analysis (24h)** — Queries recent errors, groups by route (`$metadata.trigger`) and script version to distinguish pre- vs post-deployment issues
3. **Warning Analysis** — Checks for warnings (cross-request promise issues are common in RSC apps)
4. **Current Health Check** — Counts errors in the last hour to confirm whether issues are resolved or ongoing
5. **Performance Metrics (7d)** — Measures avg and P99 latency, grouped by outcome (success/error/cancelled)
6. **Code Quality** — If errors reference code paths, uses `rwsdk-docs` to verify against best practices and checks `references/common-issues.md`

**Output:** A structured audit report with status (HEALTHY / DEGRADED / CRITICAL), metrics table, issue descriptions with root causes, per-route performance, and actionable recommendations.

**Alert thresholds:** Error rate >2% = warning, >5% = critical. P99 latency >3s = warning, >5s = critical.

---

### `update-rwsdk-docs` — Documentation Sync

Keeps the `rwsdk-docs` skill current with the official [redwoodjs/sdk](https://github.com/redwoodjs/sdk) repository.

**Auto-triggers on:** "update the docs", "refresh rwsdk docs", "sync documentation", "docs seem stale/outdated", or after major RedwoodSDK releases.

**Workflow:**

1. Runs `scripts/update-rwsdk-docs.sh` which shallow-clones the official repo, copies `docs/src/content/docs/*` into `skills/rwsdk-docs/references/`, and removes image folders
2. Rebuilds the `SKILL.md` documentation index — reads each new `.mdx` file, extracts topics, updates table entries and quick-lookup section, removes entries for deleted files

---

## Slash Commands

Commands are explicit workflows you invoke. They load the relevant skills and execute a defined sequence of steps.

| Command | What it does |
|---------|-------------|
| `/rwsdk:new <what-to-create>` | Scaffold a new project or add a route, page, or component to an existing one |
| `/rwsdk:fix <issue>` | Run the 4-phase visual frontend debugging workflow |
| `/rwsdk:components [component-names...]` | Add or update shadcn/ui components with safe backup/restore |
| `/rwsdk:audit [worker-name]` | Run the 6-phase production health audit |
| `/rwsdk:docs <topic>` | Look up a specific RedwoodSDK documentation topic |
| `/rwsdk:sync` | Pull the latest docs from the official repo into `rwsdk-docs` |

### Command details

**`/rwsdk:new <what-to-create>`**
Looks up the relevant docs via `rwsdk-docs`, then either runs `pnpm create rwsdk` for new projects or adds the requested feature (route, page, component, API endpoint) to an existing project. Follows RedwoodSDK conventions: `defineApp`/`route()` for routing, server components by default, `serverAction`/`serverQuery` for server functions.

**`/rwsdk:fix <issue>`**
Runs the full `rwsdk-frontend` 4-phase workflow: gathers RSC + Tailwind v4 context, visually inspects the running app, designs a fix based on actual evidence, and includes a browser re-test in the implementation plan.

**`/rwsdk:components [component-names...]`**
Runs the `rwsdk-shadcn-update` workflow: detects package manager, classifies existing components, backs up custom ones, runs shadcn CLI or MCP, restores customizations, and validates with type-check + build.

**`/rwsdk:audit [worker-name]`**
Runs the `rwsdk-audit-deployed` 6-phase workflow and generates a full audit report with health metrics, error analysis, and recommendations.

**`/rwsdk:docs <topic>`**
Uses `rwsdk-docs` to find and read the most relevant reference file for the given topic. Useful for quick lookups without needing to phrase it as a question.

**`/rwsdk:sync`**
Runs `update-rwsdk-docs` to fetch the latest official docs and rebuild the skill index.

---

## Skill Auto-Trigger Examples

You don't need to say "use the skill" — these phrases trigger the relevant skill automatically:

| What you type | Skill that loads |
|--------------|-----------------|
| "How do I add middleware to my route?" | `rwsdk-docs` |
| "My mobile layout is broken" | `rwsdk-frontend` |
| "Add a shadcn Dialog component" | `rwsdk-shadcn-update` |
| "Check if my worker is healthy after the deploy" | `rwsdk-audit-deployed` |
| "The docs seem outdated, refresh them" | `update-rwsdk-docs` |
| "How do I use serverAction with a form?" | `rwsdk-docs` |
| "Tailwind dark mode isn't working in RSC" | `rwsdk-frontend` |
| "Update all my shadcn components" | `rwsdk-shadcn-update` |

---

## Skill Dependencies

Some skills compose with others:

- **`rwsdk-frontend`** → uses `rwsdk-docs` for RSC styling constraints
- **`rwsdk-shadcn-update`** → uses `rwsdk-docs` for the latest shadcn guide
- **`rwsdk-audit-deployed`** → uses `rwsdk-docs` for code quality verification
- **`update-rwsdk-docs`** → updates `rwsdk-docs` itself

---

## Manual Skill Installation

To use individual skills without the full plugin, copy them from `plugins/rwsdk-toolkit/skills/` into your project's `.claude/skills/` directory.

---

## Dev Tools

The `dev-plugins/` directory contains third-party tools used to build and maintain this repo — not part of the distributed plugin:

- **`plugin-dev`** — Plugin development toolkit (hooks, commands, agents, MCP, settings)
- **`skill-creator`** — Create, improve, and benchmark skills with eval tooling

Load them locally when contributing:

```bash
claude --plugin-dir ./dev-plugins/plugin-dev
claude --plugin-dir ./dev-plugins/skill-creator
```
