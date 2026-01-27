---
name: update-rwsdk-docs
description: Update the rwsdk-docs skill with the latest official RedwoodSDK documentation from GitHub. Use when the RedwoodSDK docs need refreshing, when the rwsdk-docs skill references are stale or outdated, or when explicitly asked to update/sync the RedwoodSDK documentation. This skill fetches the latest docs from the official redwoodjs/sdk repository and rebuilds the rwsdk-docs skill references and index.
---

# Update rwsdk-docs

Refresh the `skills/rwsdk-docs/` skill with the latest official RedwoodSDK documentation from `https://github.com/redwoodjs/sdk`.

## Workflow

### Step 1: Determine the repo root

Identify the absolute path to the `claude-skills-priv` repository root. All paths below are relative to this root.

### Step 2: Fetch latest docs

Run the bundled update script:

```bash
bash <skill-path>/scripts/update-rwsdk-docs.sh <repo-root>
```

This script:
- Clears `skills/rwsdk-docs/references/`
- Shallow-clones the official RedwoodSDK repo
- Copies `docs/src/content/docs/*` into `skills/rwsdk-docs/references/`
- Removes image folders (`images/`, `img/`, `assets/`) to save space

Verify the script exits successfully and review the file listing it prints.

### Step 3: Rebuild the SKILL.md documentation index

The `skills/rwsdk-docs/SKILL.md` contains a hand-maintained documentation index (tables mapping files to topics, plus a quick-lookup section). After updating the references, this index must be updated to match.

1. Read the current `skills/rwsdk-docs/SKILL.md` to understand the index format.
2. List all `.mdx` and `.md` files now in `skills/rwsdk-docs/references/`.
3. For each file, read it and extract the main topics covered.
4. Rebuild the documentation index tables and topic quick-lookup in `SKILL.md`:
   - Preserve the existing structure and format (YAML frontmatter, intro paragraph, "How to Use This Skill" section, table format, quick-lookup format).
   - Add entries for any new files.
   - Remove entries for any deleted files.
   - Update topic descriptions if file content has changed.
   - Keep the same section groupings (Getting Started, Core Concepts, Guides - Frontend, Guides - Backend & Tooling, Experimental Features, Legacy, API Reference) but adjust if the upstream folder structure has changed.

### Step 4: Verify

1. Confirm every `.mdx`/`.md` file in `references/` has a corresponding entry in the SKILL.md index.
2. Confirm no index entries point to files that no longer exist.
3. Confirm the SKILL.md is valid markdown with correct relative links.
