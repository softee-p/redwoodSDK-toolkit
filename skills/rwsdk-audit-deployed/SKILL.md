---
name: rwsdk-audit-deployed
description: |
  Audit deployed RedwoodSDK applications on Cloudflare Workers using cloudflare-observability MCP.

  Use this skill when:
  - User asks to audit, check, or analyze a deployed RedwoodSDK/rwsdk worker
  - User wants to investigate production errors or performance issues
  - User asks "is everything working correctly" for a deployed app
  - User wants to check logs, errors, or health of a Cloudflare Worker
  - User mentions checking observability, metrics, or monitoring for rwsdk apps

  Requires: cloudflare-observability MCP, rwsdk-docs skill for best practice verification.
---
disable-model-invocation: true

# RedwoodSDK Deployed Application Audit

Methodically audit a deployed RedwoodSDK application on Cloudflare Workers.

## Prerequisites

- **cloudflare-observability MCP** - For querying worker logs and metrics
- **rwsdk-docs skill** - For verifying code against best practices

## Audit Workflow

Execute these phases in order. Use TodoWrite to track progress.

### Phase 1: Setup & Discovery

1. **Auto-detect worker name** (if in a project):
   - Check `wrangler.jsonc` or `wrangler.toml` for `name` field
   - If found, use it as default worker name
2. List workers: `mcp__cloudflare-observability__workers_list`
3. Confirm worker name with user if:
   - Multiple workers exist
   - No wrangler config found
   - User specifies a different worker
4. Get worker details: `mcp__cloudflare-observability__workers_get_worker`

### Phase 2: Error Analysis (24h)

Query recent errors:
```json
{
  "view": "events",
  "queryId": "errors-24h",
  "limit": 20,
  "parameters": {
    "filters": [
      {"key": "$metadata.service", "operation": "eq", "type": "string", "value": "<worker-name>"},
      {"key": "$metadata.level", "operation": "eq", "type": "string", "value": "error"}
    ]
  },
  "timeframe": {"reference": "<current-iso-time>", "offset": "-24h"}
}
```

**Analyze patterns:**
- Route-specific errors (`$metadata.trigger`)
- Version-specific (`$workers.scriptVersion.id`) - different versions indicate deployment changes
- Error fingerprints for grouping

### Phase 3: Warning Analysis

Query warnings (cross-request promise issues common in rwsdk):
```json
{
  "view": "events",
  "queryId": "warnings-24h",
  "limit": 10,
  "parameters": {
    "filters": [
      {"key": "$metadata.service", "operation": "eq", "type": "string", "value": "<worker-name>"},
      {"key": "$metadata.level", "operation": "eq", "type": "string", "value": "warn"}
    ]
  },
  "timeframe": {"reference": "<current-iso-time>", "offset": "-24h"}
}
```

### Phase 4: Current Health Check

Verify no recent errors (confirms if issues resolved):
```json
{
  "view": "calculations",
  "queryId": "errors-1h",
  "parameters": {
    "filters": [
      {"key": "$metadata.service", "operation": "eq", "type": "string", "value": "<worker-name>"},
      {"key": "$metadata.level", "operation": "eq", "type": "string", "value": "error"}
    ],
    "calculations": [{"operator": "count", "alias": "error_count"}]
  },
  "timeframe": {"reference": "<current-iso-time>", "offset": "-1h"}
}
```

### Phase 5: Performance Metrics (7d)

Query health and performance by outcome:
```json
{
  "view": "calculations",
  "queryId": "health-7d",
  "parameters": {
    "filters": [{"key": "$metadata.service", "operation": "eq", "type": "string", "value": "<worker-name>"}],
    "calculations": [
      {"operator": "count", "alias": "total"},
      {"operator": "avg", "key": "$workers.wallTimeMs", "keyType": "number", "alias": "avg_latency"},
      {"operator": "p99", "key": "$workers.wallTimeMs", "keyType": "number", "alias": "p99_latency"}
    ],
    "groupBys": [{"type": "string", "value": "$workers.outcome"}]
  },
  "timeframe": {"reference": "<current-iso-time>", "offset": "-7d"}
}
```

### Phase 6: Code Quality (If Errors Found)

When errors reference code paths:

1. **Use rwsdk-docs skill** to verify patterns against docs
2. **Read source files** from error stack traces
3. **Check common issues** - See [references/common-issues.md](references/common-issues.md)

## Report Structure

```markdown
# Audit Report: <worker-name>

## Executive Summary
**Status**: [HEALTHY | DEGRADED | CRITICAL]

## Health Metrics (7 Days)
| Outcome | Count | % |
|---------|-------|---|

**Performance:** Avg: Xms, P99: Xms

## Issues Found
### [RESOLVED | ACTIVE]: <Title>
**Error:** <message>
**Route:** <trigger>
**Root Cause:** <explanation>

## Performance by Route
| Route | Avg | P99 | Notes |

## Code Quality
| Pattern | Status | Notes |

## Recommendations
```

## Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| Error rate | >2% | >5% |
| P99 latency | >3s | >5s |
| Canceled rate | >10% | >15% |

**Version mismatch in errors** = Recent deployment likely fixed/caused issue
