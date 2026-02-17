---
description: Show project progress — what's done, what's pending, what's next
scope: project
allowed-tools: Read, Bash(find:*), Bash(ls:*), Bash(wc:*), Bash(git log:*)
---

# Project Progress

Check the actual state of all components and report status.

## Instructions

1. Read `project-docs/ARCHITECTURE.md` for project context (if it exists)
2. Check the `src/` directory structure
3. Check the `tests/` directory for test coverage
4. Check recent git activity

## Shell Commands to Run

```bash
echo "=== Source Files ==="
find src/ -name "*.ts" -o -name "*.tsx" | head -30 2>/dev/null || echo "No src/ directory"

echo ""
echo "=== Test Files ==="
find tests/ -name "*.test.*" -o -name "*.spec.*" | head -30 2>/dev/null || echo "No test files"

echo ""
echo "=== Recent Activity (Last 7 Days) ==="
git log --oneline --since="7 days ago" 2>/dev/null | head -15 || echo "No recent commits"

echo ""
echo "=== File Count by Type ==="
find src/ -name "*.ts" 2>/dev/null | wc -l | xargs -I{} echo "TypeScript: {} files"
find src/ -name "*.js" 2>/dev/null | wc -l | xargs -I{} echo "JavaScript: {} files"
find tests/ -name "*.test.*" 2>/dev/null | wc -l | xargs -I{} echo "Tests: {} files"
```

## Output Format

| Area | Files | Status | Notes |
|------|-------|--------|-------|
| Source code | N files | ... | ... |
| Tests | N files | ... | ... |
| Documentation | ... | ... | ... |

### RuleCatch Report
| Metric | Value |
|--------|-------|
| Violations (this session) | ... |
| Critical violations | ... |
| Most violated rule | ... |
| Files with violations | ... |

If the RuleCatch MCP server is available: query for session summary and populate the table above.
If no MCP available: show "Install RuleCatch for violation tracking — `npx @rulecatch/mcp-server init`"

### Next Actions (Priority Order)
1. ...
2. ...
3. ...
