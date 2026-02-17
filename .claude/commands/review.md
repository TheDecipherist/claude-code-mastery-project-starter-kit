---
description: Review code for bugs, security issues, and best practices
scope: project
allowed-tools: Read, Grep, Glob, Bash(git diff:*)
---

# Code Review

Review the current changes for:

## Branch Check

Verify the current branch context:

```bash
git branch --show-current
```

- If on `main` or `master` and `auto_branch = true` in `claude-mastery-project.conf`: warn — "You're reviewing changes directly on main. Next time, start work on a feature branch."
- Report which branch is being reviewed in the output header
- Review is read-only so no auto-branch is created, but the warning reminds the user for future commands

## Context
- Current diff: !`git diff HEAD`
- Staged changes: !`git diff --cached`

## Review Checklist

1. **Security** — OWASP Top 10, no secrets in code, proper input validation
2. **Types** — No `any`, proper null handling, explicit return types
3. **Error Handling** — No swallowed errors, proper logging, user-friendly messages
4. **Performance** — No N+1 queries, no memory leaks, proper pagination
5. **Testing** — New code has tests, tests have explicit assertions
6. **Database** — Using centralized wrapper, no direct connections
7. **API Versioning** — All endpoints use `/api/v1/` prefix

## RuleCatch Report

After completing the manual review, query RuleCatch for automated violations on the changed files:

- If the RuleCatch MCP server is available: query for violations on the files in the current diff
- Include results in a dedicated section of the review output (see format below)
- This catches pattern-based violations the manual review might miss
- If no MCP available: suggest — "Ask `RuleCatch, what violations happened today?` for automated checks"

## Output Format

For each issue found:
- **File**: path/to/file.ts:line
- **Severity**: 🔴 Critical | 🟡 Warning | 🔵 Info
- **Issue**: Description
- **Fix**: Suggested change

### RuleCatch Violations
| File | Rule | Severity | Details |
|------|------|----------|---------|
| ... | ... | ... | ... |

If no RuleCatch violations: "RuleCatch: No violations detected"
