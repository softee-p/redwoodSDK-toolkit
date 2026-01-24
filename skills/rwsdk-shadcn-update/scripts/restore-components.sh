#!/bin/bash
# Restore custom shadcn/ui components after updates
#
# IMPORTANT: Customize this script for your project!
# Edit the component list below to match YOUR custom/modified components.
# This should mirror the components listed in backup-components.sh.

set -e

BACKUP_DIR=".shadcn-backup"
UI_DIR="src/app/components/ui"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "[ERROR] No backup directory found at $BACKUP_DIR"
  echo "Run backup-components.sh first!"
  exit 1
fi

echo "[INFO] Restoring custom shadcn components..."

# ========================================
# CUSTOMIZE THIS SECTION FOR YOUR PROJECT
# ========================================
# This should match the components in backup-components.sh.
#
# Custom components: Always restore (they're fully custom)
# Modified components: Restore and check for manual merge needs

# Example restore for custom component:
# if [ -f "$BACKUP_DIR/CustomComponent.tsx" ]; then
#   cp "$BACKUP_DIR/CustomComponent.tsx" "$UI_DIR/"
#   echo "[SUCCESS] Restored CustomComponent.tsx (custom component)"
# else
#   echo "[WARNING] CustomComponent.tsx not found in backup"
# fi

# Example restore for modified component:
# if [ -f "$BACKUP_DIR/button.tsx" ]; then
#   cp "$BACKUP_DIR/button.tsx" "$UI_DIR/"
#   echo "[SUCCESS] Restored button.tsx (modified component)"
#   echo "  [INFO] Check for new features to manually merge"
# else
#   echo "[WARNING] button.tsx not found in backup"
# fi

# Add your project's components below:
# --------------------------------------


# --------------------------------------

echo "[SUCCESS] Restore complete!"
echo ""
echo "[INFO] IMPORTANT: For modified components:"
echo "   - Check if shadcn made breaking changes"
echo "   - Verify custom attributes/styling are preserved"
echo "   - Test the components before committing"
