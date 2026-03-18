---
description: Scaffold a new RedwoodSDK project or add a new feature (route, page, component) to an existing one
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent
argument-hint: <what-to-create>
---

Use the rwsdk-docs skill to look up the relevant documentation before proceeding.

The user wants to create: $ARGUMENTS

**If creating a new project:**
1. Read the `getting-started/quick-start.mdx` reference from rwsdk-docs skill
2. Run `pnpm create rwsdk` (or the appropriate create command)
3. Walk the user through initial setup

**If adding to an existing project:**
1. Identify what the user wants to add (route, page, component, API endpoint, etc.)
2. Read the relevant rwsdk-docs references for that feature
3. Explore the existing project structure to understand conventions
4. Implement the feature following RedwoodSDK patterns:
   - Use `defineApp` and `route()` for routing
   - Default to React Server Components (no "use client" unless needed)
   - Use `serverAction`/`serverQuery` for server functions
   - Follow the project's existing naming and file organization conventions
5. Verify with type checking and build
