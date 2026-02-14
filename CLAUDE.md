# CLAUDE.md — Project Instructions

> Based on Claude Code Mastery Guides V1-V5 by TheDecipherist
> https://github.com/TheDecipherist/claude-code-mastery

---

## Quick Reference — Scripts

| Command | What it does |
|---------|-------------|
| `pnpm dev` | Start dev server with hot reload |
| `pnpm dev:website` | Dev server on port 3000 |
| `pnpm dev:api` | Dev server on port 3001 |
| `pnpm dev:dashboard` | Dev server on port 3002 |
| `pnpm build` | Type-check + compile TypeScript |
| `pnpm start` | Run compiled production build |
| `pnpm typecheck` | TypeScript type-check only (no emit) |
| **Testing** | |
| `pnpm test` | Run ALL tests (unit + E2E) |
| `pnpm test:unit` | Run unit/integration tests (Vitest) |
| `pnpm test:unit:watch` | Unit tests in watch mode |
| `pnpm test:coverage` | Unit tests with coverage report |
| `pnpm test:e2e` | Run E2E tests (kills test ports first, spawns servers on 4000/4010) |
| `pnpm test:e2e:ui` | E2E with Playwright UI mode |
| `pnpm test:e2e:headed` | E2E with visible browser |
| `pnpm test:e2e:chromium` | E2E on Chromium only (fast) |
| `pnpm test:e2e:report` | Open last E2E test report |
| `pnpm test:kill-ports` | Kill anything on test ports (4000, 4010, 4020) |
| **Database** | |
| `pnpm db:query <name>` | Run a dev/test database query |
| `pnpm db:query:list` | List all registered database queries |
| **Content** | |
| `pnpm content:build` | Build all published markdown → HTML |
| `pnpm content:build:id <id>` | Build a single article by ID |
| `pnpm content:list` | List all articles and their status |
| **Docker** | |
| `pnpm docker:optimize` | Audit Dockerfile against 12 best practices (use `/optimize-docker` in Claude) |
| **Getting Started** | |
| `/help` | List all commands, skills, and agents |
| `/quickstart` | Interactive first-run walkthrough for new users |
| **Setup** | |
| `/install-global` | Install/merge global Claude config into `~/.claude/` (one-time, never overwrites) |
| `/setup` | Interactive .env configuration — GitHub, database, Docker, analytics, RuleCatch |
| `/setup --reset` | Re-configure everything from scratch |
| `/set-clean-as-default` | Make `clean` the default profile for `/new-project` (AI goodies, zero opinions) |
| `/reset-to-defaults` | Reset `/new-project` back to the `default` profile (full opinionated stack) |
| **RuleCatch** | |
| `pnpm ai:monitor` | Live view of AI activity — tokens, cost, violations, tool usage (separate terminal) |
| `/what-is-my-ai-doing` | Same as above — launches AI-Pooler monitor |
| **Git** | |
| `/worktree <name>` | Create isolated branch + worktree for a task (never touch main) |
| **Code Quality** | |
| `/refactor <file>` | Audit + refactor a file against all CLAUDE.md rules (split, type, extract, clean) |
| **API** | |
| `/create-api <resource>` | Scaffold a full API endpoint — route, handler, types, tests — wired into the server |
| **Documentation** | |
| `/diagram <type>` | Generate diagrams from actual code: `architecture`, `api`, `database`, `infrastructure`, `all` |
| **Utility** | |
| `pnpm clean` | Remove dist/, coverage/, test-results/, playwright-report/ |

---

## Critical Rules

### 0. NEVER Publish Sensitive Data

- NEVER commit passwords, API keys, tokens, or secrets to git/npm/docker
- NEVER commit `.env` files — ALWAYS verify `.env` is in `.gitignore`
- Before ANY commit: verify no secrets are included
- NEVER output secrets in suggestions, logs, or responses

### 1. TypeScript Always

- ALWAYS use TypeScript for new files (strict mode)
- NEVER use `any` unless absolutely necessary and documented why
- When editing JavaScript files, convert to TypeScript first
- Types are specs — they tell you what functions accept and return

### 2. API Versioning

```
CORRECT: /api/v1/users
WRONG:   /api/users
```

Every API endpoint MUST use `/api/v1/` prefix. No exceptions.

### 3. Database Access — Wrapper Only (`src/core/db/index.ts`)

**ABSOLUTE RULE: ALL database access goes through `src/core/db/index.ts`. No exceptions.**

- NEVER create `new MongoClient()` anywhere else in the codebase
- NEVER import `mongodb` directly in any file except `src/core/db/index.ts`
- NEVER use `mongoose` or any ODM — native MongoDB driver only
- ALWAYS import from `src/core/db/` for all database operations
- All query inputs are automatically sanitized against NoSQL injection (enabled by default)
- To disable sanitization: set `DB_SANITIZE_INPUTS=false` in `.env` or `sanitize = false` in `claude-mastery-project.conf`
- Programmatic toggle: `configureSanitization(false)` — only if you handle sanitization yourself

#### How to use the wrapper

```typescript
// CORRECT — import from the centralized wrapper
import { queryOne, queryMany, insertOne, updateOne, bulkOps, closePool } from '@/core/db/index.js';

// WRONG — NEVER do this
import { MongoClient } from 'mongodb';  // FORBIDDEN outside src/core/db/
const client = new MongoClient(uri);     // FORBIDDEN — creates rogue connection
```

#### Reading data — ALWAYS use aggregation

```typescript
// Single document lookup
const user = await queryOne<User>('users', { email });

// Multiple documents with pipeline
const recentOrders = await queryMany<Order>('orders', [
  { $match: { userId, status: 'active' } },
  { $sort: { createdAt: -1 } },
  { $limit: 20 },
]);

// Lookup/join — $limit is enforced BEFORE $lookup automatically
const userWithOrders = await queryWithLookup<UserWithOrders>('users', {
  match: { _id: userId },
  lookup: { from: 'orders', localField: '_id', foreignField: 'userId', as: 'orders' },
  unwind: 'orders',
});

// Count
const total = await count('users', { role: 'admin' });
```

#### Writing data — ALWAYS use bulkWrite

```typescript
// Insert
await insertOne('users', { email, name, createdAt: new Date() });
await insertMany('events', batchOfEvents);

// Update — use $inc for counters, $set for fields (NEVER read-modify-write)
await updateOne<User>('users', { _id: userId }, { $set: { name: 'New Name' } });
await updateOne<Stats>('stats', { date }, { $inc: { pageViews: 1, visitors: 1 } }, true); // upsert

// Complex batch operations (auto-retries E11000 concurrent upsert races)
await bulkOps('sessions', [
  { updateOne: { filter: { sessionId }, update: { $inc: { events: 1 } }, upsert: true } },
  { updateOne: { filter: { sessionId }, update: { $set: { lastSeen: new Date() } } } },
]);

// Delete
await deleteOne('tokens', { token: expiredToken });
```

#### Connection pool presets

```typescript
import { connect } from '@/core/db/index.js';

// High-traffic API service
await connect(undefined, { pool: 'high', label: 'API' });    // 20 max connections

// Standard service
await connect(undefined, { pool: 'standard', label: 'Web' }); // 10 max connections

// Low-traffic background job
await connect(undefined, { pool: 'low', label: 'Worker' });   // 5 max connections
```

#### Graceful shutdown — MANDATORY for every Node.js entry point

ANY crash or termination signal MUST close MongoDB pools before exiting.
NEVER call `process.exit()` without closing pools first.

```typescript
import { gracefulShutdown } from '@/core/db/index.js';

// Termination signals — clean exit
process.on('SIGTERM', () => gracefulShutdown(0));
process.on('SIGINT', () => gracefulShutdown(0));

// Crashes — close pools, then exit with error code
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  gracefulShutdown(1);
});
process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
  gracefulShutdown(1);
});
```

`gracefulShutdown()` is idempotent — safe to call from multiple signals.

#### Index management

Register indexes alongside your queries, then call `ensureIndexes()` once at startup:

```typescript
import { registerIndex, ensureIndexes } from '@/core/db/index.js';

// Register at module load time
registerIndex({ collection: 'users', fields: { email: 1 }, unique: true });
registerIndex({ collection: 'users', fields: { apiKey: 1 }, unique: true, sparse: true });
registerIndex({ collection: 'sessions', fields: { userId: 1, startedAt: -1 } });
registerIndex({ collection: 'tokens', fields: { expiresAt: 1 }, expireAfterSeconds: 0 }); // TTL

// Call once at app startup
await ensureIndexes();           // creates all registered indexes
await ensureIndexes({ dryRun: true }); // just logs what would be created
```

MongoDB skips indexes that already exist, so `ensureIndexes()` is safe to call every startup.

#### Test queries — `scripts/db-query.ts` (MANDATORY pattern)

**ABSOLUTE RULE: ALL ad-hoc / test / dev database queries go through the db-query system. No exceptions.**

When a developer asks to "look something up in the database", "check a collection", "find a user", or any exploratory query:

1. **Create a query file** in `scripts/queries/<descriptive-name>.ts`
2. **Register it** in `scripts/db-query.ts` query registry
3. **NEVER** create standalone scripts, one-off files, or inline queries in `src/`

```typescript
// scripts/queries/find-expired-sessions.ts
import { queryMany } from '../../src/core/db/index.js';

export default {
  name: 'find-expired-sessions',
  description: 'Find sessions that expired in the last 24 hours',
  async run(args: string[]): Promise<void> {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const sessions = await queryMany('sessions', [
      { $match: { expiresAt: { $lt: cutoff } } },
      { $sort: { expiresAt: -1 } },
      { $limit: 50 },
    ]);
    console.log(`Found ${sessions.length} expired sessions:`);
    console.log(JSON.stringify(sessions, null, 2));
  },
};
```

Then register in `scripts/db-query.ts`:
```typescript
const queryRegistry = {
  'find-expired-sessions': () => import('./queries/find-expired-sessions.js'),
};
```

Run: `npx tsx scripts/db-query.ts find-expired-sessions`

**Why this matters:**
- **One place for all test queries** — no random scripts scattered across the project
- **Clear separation** — `scripts/queries/` = dev/test, `src/` = production only
- **Every query uses the wrapper** — enforces the same connection pool and patterns
- **Easy cleanup** — when done exploring, delete the query file and its registry entry
- **Discoverable** — `npx tsx scripts/db-query.ts --list` shows all available queries

**FORBIDDEN patterns:**
```typescript
// NEVER do this — creates rogue query files outside the system
// scripts/check-users.ts        ← WRONG
// src/utils/debug-query.ts      ← WRONG
// src/handlers/temp-lookup.ts   ← WRONG

// ALWAYS do this — use the db-query system
// scripts/queries/check-users.ts + register in db-query.ts  ← CORRECT
```

**Why this matters (overall Rule 3):**
- **One pool** — prevents connection exhaustion (the #1 Claude Code database failure)
- **One place to change** — swap databases without touching business logic
- **One place to mock** — testing becomes trivial
- **Aggregation only** — consistent, flexible, supports joins
- **BulkWrite only** — atomic, better performance than individual operations
- **$limit before $lookup** — prevents joining entire collections (massive perf hit)
- **One place for test queries** — no scripts scattered across the project

### 4. Testing — Explicit Success Criteria

- ALWAYS define explicit success criteria for E2E tests
- "Page loads" is NOT a success criterion
- Every test MUST verify: URL, visible elements, data displayed
- NEVER write tests without assertions
- Use `/create-e2e <feature>` to create E2E tests with proper structure

```typescript
// CORRECT — explicit success criteria (MINIMUM 3 assertions per test)
await expect(page).toHaveURL('/dashboard');              // 1. URL
await expect(page.locator('h1')).toContainText('Welcome'); // 2. Element visible
await expect(page.locator('[data-testid="user"]')).toContainText('test@example.com'); // 3. Data correct

// WRONG — passes even if broken
await page.goto('/dashboard');
// no assertion!
```

**A test is NOT finished until it has:**
- At least one URL assertion (`toHaveURL`)
- At least one element visibility assertion (`toBeVisible`)
- At least one content/data assertion (`toContainText`, `toHaveValue`)
- Error case coverage (what happens when it fails?)

**E2E test execution — ALWAYS kills test ports first:**
```bash
pnpm test:e2e          # kills ports 4000/4010/4020 → spawns servers → runs Playwright
pnpm test:e2e:headed   # same but with visible browser
pnpm test:e2e:ui       # same but with Playwright UI mode
```

E2E tests run on TEST ports (4000, 4010, 4020) — never dev ports.
`playwright.config.ts` spawns servers automatically via `webServer`.

### 5. NEVER Hardcode Credentials

- ALWAYS use environment variables for secrets
- NEVER put API keys, passwords, or tokens directly in code
- NEVER hardcode connection strings — use DATABASE_URL from .env

### 6. ALWAYS Ask Before Deploying

- NEVER auto-deploy, even if the fix seems simple
- NEVER assume approval — wait for explicit "yes, deploy"
- ALWAYS ask before deploying to production

### 7. Quality Gates

- No file > 300 lines (split if larger)
- No function > 50 lines (extract helper functions)
- All tests must pass before committing
- TypeScript must compile with no errors (`tsc --noEmit`)

### 8. Parallelize Independent Awaits

- When multiple `await` calls are independent (none depends on another's result), ALWAYS use `Promise.all`
- NEVER await independent operations sequentially — it wastes time
- Before writing sequential awaits, evaluate: does the second call need the first call's result?

```typescript
// CORRECT — independent operations run in parallel
const [users, products, orders] = await Promise.all([
  getUsers(),
  getProducts(),
  getOrders(),
]);

// WRONG — sequential when they don't depend on each other
const users = await getUsers();
const products = await getProducts();  // waits for users unnecessarily
const orders = await getOrders();      // waits for products unnecessarily
```

```typescript
// CORRECT — sequential when there IS a dependency
const user = await getUserById(id);
const orders = await getOrdersByUserId(user.id); // needs user.id
```

### 9. Git Workflow — NEVER Work Directly on Main

**Auto-branch is ON by default.** Every command that modifies code will automatically create a feature branch when it detects you're on main. No manual step required.

- Commands auto-create branches like `refactor/<name>`, `test/<name>`, `feat/<name>`, `chore/<name>`
- You never work on main by accident — the commands handle it
- Use `/worktree <branch-name>` when you want a separate directory (parallel sessions)
- If Claude screws up on a feature branch, delete it — main is untouched

```bash
# What happens automatically:
# 1. You run /refactor src/handlers/users.ts while on main
# 2. Command creates branch: git checkout -b refactor/users
# 3. Refactor happens on the new branch
# 4. Main is never touched

# For parallel sessions (separate directories):
/worktree add-auth                # creates branch + separate working directory

# To disable auto-branching:
# Set auto_branch = false in claude-mastery-project.conf
```

**Before merging any branch back to main:**
1. Review the full diff: `git diff main...HEAD`
2. Ask the user: "Do you want RuleCatch to check for violations on this branch?"
3. Only merge after the user confirms

**Why this matters:**
- Main should always be deployable
- Feature branches are disposable — delete and start over if needed
- `git diff main...HEAD` shows exactly what changed, making review easy
- Auto-branching means zero friction — you don't have to remember
- Worktrees let you run multiple Claude sessions in parallel without conflicts
- RuleCatch catches violations Claude missed — last line of defense before merge

### 10. Docker Push Gate — Local Test Before Push

**Disabled by default.** When enabled (`docker_test_before_push = true` in `claude-mastery-project.conf`), ANY `docker push` is BLOCKED until the image passes local verification:

1. Build the image
2. Run the container locally
3. Wait 5 seconds for startup
4. Verify container is still running (didn't crash/exit)
5. Hit the health endpoint (must return 200)
6. Check logs for fatal errors
7. Clean up test container
8. **Only then** allow `docker push`

If any step fails: STOP, show what failed, and do NOT push.

```bash
# Enable in claude-mastery-project.conf:
docker_test_before_push = true

# Disable (default):
docker_test_before_push = false
```

This gate applies globally — every command or workflow that pushes to Docker Hub must respect it.

---

## When Something Seems Wrong

Before jumping to conclusions:

- Missing UI element? → Check feature gates BEFORE assuming bug
- Empty data? → Check if services are running BEFORE assuming broken
- 404 error? → Check service separation BEFORE adding endpoint
- Auth failing? → Check which auth system BEFORE debugging
- Test failing? → Read the error message fully BEFORE changing code

---

## Windows Users — Use VS Code in WSL Mode

If you're on Windows, you should be running VS Code in **WSL 2 mode**. Most people don't know this exists and it dramatically changes everything:

- **HMR is 5-10x faster** — file changes don't cross the Windows/Linux boundary
- **Playwright tests run significantly faster** — native Linux browser processes
- **File watching actually works** — `tsx watch`, `next dev`, `nodemon` are all reliable
- **Node.js filesystem operations** avoid the slow NTFS translation layer
- **Claude Code runs faster** — native Linux tools (`grep`, `find`, `git`)

**CRITICAL:** Your project must be on the **WSL filesystem** (`~/projects/`), NOT on `/mnt/c/`. Having WSL but keeping your project on the Windows filesystem gives you the worst of both worlds.

```bash
# Check if you're set up correctly:
pwd
# GOOD: /home/you/projects/my-app
# BAD:  /mnt/c/Users/you/projects/my-app  ← still hitting Windows filesystem

# VS Code: click green "><" icon bottom-left → "Connect to WSL"
```

Run `/setup` to auto-detect your environment and get specific instructions.

---

## Service Ports (FIXED — NEVER CHANGE)

| Service | Dev Port | Test Port | URL |
|---------|----------|-----------|-----|
| Website | 3000 | 4000 | http://localhost:{port} |
| API | 3001 | 4010 | http://localhost:{port} |
| Dashboard | 3002 | 4020 | http://localhost:{port} |

When starting any service, ALWAYS use its assigned port:

```bash
# CORRECT
npx next dev -p 3002

# WRONG — never let it default
npx next dev
```

Before starting services, ALWAYS kill existing processes on those ports:

```bash
lsof -ti:3000,3001,3002 | xargs kill -9 2>/dev/null
```

---

## Project Structure

```
project/
├── CLAUDE.md              # You are here
├── CLAUDE.local.md        # Personal overrides (gitignored)
├── .claude/
│   ├── commands/          # Slash commands (/review, /refactor, /worktree, /new-project, etc.)
│   ├── skills/            # Triggered expertise & scaffolding templates
│   ├── agents/            # Custom subagents
│   └── hooks/             # Enforcement scripts (9 hooks: secrets, branch, ports, rybbit, e2e, lint, env-sync, rulecatch)
├── project-docs/
│   ├── ARCHITECTURE.md    # System overview & data flow
│   ├── INFRASTRUCTURE.md  # Deployment & environment details
│   └── DECISIONS.md       # Why we chose X over Y
├── docs/                  # GitHub Pages site
├── src/
│   ├── core/
│   │   └── db/            # Centralized database wrapper
│   ├── handlers/          # Business logic
│   ├── adapters/          # External service wrappers
│   └── types/             # Shared TypeScript types
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── scripts/
│   ├── db-query.ts        # Test Query Master — index of all dev/test queries
│   ├── queries/           # Individual query files (dev/test only, NOT production)
│   ├── build-content.ts   # Markdown → HTML article builder
│   └── content.config.json # Article registry (source, output, SEO metadata)
├── content/               # Markdown source files for articles/posts
├── .env.example           # Template with placeholders (committed)
├── .env                   # Actual secrets (NEVER committed)
├── .gitignore
├── .dockerignore
├── package.json           # All scripts: dev, test, db:query, content:build, ai:monitor
├── claude-mastery-project.conf # Profile presets for /new-project (clean, default, api, etc.)
├── playwright.config.ts   # E2E test config (test ports 4000/4010/4020, webServer)
├── vitest.config.ts       # Unit/integration test config
└── tsconfig.json
```

---

## Project Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| `project-docs/ARCHITECTURE.md` | System overview & data flow | Before architectural changes |
| `project-docs/INFRASTRUCTURE.md` | Deployment details | Before environment changes |
| `project-docs/DECISIONS.md` | Architectural decisions | Before proposing alternatives |

**ALWAYS read relevant docs before making cross-service changes.**

---

## Coding Standards

### Imports

```typescript
// CORRECT — explicit, typed
import { getUserById } from './handlers/users.js';
import type { User } from './types/index.js';

// WRONG — barrel imports that pull everything
import * as everything from './index.js';
```

### Error Handling

```typescript
// CORRECT — handle errors explicitly
try {
  const user = await getUserById(id);
  if (!user) throw new NotFoundError('User not found');
  return user;
} catch (err) {
  logger.error('Failed to get user', { id, error: err });
  throw err;
}

// WRONG — swallow errors silently
try {
  return await getUserById(id);
} catch {
  return null; // silent failure
}
```

---

## Naming — NEVER Rename Mid-Project

Renaming packages, modules, or key variables mid-project causes cascading failures that are extremely hard to catch. If you must rename:

1. Create a checklist of ALL files and references first
2. Use IDE semantic rename (not search-and-replace)
3. Full project search for old name after renaming
4. Check: .md files, .txt files, .env files, comments, strings, paths
5. Start a FRESH Claude session after renaming

---

## Plan Mode — Plan First, Code Second

**For any non-trivial task, start in plan mode.** Don't let Claude write code until you've agreed on the plan. Bad plan = bad code. Always.

- Use plan mode for: new features, refactors, architectural changes, multi-file edits
- Skip plan mode for: typo fixes, single-line changes, obvious bugs
- One Claude writes the plan. You review it as the engineer. THEN code.

### Step Naming — MANDATORY

Every step in a plan MUST have a consistent, unique name. This is how the user references steps when requesting changes. Claude forgets to update plans — named steps make it unambiguous.

```
CORRECT — named steps the user can reference:
  Step 1 (Project Setup): Initialize repo with TypeScript
  Step 2 (Database Layer): Create MongoDB wrapper
  Step 3 (Auth System): Implement JWT authentication
  Step 4 (API Routes): Create user endpoints
  Step 5 (Testing): Write E2E tests for auth flow

WRONG — generic steps nobody can reference:
  Step 1: Set things up
  Step 2: Build the backend
  Step 3: Add tests
```

### Modifying a Plan — REPLACE, Don't Append

When the user asks to change something in the plan:

1. **FIND** the exact named step being changed
2. **REPLACE** that step's content entirely with the new approach
3. **Review ALL other steps** for contradictions with the change
4. **Rewrite the full updated plan** so the user can see the complete picture

```
CORRECT:
  User: "Change Step 3 (Auth System) to use session cookies instead of JWT"
  Claude: Replaces Step 3 content, checks Steps 4-5 for JWT references,
          outputs the FULL updated plan with Step 3 rewritten

WRONG:
  User: "Actually use session cookies instead"
  Claude: Appends "Also, use session cookies" at the bottom
          ← Step 3 still says JWT. Now the plan contradicts itself.
```

**Claude will forget to do this.** If you notice the plan has contradictions, tell Claude: "Rewrite the full plan — Step 3 and Step 7 contradict each other."

- If fundamentally changing direction: `/clear` → state requirements fresh

---

## Documentation Sync

When updating any feature, keep these locations in sync:

1. `README.md` (repository root)
2. `docs/index.html` (GitHub Pages site)
3. `project-docs/` (relevant documentation)
4. `CLAUDE.md` quick reference table (if adding commands/scripts)
5. `tests/STARTER-KIT-VERIFICATION.md` (if adding hooks/files)
6. Inline code comments
7. Test descriptions

If you update one, update ALL.

### Adding a New Command or Hook — MANDATORY Checklist

When creating a new `.claude/commands/*.md` or `.claude/hooks/*.sh`:

1. **README.md** — Update the command count, project structure tree, and add a description section
2. **docs/index.html** — Update the command count, project structure tree, and add a command card
3. **CLAUDE.md** — Add to the quick reference table (if user-facing)
4. **tests/STARTER-KIT-VERIFICATION.md** — Add verification checklist entry
5. **.claude/settings.json** — Wire up hooks (if adding a hook)

**This is NOT optional.** Every command/hook must appear in all five locations before the commit.

---

## CLAUDE.md Is Team Memory — The Feedback Loop

Every time Claude makes a mistake, **add a rule to prevent it from happening again.**

This is the single most powerful pattern for improving Claude's behavior over time:

1. Claude makes a mistake (wrong pattern, bad assumption, missed edge case)
2. You fix the mistake
3. You tell Claude: "Update CLAUDE.md so you don't make that mistake again"
4. Claude adds a rule to this file
5. Mistake rates actually drop over time

**This file is checked into git. The whole team benefits from every lesson learned.**

Don't just fix bugs — fix the rules that allowed the bug. Every mistake is a missing rule.

**If RuleCatch is installed:** also add the rule as a custom RuleCatch rule so it's monitored automatically across all future sessions. CLAUDE.md rules are suggestions — RuleCatch enforces them.

---

## Workflow Preferences

- Quality over speed — if unsure, ask before executing
- Plan first, code second — use plan mode for non-trivial tasks
- One task, one chat — `/clear` between unrelated tasks
- One task, one branch — use `/worktree` to isolate work from main
- Use `/context` to check token usage when working on large tasks
- When testing: queue observations, fix in batch (not one at a time)
- Research shows 2% misalignment early in a conversation can cause 40% failure rate by end — start fresh when changing direction
