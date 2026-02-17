---
description: Create a Playwright E2E test with explicit success criteria
scope: project
argument-hint: <feature-or-page-name>
allowed-tools: Read, Write, Grep, Glob, Bash, AskUserQuestion
---

# Create E2E Test

Create a Playwright E2E test for: **$ARGUMENTS**

## ABSOLUTE RULES — Read Before Writing a Single Line

### 1. Every test MUST have explicit success criteria

"Page loads" is NOT a test. Every `test()` block MUST assert:
- **URL** — verify the page navigated to the correct URL
- **Visible elements** — verify key elements are present and visible
- **Correct data** — verify the right content is displayed
- **Error states** — verify error messages show when expected

```typescript
// CORRECT — explicit success criteria
test('dashboard shows user data after login', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'password123');
  await page.click('button[type="submit"]');

  // ✅ Verify URL changed
  await expect(page).toHaveURL('/dashboard');
  // ✅ Verify key element visible
  await expect(page.locator('h1')).toContainText('Welcome');
  // ✅ Verify correct data displayed
  await expect(page.locator('[data-testid="user-email"]')).toContainText('test@example.com');
  // ✅ Verify sidebar loaded
  await expect(page.locator('nav.sidebar')).toBeVisible();
});

// WRONG — this passes even when completely broken
test('dashboard loads', async ({ page }) => {
  await page.goto('/dashboard');
  // no assertions!
});
```

### 2. A test is FINISHED when it has ALL of these

A test is NOT done until it has:
- [ ] At least one `await expect(page).toHaveURL()` assertion
- [ ] At least one `await expect(locator).toBeVisible()` assertion
- [ ] At least one content/data verification (`toContainText`, `toHaveValue`, etc.)
- [ ] Error case coverage (what happens when it fails?)
- [ ] No `// TODO` or placeholder assertions

If you cannot check ALL of these, the test is incomplete. Say so and explain what's missing.

### 3. Test structure — ALWAYS follow this pattern

```typescript
import { test, expect } from '@playwright/test';

test.describe('[Feature Name]', () => {
  test.describe('happy path', () => {
    test('should [specific behavior] when [specific condition]', async ({ page }) => {
      // ARRANGE — navigate, set up state
      // ACT — perform the user action
      // ASSERT — verify SPECIFIC outcomes (URL, elements, data)
    });
  });

  test.describe('error handling', () => {
    test('should show error when [invalid input]', async ({ page }) => {
      // Test the failure mode
    });
  });

  test.describe('edge cases', () => {
    test('should handle [empty state / max values / etc]', async ({ page }) => {
      // Test boundaries
    });
  });
});
```

### 4. Port configuration — ALWAYS use test ports

E2E tests run on TEST ports, never dev ports:

| Service   | Test Port | Base URL                   |
|-----------|-----------|----------------------------|
| Website   | 4000      | http://localhost:4000      |
| API       | 4010      | http://localhost:4010      |
| Dashboard | 4020      | http://localhost:4020      |

The `baseURL` is already set in `playwright.config.ts`. Use relative paths:

```typescript
// CORRECT — uses baseURL from config
await page.goto('/dashboard');

// WRONG — hardcoded URL
await page.goto('http://localhost:3000/dashboard');
```

### 5. What to test for each page type

**For a page/route:**
- URL is correct after navigation
- Page title / heading is present
- Key UI elements are visible (nav, sidebar, footer, etc.)
- Dynamic data is loaded and displayed
- Links navigate to correct destinations
- Responsive behavior (if applicable)

**For a form:**
- Empty form shows proper validation messages
- Valid submission succeeds (verify success state)
- Invalid input shows specific error messages
- Submit button disabled during processing
- Form clears or redirects after success

**For an API endpoint:**
- Correct response status code
- Response body matches expected shape
- Error responses have proper status codes and messages
- Authentication/authorization is enforced

**For authentication:**
- Login with valid credentials succeeds
- Login with invalid credentials shows error
- Protected pages redirect to login
- Logout clears session
- Token expiry is handled

### 6. Naming convention

File: `tests/e2e/[feature-name].spec.ts`

Examples:
- `tests/e2e/auth-login.spec.ts`
- `tests/e2e/dashboard-overview.spec.ts`
- `tests/e2e/api-users.spec.ts`
- `tests/e2e/settings-profile.spec.ts`

## Step 0 — Auto-Branch (if on main)

Before creating any files, check the current branch:

```bash
git branch --show-current
```

**Default behavior** (`auto_branch = true` in `claude-mastery-project.conf`):
- If on `main` or `master`: automatically create a feature branch and switch to it:
  ```bash
  git checkout -b test/<feature-name>
  ```
  Report: "Created branch `test/<feature>` — main stays untouched."
- If already on a feature branch: proceed
- If not a git repo: skip this check

**To disable:** Set `auto_branch = false` in `claude-mastery-project.conf`. When disabled, warn and ask the user before proceeding on main.

## Step 1 — Gather Information

Before writing the test:

1. **Read the source code** for the feature/page being tested
2. **Identify all assertions** — what URLs, elements, and data should be verified?
3. **Identify error states** — what can go wrong? What should the user see?
4. **Check for test data** — does the test need seeded data? Mock API responses?

## Step 2 — Ask What to Verify (if not obvious)

If the feature has multiple possible success criteria, ask the user:

Use AskUserQuestion to clarify:
- "What specific elements should be visible on this page?"
- "What data should be displayed after this action?"
- "What error message should appear for invalid input?"

## Step 3 — Write the Test

Create the test file at `tests/e2e/[feature-name].spec.ts` following ALL rules above.

Every test file MUST include:
1. At least one happy-path test
2. At least one error-case test
3. Explicit assertions in every `test()` block

## Step 4 — Verification Checklist

After writing, verify:

- [ ] File is at `tests/e2e/[name].spec.ts`
- [ ] Every `test()` has at least 3 assertions (URL, element, data)
- [ ] Error cases are covered
- [ ] No hardcoded ports (uses baseURL from config)
- [ ] No `// TODO` placeholders
- [ ] Test names describe behavior: "should [verb] when [condition]"
- [ ] No `any` types
- [ ] No `.only` left in the code

## Running Tests

```bash
# Run all E2E tests (spawns servers automatically on test ports)
pnpm test:e2e

# Run a specific test file
pnpm test:e2e tests/e2e/auth-login.spec.ts

# Run with UI mode (debug)
pnpm test:e2e:ui

# Run headed (see the browser)
pnpm test:e2e:headed

# View the last test report
pnpm test:e2e:report
```

## RuleCatch Report

After the test file is created and verified, check RuleCatch:

- If the RuleCatch MCP server is available: query for violations in the new test file
- Report any violations found (missing assertions, TypeScript issues, etc.)
- If no MCP: suggest checking the RuleCatch dashboard
