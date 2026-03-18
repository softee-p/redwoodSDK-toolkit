# RedwoodSDK Toolkit

A Claude Code plugin for building full-stack apps with [RedwoodSDK](https://rwsdk.com) — React Server Components on Cloudflare Workers.

## Installation

**Option 1 — Command:**
```
/plugin install https://github.com/softee-p/redwoodSDK-toolkit
```

**Option 2 — UI:** Run `/plugins` in Claude Code, go to **Add → Marketplace**, and paste the GitHub URL.

This installs the `rwsdk` plugin: 6 slash commands + 5 skills.

---

## How It Works

**Skills** auto-load based on keywords in your conversation — no invocation needed. When you mention `defineApp`, shadcn components, production errors, etc., the relevant skill activates and gives Claude the documentation and workflows to answer correctly.

**Slash Commands** are explicit multi-step workflows (`/rwsdk:new`, `/rwsdk:audit`, etc.) that you invoke when you want a structured task executed from start to finish.

---

## Skills

### `rwsdk-docs` — Documentation Reference

Full official RedwoodSDK docs (50+ `.mdx` files) covering routing, RSC, auth, storage, email, queues, cron, env vars, hosting, and all frontend guides. Also tracks a `CHANGELOG.md` of breaking changes for automatic migration when opening older projects.

**Triggers on:** `defineApp`, `route()`, `serverQuery`, `serverAction`, `"use server"`, `wrangler.jsonc`, `D1`, Durable Objects, Cloudflare Workers, RSC hydration — plus any question about routing, middleware, deployment, or Cloudflare + React full-stack development.

---

### `rwsdk-frontend` — Visual Frontend Debugging

A 4-phase workflow that enforces seeing the running app before making CSS changes.

1. **Context** — loads `rwsdk-docs` for RSC styling constraints
2. **Visual testing** — opens the dev server with browser automation, inspects mobile/tablet/desktop viewports
3. **Solution** — creates a fix plan based on visual evidence, not code guessing
4. **Verification** — re-tests in the browser after changes

**Triggers on:** "fix layout", "mobile looks broken", "Tailwind not working", "UI is off", responsive design issues, dark mode problems.

---

### `rwsdk-shadcn-update` — shadcn/ui Component Management

Adds or updates shadcn/ui components while preserving customizations and enforcing RSC compliance.

1. **Setup** — checks for shadcn MCP server, fetches the latest shadcn guide from `rwsdk-docs`
2. **Analysis** — reads `components.json`, classifies each component as *custom* (skip), *modified* (backup first), or *standard* (safe to overwrite)
3. **Update/add** — backs up custom components, runs shadcn CLI or MCP, restores customizations
4. **Validation** — type-check + build

Includes scripts: `backup-components.sh`, `restore-components.sh`, `safe-update.sh`.

**Triggers on:** "add a shadcn component", "update shadcn", "install shadcn", Radix UI issues, `"use client"` questions for interactive components.

---

### `rwsdk-audit-deployed` — Production Audit

A 6-phase audit via the cloudflare-observability MCP, producing a HEALTHY / DEGRADED / CRITICAL report.

1. **Discovery** — auto-detects worker name from `wrangler.jsonc`, lists workers
2. **Errors (24h)** — groups by route and script version to spot pre/post-deployment regressions
3. **Warnings** — flags cross-request promise issues common in RSC apps
4. **Health check (1h)** — confirms whether issues are resolved or ongoing
5. **Performance (7d)** — avg + P99 latency by outcome
6. **Code quality** — if errors reference code paths, verifies against `rwsdk-docs`

Thresholds: error rate >2% = warning / >5% = critical; P99 >3s / >5s.

**Triggers on:** "audit my deployed app", "check production errors", "is my worker healthy", post-deployment verification.

---

### `update-rwsdk-docs` — Documentation Sync

Shallow-clones the official [redwoodjs/sdk](https://github.com/redwoodjs/sdk) repo, copies the latest docs into `skills/rwsdk-docs/references/`, then rebuilds the `SKILL.md` index to match.

**Triggers on:** "update the docs", "refresh rwsdk docs", "docs seem outdated".

---

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/rwsdk:new <what-to-create>` | Scaffold a new project or add a route/page/component |
| `/rwsdk:fix <issue>` | 4-phase visual frontend debugging |
| `/rwsdk:components [names...]` | Add or update shadcn/ui components safely |
| `/rwsdk:audit [worker-name]` | 6-phase production health audit |
| `/rwsdk:docs <topic>` | Look up a specific documentation topic |
| `/rwsdk:sync` | Sync `rwsdk-docs` with the latest official docs |

---

## Skill Auto-Trigger Examples

| What you type | Skill that loads |
|--------------|-----------------|
| "How do I add middleware to my route?" | `rwsdk-docs` |
| "My mobile layout is broken" | `rwsdk-frontend` |
| "Add a shadcn Dialog component" | `rwsdk-shadcn-update` |
| "Is my worker healthy after the deploy?" | `rwsdk-audit-deployed` |
| "The docs seem outdated, refresh them" | `update-rwsdk-docs` |

---

## Skill Dependencies

- `rwsdk-frontend` → uses `rwsdk-docs` for RSC styling constraints
- `rwsdk-shadcn-update` → uses `rwsdk-docs` for the latest shadcn guide
- `rwsdk-audit-deployed` → uses `rwsdk-docs` for code quality checks
- `update-rwsdk-docs` → updates `rwsdk-docs` itself

---

## Manual Skill Installation

Copy individual skills from `plugins/rwsdk-toolkit/skills/` into your project's `.claude/skills/` directory.

## Dev Tools

Not part of the distributed plugin — used to build and maintain this repo:

- **`plugin-dev`** — Plugin development toolkit
- **`skill-creator`** — Create, improve, and benchmark skills

```bash
claude --plugin-dir ./dev-plugins/plugin-dev
claude --plugin-dir ./dev-plugins/skill-creator
```
