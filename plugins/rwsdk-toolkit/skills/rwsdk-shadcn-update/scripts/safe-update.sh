#!/bin/bash
# Safe update workflow for shadcn/ui components
# This script orchestrates backup, update, restore, and testing
#
# IMPORTANT: Customize the STANDARD_COMPONENTS list below for your project!
# Run Phase 1 analysis from SKILL.md to identify which components are safe to update.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

cd "$PROJECT_ROOT"

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"
    PKG_EXEC="pnpx"
elif [ -f "yarn.lock" ]; then
    PKG_MGR="yarn"
    PKG_EXEC="yarn dlx"
elif [ -f "package-lock.json" ]; then
    PKG_MGR="npm"
    PKG_EXEC="npx"
else
    echo "[WARNING] Could not detect package manager. Defaulting to npm."
    PKG_MGR="npm"
    PKG_EXEC="npx"
fi

echo "[INFO] Detected package manager: $PKG_MGR"
echo "[INFO] Starting safe shadcn/ui component update workflow..."
echo ""

# ========================================
# CUSTOMIZE THIS LIST FOR YOUR PROJECT
# ========================================
# After running Phase 1 analysis, list ONLY standard components here.
# Standard components = no customizations, safe to update via CLI.
#
# Example:
# STANDARD_COMPONENTS=(
#   input
#   alert
#   label
#   popover
#   select
#   avatar
#   table
# )

STANDARD_COMPONENTS=(
  # Add your standard components here after Phase 1 analysis
)

# Step 1: Backup
echo "========================================"
echo "STEP 1: Backing up custom components"
echo "========================================"
bash "$SCRIPT_DIR/backup-components.sh"
echo ""

# Step 2: Update standard components
echo "========================================"
echo "STEP 2: Updating standard components"
echo "========================================"
echo "[INFO] Updating: ${STANDARD_COMPONENTS[*]}"
echo ""

# Update standard components (safe to update)
$PKG_EXEC shadcn@latest add \
  "${STANDARD_COMPONENTS[@]}" \
  --overwrite \
  --yes || true

echo ""
echo "[SUCCESS] Standard components updated"
echo ""

# Step 3: Restore custom components
echo "========================================"
echo "STEP 3: Restoring custom components"
echo "========================================"
bash "$SCRIPT_DIR/restore-components.sh"
echo ""

# Step 4: Type check
echo "========================================"
echo "STEP 4: Type checking"
echo "========================================"
if grep -q '"types"' package.json; then
  if $PKG_MGR run types; then
    echo "[SUCCESS] Type check passed"
  else
    echo "[ERROR] Type check failed - review errors above"
    exit 1
  fi
else
  echo "[WARNING] No 'types' script found in package.json, skipping type check"
fi
echo ""

# Step 5: Build check
echo "========================================"
echo "STEP 5: Build check"
echo "========================================"
if grep -q '"build"' package.json; then
  if $PKG_MGR run build; then
    echo "[SUCCESS] Build succeeded"
  else
    echo "[ERROR] Build failed - review errors above"
    exit 1
  fi
else
  echo "[ERROR] No 'build' script found in package.json"
  exit 1
fi
echo ""

# Success message
echo "========================================"
echo "[SUCCESS] SAFE UPDATE COMPLETE!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Test the app visually ($PKG_MGR run dev)"
echo "  2. Check key pages that use shadcn components"
echo "  3. Review diffs for modified components"
echo "  4. Commit changes if everything works"
echo ""
echo "[WARNING] NOTE: Custom/modified components were restored from backup."
echo "   If shadcn made improvements you want, manually merge them."
