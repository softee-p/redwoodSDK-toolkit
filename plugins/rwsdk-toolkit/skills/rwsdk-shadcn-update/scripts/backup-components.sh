#!/bin/bash
# Backup custom and modified shadcn/ui components before updates
#
# IMPORTANT: Customize this script for your project!
# Edit the component list below to match YOUR custom/modified components.
# Run Phase 1 analysis from SKILL.md to identify which components need backup.

set -e

BACKUP_DIR=".shadcn-backup"
UI_DIR="src/app/components/ui"

echo "[INFO] Backing up custom shadcn components..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# ========================================
# CUSTOMIZE THIS SECTION FOR YOUR PROJECT
# ========================================
# After running Phase 1 analysis, add your custom/modified components here.
#
# Custom components (never update via CLI):
#   - Components not in shadcn registry
#   - Custom compositions combining multiple components
#   - Example: DatePicker combining Button + Calendar + Popover
#
# Modified components (backup before updating):
#   - Standard shadcn components with customizations
#   - Components with custom data-* attributes
#   - Components with modified variants or styling

# Example backup for custom component:
# if [ -f "$UI_DIR/CustomComponent.tsx" ]; then
#   cp "$UI_DIR/CustomComponent.tsx" "$BACKUP_DIR/"
#   echo "[SUCCESS] Backed up CustomComponent.tsx (custom component)"
# fi

# Example backup for modified component:
# if [ -f "$UI_DIR/button.tsx" ]; then
#   cp "$UI_DIR/button.tsx" "$BACKUP_DIR/"
#   echo "[SUCCESS] Backed up button.tsx (modified component)"
# fi

# Add your project's components below:
# --------------------------------------


# --------------------------------------

echo "[SUCCESS] Backup complete at $BACKUP_DIR/"
echo "[INFO] Remember to add your custom/modified components to this script!"
