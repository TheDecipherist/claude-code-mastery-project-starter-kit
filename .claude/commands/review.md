---
description: Review code for bugs, security issues, and best practices
allowed-tools: Read, Grep, Glob, Bash(git diff:*)
---

# Code Review

Review the current changes for:

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

## Output Format

For each issue found:
- **File**: path/to/file.ts:line
- **Severity**: 🔴 Critical | 🟡 Warning | 🔵 Info
- **Issue**: Description
- **Fix**: Suggested change
