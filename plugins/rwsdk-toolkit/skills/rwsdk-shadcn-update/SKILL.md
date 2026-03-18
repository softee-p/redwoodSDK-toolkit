---
name: rwsdk-shadcn-update
description: >
  This skill should be used when the user wants to "add a shadcn component", "update shadcn
  components", "install shadcn", "fix shadcn", "setup shadcn in rwsdk", or manage shadcn/ui
  components in a RedwoodSDK project. Trigger on any mention of shadcn/ui combined with
  RedwoodSDK, including adding new components, updating existing components, troubleshooting
  component rendering issues, configuring components.json, ensuring RSC compliance for shadcn
  components, preserving custom modifications during updates, or setting up the shadcn MCP
  server. Also trigger when the user asks about "use client" directives for interactive shadcn
  components, Radix UI issues, or component backup/restore workflows. This skill detects custom
  components automatically and provides safe update workflows with backup/restore.
---

# shadcn/ui Component Manager for RedwoodSDK

## Overview

General-purpose skill for managing shadcn/ui components in ANY RedwoodSDK project with React Server Components (RSC). This skill detects custom components, handles updates while preserving customizations, and enforces RSC compliance patterns from RedwoodSDK documentation.

**Key capabilities:**
- Automated custom component detection in any project
- Safe component updates with automatic backup/restore
- shadcn MCP server integration (optional but recommended)
- RSC-compliant component usage patterns from RedwoodSDK docs
- Project-specific testing workflows
- Package manager agnostic (pnpm, yarn, npm)

**Requirements:**
- RedwoodSDK project with shadcn/ui configured
- Access to `rwsdk-docs` skill (fetches latest shadcn guide from RedwoodSDK docs)
- Optional: shadcn MCP server for enhanced component management

---

## How This Skill Works

This skill provides a safe workflow for ANY RedwoodSDK project:

1. **Checks for shadcn MCP server** - Offers to install if not available
2. **Fetches latest shadcn guide** from RedwoodSDK docs using `rwsdk-docs` skill
3. **Detects custom components** in your specific project
4. **Creates a custom update/addition plan** based on your setup
5. **Executes safely** with backup, update, restore, and validation

---

## Phase 0: Setup & Prerequisites

### Check for shadcn MCP Server

**CRITICAL: Before starting any component work, check if the shadcn MCP server is available.**

**Check for MCP server availability:**
```typescript
// Check if MCP tools are available:
// - mcp__shadcn__*
```

**If NOT available:**

1. Ask the user if they want to install the shadcn MCP server
2. If yes, fetch the installation guide from https://ui.shadcn.com/docs/mcp
3. Follow the official guide to install the MCP server
4. Verify installation by checking for MCP tools again

**If available or user declines:**
- Proceed with standard shadcn CLI commands (`pnpx shadcn@latest`)
- Note: MCP server provides enhanced functionality but is optional

### Fetch RedwoodSDK shadcn Guide

**Use the `rwsdk-docs` skill to fetch the latest shadcn/ui documentation for RedwoodSDK:**

```
Ask rwsdk-docs skill for:
- Latest shadcn/ui setup guide for RedwoodSDK
- RSC (React Server Components) best practices
- Component usage patterns
- Common pitfalls and solutions
```

This ensures you have the most up-to-date information from the RedwoodSDK documentation.

---

## Phase 1: Project Analysis

**Before any component work, analyze the user's specific project:**

### 1.1 Check components.json Configuration

Read `components.json` to understand:
- Component path aliases (default: `@/app/components/ui`)
- RSC setting (must be `"rsc": true` for RedwoodSDK)
- Style variant (new-york, default, etc.)
- Tailwind configuration paths

### 1.2 Detect Existing Components

List all shadcn components in the project's UI directory:

```bash
# Find all .tsx files in the UI components directory
ls src/app/components/ui/*.tsx  # Adjust path based on components.json aliases
```

### 1.3 Detect Custom/Modified Components

**Scan each component file for customization indicators:**

**Fully Custom Components** (never update via CLI):
- Components not in the standard shadcn registry
- Custom compositions (e.g., DatePicker combining Button + Calendar + Popover)
- Look for: Unique component names, custom logic, multi-component compositions

**Modified Components** (backup before updating):
- Standard shadcn components with customizations
- Look for:
  - Custom `data-*` attributes (e.g., `data-slot`, `data-variant`)
  - Modified variant definitions
  - Additional styling beyond shadcn defaults
  - Custom sub-components or exports

**Standard Components** (safe to update):
- Unchanged from shadcn defaults
- No custom attributes or styling
- Match shadcn registry exactly

**Detection Script:**
```bash
# For each component in src/app/components/ui/:
# 1. Check if component name exists in shadcn registry
# 2. Search for custom data-* attributes
# 3. Look for custom styling patterns
# 4. Check for non-standard exports
```

### 1.4 Create Component Inventory

Output a summary for the user:

```
[INFO] Component Analysis:

Custom Components (never update via CLI):
- [Component Name] - [Reason: composition/custom logic]

Modified Components (backup before updating):
- [Component Name] - [Modifications: data-attributes/styling]

Standard Components (safe to update):
- [List of components]
```

**Document findings** in `references/customizations.md` (create if doesn't exist).

---

## Phase 2: Component Operations

### Updating Existing Components

#### Option A: Quick Update (Standard Components Only)

For components with no customizations:

**Using shadcn CLI:**
```bash
# Detect package manager
PKG_MGR=$(
  if [ -f "pnpm-lock.yaml" ]; then echo "pnpx"
  elif [ -f "yarn.lock" ]; then echo "yarn dlx"
  elif [ -f "package-lock.json" ]; then echo "npx"
  else echo "npx"; fi
)

# Single component
$PKG_MGR shadcn@latest add input --overwrite

# Multiple components
$PKG_MGR shadcn@latest add input alert label --overwrite
```

**Using shadcn MCP** (if available):
```
Use MCP tool: mcp__shadcn__add_component
Parameters: component="input", overwrite=true
```

#### Option B: Safe Update (All Components)

For projects with custom/modified components, use the automated workflow:

**1. Backup custom/modified components:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-shadcn-update/scripts/backup-components.sh
```

**2. Update standard components:**
```bash
# Via CLI or MCP as detected in Phase 0
$PKG_MGR shadcn@latest add [component-list] --overwrite
```

**3. Restore custom/modified components:**
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-shadcn-update/scripts/restore-components.sh
```

**4. Validate:**
```bash
# Detect package manager
PKG_MGR=$(
  if [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "package-lock.json" ]; then echo "npm"
  else echo "npm"; fi
)

# Type check
$PKG_MGR run types

# Build
$PKG_MGR run build
```

#### Full Automated Workflow

Run the safe-update script (detects package manager, backs up, updates, restores, validates):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-shadcn-update/scripts/safe-update.sh
```

---

### Adding New Components

**1. Check RedwoodSDK docs** (via `rwsdk-docs` skill) for component-specific guidance

**2. Add component:**

**Using shadcn CLI:**
```bash
$PKG_MGR shadcn@latest add [component-name]
```

**Using shadcn MCP** (if available):
```
Use MCP tool: mcp__shadcn__add_component
Parameters: component="[component-name]"
```

**3. Verify RSC compliance:**

Check the newly added component for proper RSC usage:

```typescript
// Only add "use client" if the component needs:
// - useState, useEffect, or other React hooks
// - Event handlers (onClick, onChange)
// - Browser APIs (window, document)
```

**Server component pattern (preferred):**
```typescript
// No "use client" directive
import { Button } from "@/app/components/ui/button";

export function MyPage() {
  return <Button>Click me</Button>;
}
```

**Client component pattern (when needed):**
```typescript
"use client";
import { useState } from "react";
import { Dialog, DialogContent } from "@/app/components/ui/dialog";

export function MyDialog() {
  const [open, setOpen] = useState(false);
  return <Dialog open={open} onOpenChange={setOpen}>...</Dialog>;
}
```

**With server functions:**
```typescript
"use client";
import { Button } from "@/app/components/ui/button";
import { myServerAction } from "./actions";

export function Form() {
  return (
    <form action={myServerAction}>
      <Button type="submit">Save</Button>
    </form>
  );
}
```

**4. Test the component:**

```bash
# Type check
$PKG_MGR run types

# Build
$PKG_MGR run build

# Visual test
$PKG_MGR run dev
```

**5. Document if customized:**

If you add customizations, update `references/customizations.md` with:
- Component name
- Type (custom/modified/standard)
- Description of customizations
- Update strategy

---

## Configuration Verification

### components.json Setup

Verify proper configuration for RedwoodSDK:

```json
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",  // Or your preferred style
  "rsc": true,  // CRITICAL: Must be true for RSC support
  "tsx": true,
  "tailwind": {
    "config": "",
    "css": "src/app/styles.css",  // Verify path
    "baseColor": "neutral",  // Or your preferred color
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/app/components",
    "utils": "@/lib/utils",
    "ui": "@/app/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  },
  "iconLibrary": "lucide"  // Or your preferred icon library
}
```

**Critical setting:** `"rsc": true` enables React Server Components support.

**Verify paths match your project structure.** Common variations:
- UI components: `src/app/components/ui` OR `src/components/ui`
- Styles: `src/app/styles.css` OR `src/styles/globals.css`

---

## Validation & Testing

### Automated Validation

After any component operation, run:

```bash
# Detect package manager
PKG_MGR=$(
  if [ -f "pnpm-lock.yaml" ]; then echo "pnpm"
  elif [ -f "yarn.lock" ]; then echo "yarn"
  elif [ -f "package-lock.json" ]; then echo "npm"
  else echo "npm"; fi
)

# Generate types (if script exists)
if grep -q '"generate"' package.json; then
  $PKG_MGR run generate
fi

# Type check
if grep -q '"types"' package.json; then
  $PKG_MGR run types
fi

# Build
$PKG_MGR run build
```

### Manual Testing

Create a project-specific testing plan based on where components are used:

**1. Identify key pages** that use shadcn components:
```bash
# Search for component imports across the project
grep -r "from \"@/app/components/ui" src/ --include="*.tsx" --include="*.ts"
```

**2. Test each page:**
- Load the page in development mode
- Verify component rendering
- Test interactive features (if client components)
- Check for console errors

**3. Common areas to test** (adapt to your project):
- Forms (Input, Button, Label, Textarea, Select)
- Dialogs/Modals (Dialog, AlertDialog, Sheet)
- Data display (Table, Card, Avatar)
- Navigation (Breadcrumb, Tabs)
- Feedback (Alert, Sonner/Toast)

---

## Troubleshooting

### Common Issues

**"Component not working after update":**
- Check if custom attributes were lost (data-slot, custom styles, etc.)
- Restore from `.shadcn-backup/` and compare differences
- Run type check: `$PKG_MGR run types`
- Verify component imports still match

**"Type errors after adding component":**
- Run `$PKG_MGR run generate` (updates Cloudflare/framework types)
- Verify Radix UI dependencies are compatible
- Check if `"rsc": true` in components.json
- Ensure TypeScript version is compatible

**"Component needs client interactivity but breaks as server component":**
- Add `"use client"` directive at the top of your component file
- Import the shadcn component as usual
- Use React hooks (useState, useEffect) as needed
- Verify no server-only APIs are used in client components

**"shadcn MCP not working":**
- Verify MCP server is properly installed (check https://ui.shadcn.com/docs/mcp)
- Check MCP server is running
- Verify MCP tools are available in the tool list
- Fall back to shadcn CLI if MCP unavailable

**"Custom components lost after update":**
- Check if backup script was run before update
- Look for `.shadcn-backup/` directory
- Restore from git if backup unavailable
- Always commit before running updates in the future

---

## Best Practices

### Before Any Component Operation

1. **Commit current changes** to git
2. **Run project analysis** (Phase 1) if not done recently
3. **Backup** custom/modified components
4. **Fetch latest docs** using `rwsdk-docs` skill

### During Component Operations

1. **Use MCP server** when available for better reliability
2. **Verify RSC compliance** - Default to server components
3. **Test incrementally** - Don't update all components at once
4. **Document customizations** - Update `references/customizations.md`

### After Component Operations

1. **Validate** with automated checks (types, build)
2. **Test visually** on affected pages
3. **Review diffs** for modified components
4. **Commit changes** with descriptive message

### Component Usage Guidelines (from RedwoodSDK)

**Use `rwsdk-docs` skill for latest best practices**, but generally:

1. **Default to server components** - Don't add "use client" unless necessary
2. **Keep "use client" boundary low** - Only mark interactive components as client
3. **Use server functions** for data mutations instead of client-side logic
4. **Avoid nested client components** when possible
5. **Leverage RSC benefits** - Server-side rendering, smaller bundles, better SEO

---

## Scripts Reference

All scripts located in `${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-shadcn-update/scripts/`:

- **backup-components.sh** - Backup custom/modified components to `.shadcn-backup/`
- **restore-components.sh** - Restore components from `.shadcn-backup/`
- **safe-update.sh** - Full automated workflow (backup, update, restore, validate)

**All scripts:**
- Are safe to run multiple times
- Auto-detect package manager (pnpm/yarn/npm)
- Use text markers instead of emojis
- Adapt to project structure

**Customizing scripts** for your project:
- Edit backup-components.sh to list your custom/modified components
- Scripts read from `.shadcn-backup/` directory (gitignored by default)

---

## Additional Resources

**In this skill:**
- **[customizations.md](references/customizations.md)** - Template for documenting component customizations
- **[README.md](README.md)** - How this skill works and how to share it

**External resources (use `rwsdk-docs` skill):**
- RedwoodSDK shadcn/ui guide
- RSC best practices
- Component usage patterns
- Migration guides

**shadcn/ui official:**
- https://ui.shadcn.com/docs - Official documentation
- https://ui.shadcn.com/docs/mcp - MCP server setup guide

---

## Sharing This Skill

This skill is designed to be **general-purpose** and can be shared publicly:

1. **No project-specific code** - Adapts to any RedwoodSDK project
2. **Dynamic documentation** - Fetches latest info via `rwsdk-docs` skill
3. **Custom component detection** - Analyzes each project's specific setup
4. **Package manager agnostic** - Works with pnpm, yarn, or npm
5. **Template-based** - Customizations doc adapts to user's components

**To use in another project:**
1. Install the rwsdk-toolkit plugin or copy the rwsdk-shadcn-update skill directory
2. Ensure `rwsdk-docs` skill is available
3. The skill will detect and adapt to the new project's setup

**Contributing:**
- Keep it general-purpose (no hardcoded component lists)
- Use `rwsdk-docs` skill for framework-specific info
- Update reference docs when new patterns emerge
- Test with different project configurations
