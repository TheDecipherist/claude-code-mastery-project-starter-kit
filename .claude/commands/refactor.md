---
description: Refactor a file following all project best practices — split, type, extract, clean
argument-hint: <file-path> [--dry-run]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion
---

# Refactor — Best Practices Enforcement

Refactor the target file following every rule in this project's CLAUDE.md.

**Target:** $ARGUMENTS

If `--dry-run` is passed, report what WOULD change without modifying any files.

## Step 0 — Auto-Branch (if on main)

Before making any changes, check the current branch:

```bash
git branch --show-current
```

**Default behavior** (`auto_branch = true` in `claude-mastery-project.conf`):
- If on `main` or `master`: automatically create a feature branch and switch to it:
  ```bash
  git checkout -b refactor/<filename-without-extension>
  ```
  Report: "Created branch `refactor/<name>` — main stays untouched."
- If already on a feature branch: proceed
- If not a git repo: skip this check

**To disable:** Set `auto_branch = false` in `claude-mastery-project.conf`. When disabled, warn and ask the user before proceeding on main.

## Step 0.5 — Read Before Touching

**NEVER refactor blind.** Read these files first:

1. The target file (fully — every line)
2. `CLAUDE.md` — to know the current project rules
3. `project-docs/ARCHITECTURE.md` — to understand where things belong (if it exists)
4. `tsconfig.json` — to check TypeScript strict mode settings (if it exists)

Also check:
```bash
# What imports this file? (understand the blast radius)
# Search for the filename in all source files
```

Report: "This file is imported by X other files. Changes here affect: [list]"

## Step 1 — Audit the File

Run through EVERY check below. For each violation found, note the line number, what's wrong, and what the fix is.

### 1A. File Size (Rule 7: Quality Gates)

- **> 300 lines = MUST split.** No exceptions.
- Identify logical sections that can become their own files
- Group by: types, constants, helpers/utilities, main logic, exports

### 1B. Function Size (Rule 7: Quality Gates)

- **> 50 lines = MUST extract.** No exceptions.
- Identify functions that do multiple things — each "thing" becomes its own function
- Name extracted functions by what they DO, not where they came from

### 1C. TypeScript Compliance (Rule 1: TypeScript Always)

- If the file is `.js` or `.jsx` → **convert to `.ts` / `.tsx`**
- Find ALL `any` types → replace with proper types or `unknown`
- Check for missing return types on exported functions
- Check for missing parameter types
- Check for implicit `any` (TypeScript should catch these in strict mode)
- Check for `@ts-ignore` or `@ts-expect-error` — remove if possible, document if necessary

### 1D. Import Hygiene (Coding Standards)

- No barrel imports (`import * as everything from`)
- No circular imports (A imports B, B imports A)
- Types should use `import type { }` not `import { }`
- Unused imports → remove
- Sort: external packages first, then internal, then types

### 1E. Error Handling (Coding Standards)

- No swallowed errors (`catch { return null }`)
- No empty catch blocks
- Errors must be logged with context (what was being attempted, relevant IDs)
- User-facing errors must have clear messages

### 1F. Database Access (Rule 3)

- No direct `MongoClient` or `mongodb` imports outside `src/core/db/`
- All queries go through the wrapper (`queryOne`, `queryMany`, `insertOne`, etc.)
- No `find()` or `findOne()` — use aggregation via the wrapper
- Counters use `$inc` not read-modify-write

### 1G. API Routes (Rule 2)

- All endpoints use `/api/v1/` prefix
- No business logic in route handlers — extract to `handlers/`

### 1H. Independent Awaits (Rule 8)

- Find sequential `await` calls that don't depend on each other
- Wrap in `Promise.all`

### 1I. Security (Rule 0 + Rule 5)

- No hardcoded secrets, API keys, tokens, or connection strings
- No SQL/NoSQL injection vulnerabilities
- Input validation on external data

### 1J. Dead Code

- Unused functions → remove entirely (don't comment out)
- Unused variables → remove
- Unreachable code → remove
- Commented-out code blocks → remove (that's what git history is for)

## Step 2 — Plan the Refactor

Before changing ANYTHING, present the plan to the user:

```
Refactor Plan for: src/handlers/users.ts (347 lines)
=====================================================

File size: 347 lines → SPLIT REQUIRED (max 300)

Split into:
  1. src/handlers/users.ts        — main handler (route logic, ~120 lines)
  2. src/handlers/user-validation.ts — input validation helpers (~80 lines)
  3. src/handlers/user-transforms.ts — data transformation functions (~60 lines)
  4. src/types/user.ts             — User, CreateUserInput, UserResponse types (~40 lines)

Function extraction:
  - processUserSignup() (73 lines) → split into validateSignupInput() + createUserRecord() + sendWelcomeEmail()
  - getUserDashboard() (62 lines) → split into fetchDashboardData() + formatDashboardResponse()

TypeScript fixes:
  - Line 45: `any` → `CreateUserInput`
  - Line 89: missing return type → `Promise<UserResponse>`
  - Line 134: `@ts-ignore` → proper null check

Other fixes:
  - Lines 23-25: sequential awaits → Promise.all (independent)
  - Line 67: swallowed error → proper logging + rethrow
  - Line 112: direct MongoClient import → use wrapper
  - Lines 200-215: dead code (commented out old auth) → remove

Blast radius: imported by 3 files (server.ts, user-routes.ts, admin.ts)
  - Imports will be updated to point to new file locations

Proceed? (yes / no / modify plan)
```

**WAIT for user approval before making any changes.**

Use named steps (Step 1, Step 2, etc.) so the user can say "skip Step 3" or "change Step 2 to keep validation inline."

## Step 3 — Execute the Refactor

After approval, make changes in this order:

1. **Create new files first** (types, helpers, utilities)
2. **Move code** from the original file to new files
3. **Update imports** in the original file to reference new files
4. **Update imports** in ALL files that imported from the original
5. **Fix TypeScript** (types, return types, remove `any`)
6. **Fix patterns** (Promise.all, error handling, dead code)
7. **Verify TypeScript compiles:**
   ```bash
   npx tsc --noEmit 2>&1 | head -30
   ```

### Splitting Rules

When splitting a file into multiple files:

- **Types** → `src/types/<domain>.ts` (or colocated `<name>.types.ts`)
- **Constants** → colocated `<name>.constants.ts` or `src/constants/`
- **Helpers/Utilities** → colocated `<name>.utils.ts` or `src/utils/`
- **Validation** → colocated `<name>.validation.ts`
- **The original file** keeps the main logic and imports from the new files

```typescript
// BEFORE: one massive file
// src/handlers/users.ts (347 lines — types, validation, helpers, handlers all mixed)

// AFTER: clean separation
// src/types/user.ts          — User, CreateUserInput, UserResponse
// src/handlers/user-validation.ts — validateEmail(), validatePassword()
// src/handlers/user-transforms.ts — formatUserResponse(), sanitizeInput()
// src/handlers/users.ts      — handler functions only, imports from above
```

### Import Updates

After splitting, update EVERY file that imported from the original:

```typescript
// BEFORE
import { User, getUserById, validateEmail } from './handlers/users.js';

// AFTER
import type { User } from '../types/user.js';
import { getUserById } from './handlers/users.js';
import { validateEmail } from './handlers/user-validation.js';
```

## Step 4 — Verify

After all changes:

1. **TypeScript compiles clean:**
   ```bash
   npx tsc --noEmit
   ```

2. **No broken imports** — search for any import referencing moved/renamed exports:
   ```bash
   # Check for compilation errors
   npx tsc --noEmit 2>&1 | grep "error TS"
   ```

3. **No file exceeds 300 lines**
4. **No function exceeds 50 lines**
5. **No remaining `any` types** (unless documented why)

## Step 5 — RuleCatch Report

After the refactor is complete, check RuleCatch:

- If the RuleCatch MCP server is available: query for violations in the refactored files
- Report any remaining violations
- If no MCP: suggest checking the dashboard

## Step 6 — Report

```
Refactor Complete: src/handlers/users.ts
========================================
Before: 1 file, 347 lines, 4 violations
After:  4 files, ~300 lines total, 0 violations

Files created:
  ✓ src/types/user.ts (40 lines)
  ✓ src/handlers/user-validation.ts (80 lines)
  ✓ src/handlers/user-transforms.ts (60 lines)

Files modified:
  ✓ src/handlers/users.ts (120 lines — down from 347)
  ✓ src/server.ts (imports updated)
  ✓ src/routes/user-routes.ts (imports updated)

Fixes applied:
  ✓ 3 `any` types replaced with proper types
  ✓ 2 functions extracted (were >50 lines)
  ✓ 1 Promise.all optimization
  ✓ 1 swallowed error fixed
  ✓ 15 lines of dead code removed

TypeScript: compiles clean ✓
RuleCatch: no violations ✓
```
