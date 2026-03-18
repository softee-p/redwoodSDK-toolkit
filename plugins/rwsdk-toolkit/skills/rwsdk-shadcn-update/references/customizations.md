# shadcn/ui Component Customizations Template

**This document tracks customizations made to shadcn/ui components in your RedwoodSDK project.**

When you customize a component, add it to the appropriate section below with:
- Component name
- Type (custom/modified/standard)
- Description of customizations
- Update strategy

---

## Component Classification

### Custom Components (Never Update via CLI)

**These are fully custom components not from the shadcn registry.**

**Indicators:**
- Not in shadcn component registry
- Custom compositions (e.g., combining Button + Calendar + Popover)
- Unique component logic
- Project-specific implementations

**Example Entry:**

#### ComponentName.tsx

**Location:** `src/app/components/ui/ComponentName.tsx`

**Type:** Fully custom component (not from shadcn)

**Description:** [Describe what this component does]

**Key Features:**
- [Feature 1]
- [Feature 2]
- [Integration details]

**Update Strategy:**
- Never update via shadcn CLI
- Manually update underlying dependencies if needed (e.g., if it uses Button, update Button separately)
- Test thoroughly after any dependency updates

**Dependencies:**
- [List shadcn components it uses, if any]

---

### Modified Components (Backup Before Updating)

**These are standard shadcn components with customizations.**

**Indicators:**
- Custom `data-*` attributes
- Modified variant definitions
- Additional styling beyond shadcn defaults
- Custom sub-components or exports
- Enhanced functionality

**Example Entry:**

#### component-name.tsx

**Location:** `src/app/components/ui/component-name.tsx`

**Type:** Modified shadcn component

**Customizations:**

1. **Custom attributes:**
   ```tsx
   data-slot="component-name"
   data-variant={variant}
   data-size={size}
   ```

2. **Enhanced styling:**
   ```tsx
   // Describe custom styling added
   focus-visible:ring-custom
   custom-class-name
   ```

3. **Additional features:**
   - [Describe any functionality changes]
   - [List new variants or options]

**Update Strategy:**
1. Backup before updating: `bash ${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-shadcn-update/scripts/backup-components.sh`
2. Update via CLI: `pnpx shadcn@latest add component-name --overwrite`
3. Restore from backup: `bash ${CLAUDE_PLUGIN_ROOT}/skills/rwsdk-shadcn-update/scripts/restore-components.sh`
4. If you want shadcn's new features:
   - Compare `.shadcn-backup/component-name.tsx` with current version
   - Manually merge new features while preserving custom attributes
   - Test both server and client component usage

---

### Standard Components (Safe to Update)

**These components have no customizations and match shadcn defaults exactly.**

**Update Command:**
```bash
pnpx shadcn@latest add <component-name> --overwrite
```

**List your standard components here:**
- [component-1]
- [component-2]
- [component-3]
- ...

---

## Configuration

### components.json

**RSC Support:** `"rsc": true` (React Server Components enabled)

**Path Aliases:**
```json
{
  "components": "@/app/components",
  "utils": "@/lib/utils",
  "ui": "@/app/components/ui",
  "lib": "@/lib",
  "hooks": "@/hooks"
}
```

**Style:** [Your style variant - e.g., "new-york", "default"]

**Theme:** [Your theme setup - e.g., "next-themes", custom theming]

---

## RedwoodSDK-Specific Patterns

### Server Component Usage (Default)

Most components work as server components without "use client":

```typescript
import { Button } from "@/app/components/ui/button";

export function MyPage() {
  return <Button>Click me</Button>;
}
```

### Client Component Usage (When Needed)

Add "use client" only when interactivity is required:

```typescript
"use client";
import { useState } from "react";
import { Dialog, DialogContent } from "@/app/components/ui/dialog";

export function MyDialog() {
  const [open, setOpen] = useState(false);
  return <Dialog open={open} onOpenChange={setOpen}>...</Dialog>;
}
```

### With Server Functions

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

---

## Testing After Updates

Run these checks after any component update:

1. **Type check:**
   ```bash
   # Auto-detect package manager
   pnpm types    # or npm run types / yarn types
   ```

2. **Build:**
   ```bash
   pnpm build    # or npm run build / yarn build
   ```

3. **Visual tests:**
   - [List your key pages that use components]
   - [e.g., Dashboard, Forms, Settings, etc.]

---

## Component Detection Guide

**Use this guide to classify components in your project:**

### Is it a Custom Component?

Check:
- [ ] Component name not in shadcn registry
- [ ] Combines multiple shadcn components
- [ ] Has unique business logic
- [ ] Project-specific implementation

If YES → Add to "Custom Components" section

### Is it a Modified Component?

Check:
- [ ] Has custom `data-*` attributes
- [ ] Modified variant definitions
- [ ] Additional styling beyond shadcn
- [ ] Custom sub-components added
- [ ] Enhanced functionality

If YES → Add to "Modified Components" section

### Is it a Standard Component?

Check:
- [ ] Matches shadcn registry exactly
- [ ] No custom attributes
- [ ] No custom styling
- [ ] Unchanged from shadcn default

If YES → Add to "Standard Components" list

---

## Migration History

**Track major component updates here:**

### [Date] - [Update Description]

**Components updated:**
- [component-1] - [version/changes]
- [component-2] - [version/changes]

**Issues encountered:**
- [Issue 1] - [Resolution]
- [Issue 2] - [Resolution]

**Testing notes:**
- [What was tested]
- [Any regressions found]

---

## Notes

- **React Server Components:** Most shadcn components have `"use client"` - this is expected for interactive components
- **Version control:** Always commit before running shadcn updates to easily revert if needed
- **Backup directory:** `.shadcn-backup/` contains backed-up components (gitignored by default)
- **Package manager:** Scripts auto-detect pnpm, yarn, or npm based on lock files
