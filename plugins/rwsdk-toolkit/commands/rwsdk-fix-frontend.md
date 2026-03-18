---
description: Diagnose and fix frontend layout/styling issues in a RedwoodSDK app using the 4-phase visual workflow
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: <description-of-issue>
---

Use the rwsdk-frontend skill to fix this frontend issue with the mandatory 4-phase workflow.

Issue: $ARGUMENTS

Follow the rwsdk-frontend skill workflow strictly:

**Phase 1: Context Gathering**
- Use rwsdk-docs skill for RSC styling constraints
- Explore the codebase for layout components, CSS files, and Tailwind config
- Identify the affected components and their file paths

**Phase 2: Visual Testing**
- Start the dev server if not running
- Use browser-use skill to visually inspect the issue at multiple viewport sizes
- Document specific problems with screenshots/descriptions

**Phase 3: Design Solution**
- Create implementation plan based on visual evidence
- Specify exact Tailwind classes or CSS changes needed
- Account for RSC-specific constraints

**Phase 4: Verification**
- Apply the fix
- Re-test with browser-use at the same viewports
- Verify no regressions at other breakpoints (mobile, tablet, desktop)
