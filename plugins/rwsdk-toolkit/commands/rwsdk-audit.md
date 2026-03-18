---
description: Audit a deployed RedwoodSDK application for errors, performance issues, and health
allowed-tools: Bash, Read, Glob, Grep, Agent
argument-hint: [worker-name]
---

Use the rwsdk-audit-deployed skill to perform a comprehensive audit of the deployed application.

Target worker: $ARGUMENTS

Follow the full 6-phase audit workflow from the rwsdk-audit-deployed skill:
1. Setup & Discovery — auto-detect worker name from wrangler.jsonc if not specified
2. Error Analysis (24h) — query and categorize recent errors
3. Warning Analysis — check for cross-request promise issues and other warnings
4. Current Health Check — verify no active errors in the last hour
5. Performance Metrics (7d) — analyze latency, error rates, and outcomes
6. Code Quality — cross-reference errors with source code using rwsdk-docs best practices

Generate the full audit report with executive summary, health metrics, issues found, and recommendations.
