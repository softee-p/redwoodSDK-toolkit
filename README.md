# RedwoodSDK Toolkit

A Claude Code plugin for building full-stack apps with [RedwoodSDK](https://github.com/redwoodjs/sdk) — React Server Components on Cloudflare Workers.

## Installation

Install via the Claude Code plugin menu:

```
/plugin install https://github.com/softee-p/redwoodSDK-toolkit
```

This installs the `rwsdk-toolkit` plugin, which gives you 6 slash commands and 5 skills.

## Slash Commands

| Command | What it does |
|---------|-------------|
| `/rwsdk-toolkit:rwsdk-lookup <topic>` | Look up RedwoodSDK documentation for a specific topic |
| `/rwsdk-toolkit:rwsdk-new <what-to-create>` | Scaffold a new project or add a route, page, or component |
| `/rwsdk-toolkit:rwsdk-fix-frontend <issue>` | Diagnose and fix frontend layout/styling issues (4-phase workflow) |
| `/rwsdk-toolkit:rwsdk-update-components [components...]` | Safely update or add shadcn/ui components with backup/restore |
| `/rwsdk-toolkit:rwsdk-audit [worker-name]` | Audit a deployed RedwoodSDK app for errors and performance issues |
| `/rwsdk-toolkit:rwsdk-update-docs` | Sync the `rwsdk-docs` skill with the latest official docs |

## Skills

The plugin loads these skills automatically for RedwoodSDK projects:

| Skill | What it does |
|-------|-------------|
| `rwsdk-docs` | Full RedwoodSDK docs reference with topic index and changelog |
| `rwsdk-frontend` | Frontend patterns — layouts, dark mode, shadcn, Tailwind |
| `rwsdk-shadcn-update` | Keep shadcn/ui components up to date |
| `rwsdk-audit-deployed` | Audit a deployed RedwoodSDK app |
| `update-rwsdk-docs` | Pull latest docs from the official repo into `rwsdk-docs` |

## Manual Skill Installation

If you prefer to use only specific skills without the full plugin, copy them from `skills/` into your project's `.claude/skills/` directory. Each skill has a `SKILL.md` with usage details.

## Dev Tools

The `dev-plugins/` directory contains third-party tools used to build and maintain this repo — not part of the distributed plugin:

- **`plugin-dev`** — Plugin development toolkit (hooks, commands, agents, MCP, settings)
- **`skill-creator`** — Create, improve, and benchmark skills with eval tooling

Load them locally when contributing:

```bash
claude --plugin-dir ./dev-plugins/plugin-dev
claude --plugin-dir ./dev-plugins/skill-creator
```
