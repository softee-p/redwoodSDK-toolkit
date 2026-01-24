#!/bin/bash
set -e

# Update RedwoodSDK official documentation
# This script syncs docs from https://github.com/redwoodjs/sdk

REPO_URL="https://github.com/redwoodjs/sdk.git"
REMOTE_DOCS_PATH="docs/src/content/docs"
LOCAL_DOCS_PATH="docs/redwoodsdk-official"
TEMP_DIR=$(mktemp -d)

echo "Syncing RedwoodSDK official documentation..."
echo "Source: $REPO_URL/$REMOTE_DOCS_PATH"
echo "Target: $LOCAL_DOCS_PATH"
echo ""

# Clone the repo to temp directory (shallow clone for speed)
echo "[1/5] Cloning SDK repository..."
git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR"

cd "$TEMP_DIR"

# Sparse checkout only the docs folder
echo "[2/5] Checking out docs folder..."
git sparse-checkout set "$REMOTE_DOCS_PATH"

# Go back to repo root
cd - > /dev/null

# Remove old docs if they exist
if [ -d "$LOCAL_DOCS_PATH" ]; then
    echo "[3/5] Removing old documentation..."
    rm -rf "$LOCAL_DOCS_PATH"
fi

# Copy the docs folder to our repo
echo "[4/5] Copying documentation..."
mkdir -p "$(dirname "$LOCAL_DOCS_PATH")"
cp -r "$TEMP_DIR/$REMOTE_DOCS_PATH" "$LOCAL_DOCS_PATH"

# Remove image folders (we don't need them)
echo "[5/5] Removing image folders..."
find "$LOCAL_DOCS_PATH" -type d \( -name "images" -o -name "img" -o -name "assets" \) -exec rm -rf {} + 2>/dev/null || true

# Clean up temp directory
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Documentation updated successfully!"
echo ""
echo "The official RedwoodSDK docs are now in: $LOCAL_DOCS_PATH"
echo ""
echo "To commit these changes:"
echo "  git add $LOCAL_DOCS_PATH"
echo "  git commit -m \"Update RedwoodSDK official documentation\""
