# rwsdk-shadcn-update Skill

A general-purpose shadcn/ui component management assistant for RedwoodSDK projects.

## Overview

This skill helps you safely manage shadcn/ui components in ANY RedwoodSDK project with React Server Components (RSC). It automatically detects custom components, handles updates while preserving customizations, and integrates with both the shadcn MCP server and RedwoodSDK documentation.

### Key Features

1. **shadcn MCP Integration** - Detects and offers to install the shadcn MCP server for enhanced functionality
2. **Dynamic Documentation** - Fetches latest shadcn/ui guide from RedwoodSDK docs using `rwsdk-docs` skill
3. **Custom Component Detection** - Automatically analyzes your project to identify custom/modified components
4. **Safe Update Workflow** - Backup, update, restore, and validate in one automated flow
5. **Package Manager Agnostic** - Works with pnpm, yarn, or npm
6. **RSC Compliance** - Ensures proper React Server Components usage

## How It Works

### Phase 0: Setup & Prerequisites

1. **Check for shadcn MCP server**
   - If available: Use MCP tools for enhanced reliability
   - If not available: Ask user if they want to install it
   - If user declines: Fall back to shadcn CLI

2. **Fetch RedwoodSDK documentation**
   - Use `rwsdk-docs` skill to get latest shadcn/ui guide
   - Get RSC best practices
   - Understand component usage patterns

### Phase 1: Project Analysis

The skill analyzes your specific project to:

1. **Read components.json** - Understand path aliases, RSC settings, style variants
2. **Detect existing components** - List all shadcn components in your UI directory
3. **Classify components**:
   - **Custom components** - Never update via CLI (e.g., custom DatePicker compositions)
   - **Modified components** - Backup before updating (e.g., button.tsx with data-slot attributes)
   - **Standard components** - Safe to update anytime

4. **Create component inventory** - Output summary and document in customizations.md

### Phase 2: Component Operations

Based on your project's needs:

- **Update components** - Quick update (standard only) or safe update (all components)
- **Add components** - With automatic RSC compliance checks
- **Validate changes** - Type check, build check, visual testing plan

## Usage

When a user asks to update or add shadcn components:

1. **Invoke the skill**: Use skill name `rwsdk-shadcn-update`
2. **Follow Phase 0**: Check MCP server, fetch docs
3. **Analyze project**: Run Phase 1 to detect custom components
4. **Execute operation**: Update or add components using Phase 2 workflows
5. **Validate thoroughly**: Run automated checks and manual testing

## Dependencies

### Required

- **RedwoodSDK project** with shadcn/ui configured
- **rwsdk-docs skill** - Provides access to RedwoodSDK documentation

### Optional

- **shadcn MCP server** - Enhanced component management (recommended)
  - Installation guide: https://ui.shadcn.com/docs/mcp
  - The skill will offer to help install if not available

## Files Structure

```
.claude/skills/rwsdk-shadcn-update/
├── SKILL.md                          # Main skill instructions
├── README.md                         # This file
├── scripts/
│   ├── backup-components.sh          # Backup custom/modified components
│   ├── restore-components.sh         # Restore from backup
│   └── safe-update.sh                # Full automated workflow
└── references/
    └── customizations.md             # Template for documenting customizations
```

## Scripts

### backup-components.sh

- Backs up custom/modified components to `.shadcn-backup/` directory
- Project-agnostic: Edit the component list for your specific custom components
- Safe to run multiple times
- No emojis (uses text markers: [INFO], [SUCCESS])

### restore-components.sh

- Restores components from `.shadcn-backup/` directory
- Warns about manual merge needs for modified components
- Safe to run multiple times
- No emojis (uses text markers)

### safe-update.sh

- Full automated workflow:
  1. Backup custom/modified components
  2. Update standard components via shadcn CLI
  3. Restore custom/modified components
  4. Run type check
  5. Run build check
- Auto-detects package manager (pnpm/yarn/npm)
- No emojis (uses text markers)

## Customizing for Your Project

### 1. Identify Your Custom Components

Run Phase 1 analysis to detect:
- Fully custom components (compositions, unique logic)
- Modified components (custom attributes, styling)
- Standard components (safe to update)

### 2. Update backup-components.sh

Edit the script to list YOUR custom/modified components:

```bash
# Backup custom components (never update these via CLI)
if [ -f "$UI_DIR/YourCustomComponent.tsx" ]; then
  cp "$UI_DIR/YourCustomComponent.tsx" "$BACKUP_DIR/"
  echo "[SUCCESS] Backed up YourCustomComponent.tsx (custom component)"
fi

# Backup modified components (need manual merge after updates)
if [ -f "$UI_DIR/your-modified-component.tsx" ]; then
  cp "$UI_DIR/your-modified-component.tsx" "$BACKUP_DIR/"
  echo "[SUCCESS] Backed up your-modified-component.tsx (modified component)"
fi
```

### 3. Update restore-components.sh

Match the restore script to your backup list:

```bash
# Restore YourCustomComponent (always restore - it's fully custom)
if [ -f "$BACKUP_DIR/YourCustomComponent.tsx" ]; then
  cp "$BACKUP_DIR/YourCustomComponent.tsx" "$UI_DIR/"
  echo "[SUCCESS] Restored YourCustomComponent.tsx (custom component)"
fi
```

### 4. Update safe-update.sh

Edit the component list in the update section to match your standard components:

```bash
pnpx shadcn@latest add \
  input \
  alert \
  label \
  # ... your standard components ...
  --overwrite \
  --yes || true
```

### 5. Document Customizations

Use `references/customizations.md` template to document:
- Component name
- Type (custom/modified/standard)
- Description of customizations
- Update strategy

## Sharing This Skill

This skill is designed to be **general-purpose** and can be shared on public repositories:

### Why It's Shareable

1. **No project-specific hardcoded values** - Works with any RedwoodSDK project
2. **Dynamic documentation** - Fetches latest info via `rwsdk-docs` skill
3. **Automatic detection** - Analyzes each project's specific setup
4. **Package manager agnostic** - Works with pnpm, yarn, or npm
5. **Template-based** - Customizations doc adapts to user's components

### To Use in Another Project

1. Copy the entire `.claude/skills/rwsdk-shadcn-update/` directory to your project
2. Ensure the `rwsdk-docs` skill is available
3. Run Phase 1 analysis to detect your project's custom components
4. Customize the scripts based on your component inventory
5. The skill will adapt to your project's specific needs

### Contributing

When updating this skill:

- Keep it general-purpose (no hardcoded component lists in SKILL.md)
- Use `rwsdk-docs` skill for framework-specific information
- Update reference docs when new patterns emerge
- Test with different project configurations (pnpm/yarn/npm, different path structures)
- Remove emojis from all output (use text markers instead)

## Common Scenarios

### Scenario 1: First-Time User

1. User asks to update shadcn components
2. Skill checks for MCP server (not installed)
3. Skill asks: "Would you like to install the shadcn MCP server?"
4. User says yes → Skill fetches guide from https://ui.shadcn.com/docs/mcp
5. After installation, skill runs Phase 1 analysis
6. Skill creates component inventory and customizations.md
7. User customizes backup/restore scripts based on inventory
8. Skill proceeds with safe update workflow

### Scenario 2: Adding New Component

1. User asks to add "tooltip" component
2. Skill checks MCP server (available) → Uses MCP
3. Skill fetches RedwoodSDK docs for RSC patterns
4. Skill adds component via MCP
5. Skill checks RSC compliance (is "use client" needed?)
6. Skill runs validation (types, build)
7. Skill creates project-specific testing plan

### Scenario 3: Updating Modified Components

1. User asks to update button component
2. Skill runs Phase 1 analysis → Detects button.tsx has data-slot attributes
3. Skill classifies as "Modified Component"
4. Skill runs backup script
5. Skill updates via shadcn CLI or MCP
6. Skill restores from backup
7. Skill warns: "button.tsx restored from backup. Check for new features to manually merge."
8. Skill runs validation

## MCP Server Benefits

When shadcn MCP server is available:

- **Better reliability** - Direct integration with shadcn registry
- **Enhanced features** - Access to additional MCP-specific functionality
- **Faster operations** - Optimized component fetching
- **Consistent behavior** - Less prone to CLI version issues

When MCP server is not available:

- **Falls back to CLI** - Uses `pnpx shadcn@latest` commands
- **Still fully functional** - All core features work
- **No degradation** - Same safety guarantees with backup/restore

## Troubleshooting

### "Skill can't detect my custom components"

- Check that component files are in the path specified by `components.json`
- Verify component files have `.tsx` extension
- Look for custom `data-*` attributes or modified variants manually
- Update backup scripts to include your specific custom components

### "MCP server installation fails"

- Follow the official guide at https://ui.shadcn.com/docs/mcp
- Check MCP server logs for errors
- Fall back to shadcn CLI if installation is blocked

### "Scripts don't work with my package manager"

- Scripts auto-detect pnpm, yarn, or npm
- Check that your lock file exists (pnpm-lock.yaml, yarn.lock, or package-lock.json)
- Manually set PKG_MGR variable if detection fails

## License

This skill can be freely shared and modified to help the RedwoodSDK community.
