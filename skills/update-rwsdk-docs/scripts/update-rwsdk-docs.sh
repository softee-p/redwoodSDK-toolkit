#!/bin/bash
set -e

# Update the rwsdk-docs skill references with the latest official RedwoodSDK documentation.
#
# Usage: ./update-rwsdk-docs.sh <repo-root>
#   <repo-root>  Absolute path to the claude-skills-priv repository root.
#
# What it does:
#   1. Clears the rwsdk-docs references folder
#   2. Clones the official RedwoodSDK repo (shallow, sparse checkout)
#   3. Copies the docs into the references folder
#   4. Removes image folders (images, img, assets) to save space

REPO_ROOT="${1:?Usage: update-rwsdk-docs.sh <repo-root>}"
REFERENCES_DIR="$REPO_ROOT/skills/rwsdk-docs/references"
SDK_REPO_URL="https://github.com/redwoodjs/sdk.git"
REMOTE_DOCS_PATH="docs/src/content/docs"
TEMP_DIR=$(mktemp -d)

echo "=== Updating rwsdk-docs skill references ==="
echo "Repo root:  $REPO_ROOT"
echo "Target dir: $REFERENCES_DIR"
echo ""

# Step 1: Clear the existing references folder
echo "[1/5] Clearing existing references..."
if [ -d "$REFERENCES_DIR" ]; then
    rm -rf "$REFERENCES_DIR"
fi
mkdir -p "$REFERENCES_DIR"

# Step 2: Clone the official RedwoodSDK repo (shallow + sparse)
echo "[2/5] Cloning RedwoodSDK repository (sparse checkout)..."
git clone --depth 1 --filter=blob:none --sparse "$SDK_REPO_URL" "$TEMP_DIR"

# Step 3: Sparse checkout only the docs folder
echo "[3/5] Checking out docs folder..."
cd "$TEMP_DIR"
git sparse-checkout set "$REMOTE_DOCS_PATH"
cd - > /dev/null

# Step 4: Copy docs into references
echo "[4/5] Copying documentation to references..."
cp -r "$TEMP_DIR/$REMOTE_DOCS_PATH"/* "$REFERENCES_DIR/"

# Step 5: Remove image folders
echo "[5/5] Removing image folders..."
find "$REFERENCES_DIR" -type d \( -name "images" -o -name "img" -o -name "assets" \) -exec rm -rf {} + 2>/dev/null || true

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "Done. References updated at: $REFERENCES_DIR"
echo ""

# Print a summary of what was fetched
echo "=== Files fetched ==="
find "$REFERENCES_DIR" -type f -name "*.mdx" -o -name "*.md" | sort | while read -r f; do
    echo "  ${f#$REFERENCES_DIR/}"
done
echo ""
echo "Total files: $(find "$REFERENCES_DIR" -type f \( -name "*.mdx" -o -name "*.md" \) | wc -l)"
