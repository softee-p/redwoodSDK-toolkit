---
description: Safely update or add shadcn/ui components in a RedwoodSDK project with backup/restore
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: [component-names...]
---

Use the rwsdk-shadcn-update skill to safely manage shadcn/ui components.

Components: $ARGUMENTS

Follow the rwsdk-shadcn-update skill workflow:

1. **Phase 0: Setup** — Check for shadcn MCP server, fetch latest rwsdk shadcn guide
2. **Phase 1: Analysis** — Read components.json, detect custom/modified/standard components, create inventory
3. **Phase 2: Operations** — For updates: backup custom components, update via CLI/MCP, restore customizations. For new components: add and verify RSC compliance
4. **Validation** — Run type check and build, test visually on affected pages

Always commit before starting and use the safe-update workflow for modified components.
