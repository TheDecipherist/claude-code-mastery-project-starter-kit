---
name: Code Review
description: Comprehensive code review with security, performance, and best practices focus
triggers:
  - review
  - audit
  - check code
  - security review
---

# Code Review Skill

When reviewing code, follow this systematic approach:

## 1. Security (FIRST — always check)

- [ ] No hardcoded secrets, API keys, or passwords
- [ ] Input validation on all user-provided data
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (sanitized output)
- [ ] Authentication/authorization on protected routes
- [ ] CORS properly configured
- [ ] Rate limiting on public endpoints

## 2. TypeScript Quality

- [ ] No `any` types (unless documented why)
- [ ] Explicit return types on public functions
- [ ] Null/undefined properly handled (`User | null`)
- [ ] Strict mode enabled
- [ ] Enums or union types instead of magic strings

## 3. Error Handling

- [ ] Try/catch around async operations
- [ ] Errors logged with context (not swallowed)
- [ ] User-facing errors are helpful (not stack traces)
- [ ] Unhandled promise rejections caught

## 4. Performance

- [ ] No N+1 database queries
- [ ] Proper pagination on list endpoints
- [ ] No memory leaks (event listeners cleaned up)
- [ ] Database indexes for common queries
- [ ] No unnecessary re-renders (React)

## 5. Testing

- [ ] New code has corresponding tests
- [ ] Tests have explicit assertions (not just "page loads")
- [ ] Edge cases covered (empty, null, max values)
- [ ] Mocks are realistic

## 6. Architecture

- [ ] Database access through centralized wrapper only
- [ ] API versioning (/api/v1/) followed
- [ ] Service separation respected
- [ ] No business logic in route handlers

## Output Format

For each issue:
- **Severity**: 🔴 Critical | 🟡 Warning | 🔵 Suggestion
- **Location**: file:line
- **Issue**: What's wrong
- **Fix**: How to fix it
- **Why**: Why this matters
