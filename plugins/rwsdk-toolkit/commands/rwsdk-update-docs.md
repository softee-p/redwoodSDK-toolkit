---
description: Sync the rwsdk-docs skill references with the latest official RedwoodSDK documentation
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

Use the update-rwsdk-docs skill to refresh the documentation.

Follow the update-rwsdk-docs skill workflow:
1. Determine the repo root
2. Run the bundled update script to fetch latest docs from GitHub
3. Rebuild the SKILL.md documentation index
4. Verify completeness — every reference file has an index entry and vice versa
