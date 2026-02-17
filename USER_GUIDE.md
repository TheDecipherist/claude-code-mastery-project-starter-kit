# User Guide — Claude Code Starter Kit

> The hands-on companion to the README. This guide walks you through every feature with step-by-step tutorials, real examples, and practical workflows.
>
> **Interactive version:** [View as HTML](https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/user-guide.html) with syntax highlighting, sidebar navigation, and search.

---

## Table of Contents

- [Part 1: Getting Started](#part-1-getting-started)
- [Part 2: Daily Workflow](#part-2-daily-workflow)
- [Part 3: Commands Deep Dive](#part-3-commands-deep-dive)
- [Part 4: Hook System Explained](#part-4-hook-system-explained)
- [Part 5: Database Wrapper](#part-5-database-wrapper)
- [Part 6: CLAUDE.md Customization](#part-6-claudemd-customization)
- [Part 7: Testing](#part-7-testing)
- [Part 8: Deployment](#part-8-deployment)
- [Part 9: Troubleshooting](#part-9-troubleshooting)
- [Part 10: FAQ](#part-10-faq)

---

## Part 1: Getting Started

### What This Kit Does

The Claude Code Starter Kit is a **scaffold template** that supercharges Claude Code with battle-tested rules, automated enforcement, and on-demand tools. It's not an app — it's the foundation that makes every app you build with Claude dramatically better.

Think of it as a senior engineer's playbook, encoded into files that Claude reads and follows:

- **CLAUDE.md** tells Claude *what rules to follow*
- **Hooks** *enforce* those rules automatically (no forgetting)
- **Slash commands** give you *on-demand tools* for common tasks
- **Skills** activate *automatically* when Claude detects relevant context
- **Agents** handle *specialized work* like security audits and test writing

### Decision Tree: Which Path Is Right for You?

```
Are you starting a brand new project?
├── YES → Use /new-project
│   ├── Want full opinions (TypeScript, ports, quality gates)?
│   │   └── /new-project my-app default
│   ├── Want just AI tooling, zero coding opinions?
│   │   └── /new-project my-app clean
│   ├── Building a Go API?
│   │   └── /new-project my-api go
│   ├── Building a Python API?
│   │   └── /new-project my-api python-api
│   └── Want to pick everything yourself?
│       └── /new-project my-app fullstack next dokploy tailwind pnpm
│
├── NO → Do you have an existing project?
│   ├── Not yet using starter kit?
│   │   └── /convert-project-to-starter-kit ~/projects/my-app
│   └── Already using starter kit? Want latest updates?
│       └── /update-project
│
└── Want to customize the template itself?
    └── Clone the repo, modify commands/hooks/rules, use as your own source
```

### Tutorial: Your First Project in 5 Minutes

**Step 1: Install global config (one time only)**

```bash
/install-global
```

This merges security rules and hooks into `~/.claude/`. It never overwrites your existing config.

**Step 2: Create your project**

```bash
/new-project my-app clean
```

This creates `~/projects/my-app` with all Claude Code tooling — commands, hooks, skills, agents, documentation templates — and zero coding opinions. You pick the language, framework, and database yourself.

For a fully opinionated setup (Next.js + TypeScript + MongoDB + Tailwind):

```bash
/new-project my-app default
```

**Step 3: Enter the project**

```bash
cd ~/projects/my-app
```

**Step 4: Configure your environment**

```bash
/setup
```

This walks you through setting up `.env` interactively — database, GitHub, Docker, analytics. It skips variables that already have values and never displays secrets back to you.

**Step 5: Start building**

```bash
claude
```

That's it. Claude now has all the rules, hooks, and commands ready to go.

### Tutorial: Understanding What Got Created

After running `/new-project my-app clean`, here's what's in your project:

```
my-app/
├── .claude/
│   ├── commands/       ← 25 slash commands (16 project + 9 kit management)
│   ├── skills/         ← Auto-triggered expertise templates
│   ├── agents/         ← Specialist subagents (reviewer, test writer)
│   ├── hooks/          ← 9 enforcement scripts that always run
│   └── settings.json   ← Hooks wired to lifecycle events
├── project-docs/
│   ├── ARCHITECTURE.md ← System overview (fill in as you build)
│   ├── INFRASTRUCTURE.md ← Deployment details
│   └── DECISIONS.md    ← Why you chose X over Y
├── tests/
│   ├── CHECKLIST.md    ← Master test tracker
│   └── ISSUES_FOUND.md ← Bug tracking log
├── CLAUDE.md           ← The rules Claude follows
├── CLAUDE.local.md     ← Your personal preferences (gitignored)
├── .env                ← Secrets (never committed)
├── .env.example        ← Template with placeholders
├── .gitignore          ← Includes .env, CLAUDE.local.md
└── .dockerignore       ← Keeps secrets out of images
```

The `default` profile adds more: `src/core/db/index.ts` (database wrapper), `package.json`, `tsconfig.json`, `playwright.config.ts`, `vitest.config.ts`, and framework-specific files.

---

## Part 2: Daily Workflow

### The Development Loop

The most effective workflow with Claude Code follows this cycle:

```
Write Code → /review → Fix Issues → /commit → Repeat
```

**1. Write code** — Tell Claude what you want to build. The CLAUDE.md rules guide every decision.

**2. Review** — Run `/review` to check against the 7-point checklist (security, types, errors, performance, testing, database, API versioning).

**3. Fix** — Address any Critical or Warning issues flagged by the review.

**4. Commit** — Run `/commit` to generate a conventional commit message from the staged changes.

**5. Repeat** — Start the next feature or fix.

### Using `/progress` to Track Where You Are

Run `/progress` at any time to see:

- Source file counts by type
- Test coverage status
- Recent git activity
- Prioritized next actions

This gives you a quick snapshot without leaving the Claude session.

### When to `/clear` and Start Fresh

Use `/clear` between unrelated tasks. Research shows **39% performance degradation** when mixing topics in a single conversation. Signs you should clear:

- Switching from frontend work to backend work
- Moving from bug fixing to feature development
- Claude seems confused about context or keeps referencing old code
- You've been in the same session for a long time and responses feel "off"

A 2% misalignment early in a conversation can cause **40% failure rate** by the end. When in doubt, clear.

### Working with Branches

**Auto-branch is ON by default.** You never need to remember to create a branch. Every command that modifies code automatically creates a feature branch when it detects you're on main:

- `/refactor src/users.ts` → creates `refactor/users` branch
- `/create-api orders` → creates `feat/orders` branch
- `/commit` → creates a branch if you're on main

**If Claude screws up on a branch** — just delete it. Main was never touched.

**For parallel sessions**, use `/worktree`:

```bash
/worktree add-auth        # Creates branch + separate working directory
/worktree add-payments    # Another isolated workspace
```

Each worktree gets its own directory and branch, so you can run multiple Claude sessions simultaneously without conflicts.

---

## Part 3: Commands Deep Dive

### Getting Started Commands

#### `/help`

Lists every command, skill, and agent grouped by category. Run this whenever you forget what's available.

```
Example output:
──────────────────────────────────────
  GETTING STARTED
  /help              List all commands
  /quickstart        Interactive first-run
  /install-global    Install global config
  /setup             Configure .env

  CODE QUALITY
  /review            Code review (7-point)
  /refactor <file>   Audit + refactor
  /commit            Smart commit
  /security-check    Scan for secrets
  ...
──────────────────────────────────────
```

#### `/quickstart`

Interactive first-run walkthrough for new users. Checks if global config is installed, asks for project name and profile, then walks you through scaffolding, setup, first dev server, first review, and first commit.

Best for: Someone who just cloned the starter kit and doesn't know where to start.

#### `/install-global`

One-time setup that installs global Claude config into `~/.claude/`:

- **CLAUDE.md** — Global security rules
- **settings.json** — Hook configurations and deny rules
- **Hooks** — `block-secrets.py`, `verify-no-secrets.sh`, `check-rulecatch.sh`

Uses smart merge — if you already have config, it adds missing sections without overwriting yours. Reports exactly what was added, skipped, and merged.

#### `/setup`

Interactive `.env` configuration. Walks through:

- Database (MongoDB/PostgreSQL, connection strings)
- GitHub (username, SSH vs HTTPS)
- Docker (Hub username, image name)
- Analytics (Rybbit site ID)
- RuleCatch (API key, region)
- Auth (auto-generates JWT secret)

Supports multi-region setups (US + EU with isolated databases). Skips variables that already have values. Use `/setup --reset` to reconfigure everything.

#### `/show-user-guide`

Opens this guide in your browser. Tries the GitHub Pages URL first, falls back to the local HTML file.

### Code Quality Commands

#### `/review`

Systematic code review against a 7-point checklist:

1. **Security** — OWASP Top 10, no secrets in code
2. **Types** — No `any`, proper null handling
3. **Error Handling** — No swallowed errors
4. **Performance** — No N+1 queries, no memory leaks
5. **Testing** — New code has explicit assertions
6. **Database** — Using centralized wrapper
7. **API Versioning** — All endpoints use `/api/v1/`

Issues are reported with severity levels:

- **Critical** — Must fix before commit (security issues, data loss risks)
- **Warning** — Should fix (performance, maintainability)
- **Info** — Consider improving (style, naming)

Each issue includes file:line reference and a suggested fix.

#### `/refactor <file>`

Audits a file against **every rule** in CLAUDE.md, then refactors:

1. Branch check — not on main? Good. On main? Suggests `/worktree`
2. File size — >300 lines? Splits into focused modules
3. Function size — >50 lines? Extracts helpers
4. TypeScript — removes `any`, adds explicit types
5. Import hygiene — no barrel imports, proper `import type`
6. Error handling — no swallowed errors
7. Database access — wrapper only
8. API routes — `/api/v1/` prefix
9. Promise.all — parallelizes independent awaits
10. Security + dead code — removes unused code, checks for secrets

```bash
/refactor src/handlers/users.ts          # Full audit + refactor
/refactor src/server.ts --dry-run        # Report only, no changes
```

Presents a named-step plan before making changes. You approve before anything is modified.

#### `/commit`

Smart commit with conventional commit format. Reviews staged changes and generates a message using `type(scope): description`:

- `feat(auth): add JWT token refresh endpoint`
- `fix(db): prevent connection pool exhaustion on hot reload`
- `refactor(users): split handler into focused modules`

Warns if changes span multiple concerns and suggests splitting into separate commits.

#### `/security-check`

Scans the project for vulnerabilities:

- Secrets in source code (API keys, passwords, tokens)
- `.gitignore` coverage gaps
- Sensitive files tracked by git
- `.env` handling audit
- Dependency vulnerability scan (`npm audit`)

### Scaffolding Commands

#### `/new-project`

Full project scaffolding with profiles:

```bash
/new-project my-app clean              # AI tooling only, zero opinions
/new-project my-app default            # Full stack: Next.js + MongoDB + Tailwind
/new-project my-api api fastify        # API only with Fastify
/new-project my-api go                 # Go API with Gin + MongoDB
/new-project my-api go chi postgres    # Go with Chi + PostgreSQL
/new-project my-app vue                # Vue 3 SPA with Tailwind
/new-project my-app nuxt               # Nuxt full-stack
/new-project my-app sveltekit          # SvelteKit full-stack
/new-project my-api python-api         # FastAPI + PostgreSQL
/new-project my-app django             # Django full-stack
```

Each profile configures the right language rules, frameworks, database wrappers, test infrastructure, and build tools. The `clean` profile gives you all AI tooling with zero coding opinions.

#### `/create-api <resource>`

Scaffolds a production-ready API endpoint:

- **Types** — `src/types/<resource>.ts`
- **Handler** — `src/handlers/<resource>.ts`
- **Route** — `src/routes/v1/<resource>.ts`
- **Tests** — `tests/unit/<resource>.test.ts`

Uses the db wrapper, auto-sanitized inputs, pagination, registered indexes, and `/api/v1/` prefix.

```bash
/create-api users           # Full CRUD for users
/create-api orders --no-mongo  # Skip MongoDB integration
```

#### `/create-e2e <feature>`

Generates a Playwright E2E test with proper structure:

- Happy path with 3+ assertions (URL, visibility, content)
- Error cases (404, unauthorized, invalid input)
- Edge cases (empty state, large data, concurrent access)

Reads the source code to identify URLs, elements, and data to verify. Creates the test at `tests/e2e/<feature>.spec.ts`.

### Infrastructure Commands

#### `/diagram`

Scans actual code and generates ASCII diagrams:

```bash
/diagram architecture    # Services, connections, data flow
/diagram api             # All endpoints grouped by resource
/diagram database        # Collections, indexes, relationships
/diagram infrastructure  # Deployment topology, containers
/diagram all             # Generate everything at once
```

Writes to `project-docs/ARCHITECTURE.md` and `project-docs/INFRASTRUCTURE.md`. Uses ASCII box-drawing — works everywhere, no external tools needed.

#### `/architecture`

Reads and displays `project-docs/ARCHITECTURE.md`. If it doesn't exist, scaffolds a template.

#### `/optimize-docker`

Audits your Dockerfile against 12 best practices:

- Multi-stage builds
- Layer caching optimization
- Alpine base images
- Non-root user
- .dockerignore coverage
- Frozen lockfile
- Health checks
- No secrets in build args
- Pinned versions

Generates an optimized Dockerfile with before/after image size comparison.

### Project Management Commands

#### `/progress`

Checks the filesystem and reports project status — file counts by type, test coverage, git activity, and prioritized next actions.

#### `/test-plan`

Generates a structured test plan for any feature:

- Prerequisites
- Happy path scenarios with expected outcomes
- Error cases and edge cases
- Pass/fail criteria table
- Sign-off tracker

#### `/worktree <name>`

Creates an isolated git worktree + branch:

```bash
/worktree add-auth          # → task/add-auth branch + directory
/worktree feat/dashboard    # → uses prefix as-is
```

Each worktree gets its own branch and directory. Main stays untouched. Enables running multiple Claude sessions in parallel.

### Monitoring Commands

#### `/what-is-my-ai-doing`

Launches the RuleCatch AI-Pooler live monitor in a separate terminal. Free monitor mode works instantly — no API key needed.

Shows: every tool call, token usage, cost per turn, files accessed, cost per session.

```bash
# Run in a separate terminal
pnpm ai:monitor
```

Zero token overhead — runs completely outside Claude's context.

### Meta Commands

#### `/set-project-profile-default`

Sets the default profile for `/new-project`. Accepts any profile name:

```bash
/set-project-profile-default vue
/set-project-profile-default go
/set-project-profile-default mongo next tailwind docker  # Custom combo
```

#### `/add-project-setup`

Interactive wizard to create a named profile in `claude-mastery-project.conf`. Asks about language, framework, database, hosting, package manager, analytics, and MCP servers.

#### `/projects-created`

Lists every project scaffolded by `/new-project` — creation date, profile, language, framework, database, and location. Checks which still exist on disk.

#### `/remove-project <name>`

Removes a project from the registry and optionally deletes files from disk. Shows details before acting, asks for confirmation.

#### `/convert-project-to-starter-kit`

Merges starter kit infrastructure into an existing project non-destructively:

```bash
/convert-project-to-starter-kit ~/projects/my-app
/convert-project-to-starter-kit ~/projects/my-app --force  # Skip prompts
```

Creates a safety commit first. Detects your language, copies commands/hooks/skills/agents, merges CLAUDE.md sections and settings.json hooks. Undo with `git revert HEAD`.

#### `/update-project`

Updates an existing starter-kit project with the latest commands, hooks, skills, agents, and rules:

```bash
/update-project              # Pick from registered projects
/update-project --force      # Skip confirmation prompts
```

Smart merge — replaces starter kit files with newer versions while preserving any custom files you created. Shows a diff report (new, updated, unchanged, custom) before applying. Creates a safety commit first so you can `git revert HEAD` to undo.

---

## Part 4: Hook System Explained

### What Hooks Are

Hooks are shell/python scripts that run automatically at specific points in Claude's lifecycle. Unlike CLAUDE.md rules (which are suggestions), hooks are **guaranteed to run**. They can't be forgotten or ignored.

### The Lifecycle

```
┌─────────────────────────────────────────────┐
│  PreToolUse                                 │
│  Runs BEFORE Claude uses a tool             │
│  Can BLOCK the action (exit code 2)         │
│                                             │
│  → block-secrets.py (Read/Edit/Write)       │
│  → check-rybbit.sh  (Bash - deploy)         │
│  → check-branch.sh  (Bash - git commit)     │
│  → check-ports.sh   (Bash - dev servers)    │
│  → check-e2e.sh     (Bash - git push)       │
├─────────────────────────────────────────────┤
│  PostToolUse                                │
│  Runs AFTER Claude uses a tool              │
│  Informational (exit 0 always)              │
│                                             │
│  → lint-on-save.sh   (Write)                │
├─────────────────────────────────────────────┤
│  Stop                                       │
│  Runs when Claude FINISHES a turn           │
│  Can warn but typically doesn't block       │
│                                             │
│  → verify-no-secrets.sh                     │
│  → check-rulecatch.sh                       │
│  → check-env-sync.sh                        │
└─────────────────────────────────────────────┘
```

### Each Hook Explained

#### `block-secrets.py` (PreToolUse: Read|Edit|Write)

**What it does:** Blocks Claude from reading or editing sensitive files like `.env`, `credentials.json`, SSH keys, and `.npmrc`.

**When it triggers:** Before any Read, Edit, or Write tool call.

**What it blocks:** Files matching sensitive filenames (`.env`, `.env.local`, `secrets.json`, `id_rsa`, `id_ed25519`, `.npmrc`, `credentials.json`, `service-account.json`) and sensitive path patterns (`/.ssh/`, `/aws/credentials`, `private_key.pem`).

**Exit code 2** = operation blocked. Claude sees a message explaining why.

#### `check-branch.sh` (PreToolUse: Bash)

**What it does:** Blocks `git commit` on main/master when auto-branch is enabled.

**When it triggers:** Before any Bash command containing `git commit`.

**Logic:** If auto-branch is true (default) and you're on main/master, blocks with a message to create a feature branch first. Respects the `auto_branch` setting in `claude-mastery-project.conf`.

#### `check-rybbit.sh` (PreToolUse: Bash)

**What it does:** Blocks deployment commands if Rybbit analytics isn't configured.

**When it triggers:** Before `docker push`, `vercel deploy`, or Dokploy deployment commands.

**Logic:** Checks if `analytics = rybbit` is set in `claude-mastery-project.conf`. If yes, verifies `NEXT_PUBLIC_RYBBIT_SITE_ID` exists in `.env` with a real value (not a placeholder). Blocks with a link to https://app.rybbit.io if missing. Skips projects that don't use Rybbit.

#### `check-ports.sh` (PreToolUse: Bash)

**What it does:** Blocks dev server commands if the target port is already in use.

**When it triggers:** Before commands that start dev servers.

**Logic:** Detects the target port from `-p`, `--port`, `PORT=`, or known script names (`dev:website`→3000, `dev:api`→3001, etc.). If the port is in use, blocks and shows the PID + kill command.

#### `check-e2e.sh` (PreToolUse: Bash)

**What it does:** Blocks `git push` to main/master if no E2E tests exist.

**When it triggers:** Before `git push` commands targeting main/master.

**Logic:** Checks `tests/e2e/` for real `.spec.ts` or `.test.ts` files (excludes the example template). Blocks if no real E2E tests are found.

#### `lint-on-save.sh` (PostToolUse: Write)

**What it does:** Automatically checks TypeScript compilation, ESLint, or Python linting after Claude writes a file.

**When it triggers:** After any Write tool call.

**Logic:** Detects file extension and runs the appropriate linter:
- `.ts`/`.tsx` → `tsc --noEmit`
- `.js`/`.jsx` → `eslint`
- `.py` → `ruff check`

Informational only — never blocks.

#### `verify-no-secrets.sh` (Stop)

**What it does:** Scans staged git files for accidentally committed secrets.

**When it triggers:** When Claude finishes a turn.

**Logic:** Checks staged file contents for API key patterns, AWS credentials (`AKIA...`), and credential URLs. Warns if found.

#### `check-rulecatch.sh` (Stop)

**What it does:** Reports RuleCatch violations detected during the session.

**When it triggers:** When Claude finishes a turn.

**Logic:** Checks if RuleCatch is installed. If not, exits silently — zero overhead for users who haven't set it up.

#### `check-env-sync.sh` (Stop)

**What it does:** Compares key names between `.env` and `.env.example`.

**When it triggers:** When Claude finishes a turn.

**Logic:** If `.env` has keys that `.env.example` doesn't document, prints a warning. Informational only — never blocks. Never reads secret values.

### How to Disable a Hook Temporarily

Edit `.claude/settings.json` and comment out or remove the hook entry. Restart your Claude session for changes to take effect.

For example, to disable the branch check:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/check-rybbit.sh" },
          // Removed: check-branch.sh
          { "type": "command", "command": "bash .claude/hooks/check-ports.sh" },
          { "type": "command", "command": "bash .claude/hooks/check-e2e.sh" }
        ]
      }
    ]
  }
}
```

Or set `auto_branch = false` in `claude-mastery-project.conf` to disable branch protection without removing the hook.

### Creating Custom Hooks

Create a new script in `.claude/hooks/`:

```bash
#!/bin/bash
# .claude/hooks/my-custom-hook.sh

# Read the tool input from stdin (JSON)
INPUT=$(cat)

# Extract the command being run
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Your logic here
if echo "$COMMAND" | grep -q "something-dangerous"; then
    echo "BLOCKED: Reason for blocking" >&2
    exit 2  # Exit 2 = block the operation
fi

exit 0  # Exit 0 = allow the operation
```

Then wire it up in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/my-custom-hook.sh" }
        ]
      }
    ]
  }
}
```

### Debugging Hook Failures

1. **Check the hook is executable:** `ls -la .claude/hooks/`
2. **Test it manually:** `echo '{"tool_input":{"command":"git commit"}}' | bash .claude/hooks/check-branch.sh; echo "Exit: $?"`
3. **Check settings.json is valid:** `python3 -m json.tool .claude/settings.json`
4. **Restart Claude session** — hooks are loaded at session start
5. **Check the matcher** — does the tool name match? (`Read|Edit|Write`, `Bash`, `Write`)

---

## Part 5: Database Wrapper

### Why the Wrapper Exists

The #1 database failure in AI-assisted development is **connection pool exhaustion**. Without a centralized wrapper, Claude creates `new MongoClient()` in every file that needs database access. Each client opens its own connection pool. During development with hot reload, connections multiply until the database rejects new connections.

The wrapper solves this with a **singleton pattern** — one pool per URI, shared across the entire application.

### MongoDB Wrapper Cookbook

All database access goes through `src/core/db/index.ts`. No exceptions.

#### Reading Data

```typescript
import { queryOne, queryMany, queryWithLookup, count } from '@/core/db/index.js';

// Single document lookup
const user = await queryOne<User>('users', { email: 'test@example.com' });

// Multiple documents with pipeline
const recentOrders = await queryMany<Order>('orders', [
  { $match: { userId, status: 'active' } },
  { $sort: { createdAt: -1 } },
  { $limit: 20 },
]);

// Join with lookup ($limit enforced before $lookup automatically)
const userWithOrders = await queryWithLookup<UserWithOrders>('users', {
  match: { _id: userId },
  lookup: { from: 'orders', localField: '_id', foreignField: 'userId', as: 'orders' },
  unwind: 'orders',
});

// Count
const totalAdmins = await count('users', { role: 'admin' });
```

#### Writing Data

```typescript
import { insertOne, insertMany, updateOne, bulkOps, deleteOne } from '@/core/db/index.js';

// Insert
await insertOne('users', { email, name, createdAt: new Date() });
await insertMany('events', batchOfEvents);

// Update — use $inc for counters (never read-modify-write)
await updateOne<User>('users', { _id: userId }, { $set: { name: 'New Name' } });
await updateOne<Stats>('stats', { date }, { $inc: { pageViews: 1 } }, true); // upsert

// Batch operations (auto-retries E11000 concurrent races)
await bulkOps('sessions', [
  { updateOne: { filter: { sessionId }, update: { $inc: { events: 1 } }, upsert: true } },
  { updateOne: { filter: { sessionId }, update: { $set: { lastSeen: new Date() } } } },
]);

// Delete
await deleteOne('tokens', { token: expiredToken });
```

#### Connection Pool Presets

```typescript
import { connect } from '@/core/db/index.js';

await connect(undefined, { pool: 'high', label: 'API' });      // 20 connections
await connect(undefined, { pool: 'standard', label: 'Web' });   // 10 connections
await connect(undefined, { pool: 'low', label: 'Worker' });     // 5 connections
```

#### Index Management

```typescript
import { registerIndex, ensureIndexes } from '@/core/db/index.js';

// Register at module load time
registerIndex({ collection: 'users', fields: { email: 1 }, unique: true });
registerIndex({ collection: 'sessions', fields: { userId: 1, startedAt: -1 } });
registerIndex({ collection: 'tokens', fields: { expiresAt: 1 }, expireAfterSeconds: 0 });

// Call once at startup
await ensureIndexes();
```

MongoDB skips indexes that already exist, so `ensureIndexes()` is safe to call every startup.

### SQL Wrapper Cookbook

For PostgreSQL/MySQL/MSSQL/SQLite, the SQL wrapper lives at `src/core/db/sql.ts`.

```typescript
import { queryOne, queryMany, insertOne, withTransaction } from '@/core/db/sql.js';

// Read — ALWAYS parameterize
const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
const orders = await queryMany<Order>(
  'SELECT * FROM orders WHERE user_id = $1 AND status = $2 LIMIT $3',
  [userId, 'active', 20]
);

// Write
await insertOne('users', { email, name, created_at: new Date() });

// Transactions
await withTransaction(async (client) => {
  await client.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [100, fromId]);
  await client.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [100, toId]);
});
```

The wrapper auto-detects the driver from `DATABASE_URL`:
- `postgresql://` or `postgres://` → pg
- `mysql://` → mysql2
- `mssql://` → mssql
- `file:` or `sqlite:` → better-sqlite3

### The db-query System

All dev/test database queries go through `scripts/db-query.ts`:

```bash
pnpm db:query find-expired-sessions    # Run a registered query
pnpm db:query:list                     # List all available queries
```

Create query files in `scripts/queries/`:

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
    console.log(`Found ${sessions.length} expired sessions`);
  },
};
```

Register in `scripts/db-query.ts` and run. Production code stays clean — test queries live in `scripts/queries/`.

### Graceful Shutdown Pattern

**Mandatory for every Node.js entry point:**

```typescript
import { gracefulShutdown } from '@/core/db/index.js';

process.on('SIGTERM', () => gracefulShutdown(0));
process.on('SIGINT', () => gracefulShutdown(0));

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

---

## Part 6: CLAUDE.md Customization

### How Rules Work

CLAUDE.md is a markdown file that Claude reads at the start of every session. It contains the rules, patterns, and conventions that govern Claude's behavior in your project.

There are two levels:

| File | Scope | Checked into git? | Who sees it? |
|------|-------|-------------------|--------------|
| `CLAUDE.md` | Team rules | Yes | Everyone |
| `CLAUDE.local.md` | Personal preferences | No (gitignored) | Only you |

### Adding Your Own Rules

Open `CLAUDE.md` and add a rule to the appropriate section. Use strong language — Claude responds to "NEVER" and "ALWAYS" more consistently than "try to" or "prefer":

```markdown
### Rule 11: Always Use Relative Imports

- NEVER use absolute paths in imports
- ALWAYS use relative paths from the current file
- This prevents path mapping issues across environments
```

### CLAUDE.local.md for Personal Preferences

`CLAUDE.local.md` is gitignored. Use it for personal preferences:

```markdown
## Communication Style
- Respond concisely — I prefer terse explanations
- Show me the code first, explain after

## Testing Preferences
- Always run E2E tests headed so I can watch
- Prefer unit tests over E2E for new features

## Personal Workflows
- When I say "quick deploy", I mean: build, test, push to staging
- When I say "full review", I mean: /review, /security-check, /commit
```

### The Feedback Loop

The most powerful pattern for improving Claude's behavior:

1. Claude makes a mistake
2. You fix the mistake
3. You tell Claude: "Update CLAUDE.md so you don't make that mistake again"
4. Claude adds a rule
5. Mistake rates actually drop over time

Every mistake is a missing rule. Don't just fix bugs — fix the rules that allowed the bug. The file is checked into git, so the whole team benefits from every lesson learned.

---

## Part 7: Testing

### Vitest for Unit Tests

Unit and integration tests use Vitest. Files go in `tests/unit/` and `tests/integration/`.

```bash
pnpm test:unit          # Run once
pnpm test:unit:watch    # Watch mode
pnpm test:coverage      # With coverage report
```

### Playwright for E2E Tests

End-to-end tests use Playwright. Files go in `tests/e2e/`.

```bash
pnpm test:e2e           # Kills test ports → spawns servers → runs tests
pnpm test:e2e:headed    # With visible browser
pnpm test:e2e:ui        # With Playwright UI mode
pnpm test:e2e:chromium  # Chromium only (fast)
pnpm test:e2e:report    # Open last HTML report
```

### The 3-Assertion Minimum Rule

Every E2E test must verify at least three things:

```typescript
// CORRECT — 3 explicit assertions
await expect(page).toHaveURL('/dashboard');                    // 1. URL
await expect(page.locator('h1')).toBeVisible();               // 2. Element visible
await expect(page.locator('[data-testid="user"]'))
  .toContainText('test@example.com');                         // 3. Data correct

// WRONG — passes even if the page is broken
await page.goto('/dashboard');
// no assertions!
```

**A test is NOT finished until it has:**
- At least one URL assertion (`toHaveURL`)
- At least one element visibility assertion (`toBeVisible`)
- At least one content/data assertion (`toContainText`, `toHaveValue`)
- Error case coverage

### Test Ports and Why They Matter

Tests run on separate ports from development:

| Service | Dev Port | Test Port |
|---------|----------|-----------|
| Website | 3000 | 4000 |
| API | 3001 | 4010 |
| Dashboard | 3002 | 4020 |

This means you can run your dev server and tests simultaneously without conflicts. The `playwright.config.ts` is pre-wired to spawn test servers automatically.

```bash
pnpm test:kill-ports    # Kill stale processes on test ports
```

### Using `/create-e2e` and `/test-plan`

- `/create-e2e <feature>` — Generates a complete E2E test by reading your source code and identifying what to verify
- `/test-plan` — Creates a structured test plan before you write any tests

---

## Part 8: Deployment

### Docker Multi-Stage Builds

The starter kit's `/optimize-docker` command audits your Dockerfile against 12 best practices. A typical optimized Dockerfile:

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

# Stage 2: Production
FROM node:20-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 appuser
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### The Docker Push Gate

When enabled (`docker_test_before_push = true` in `claude-mastery-project.conf`), **no** `docker push` is allowed until the image passes local verification:

1. Build the image
2. Run the container
3. Wait 5 seconds
4. Verify it's still running (didn't crash)
5. Health endpoint returns 200
6. No fatal errors in logs
7. Clean up test container
8. **Only then** push

### Pre-Deployment Checklist

Before deploying any website:

1. **Rybbit Analytics** — Is `NEXT_PUBLIC_RYBBIT_SITE_ID` set with a site-specific ID?
2. **Secrets** — No API keys, passwords, or tokens in the codebase?
3. **Tests** — All tests passing?
4. **TypeScript** — `pnpm typecheck` passes with zero errors?
5. **Docker** — Image tested locally? (if using Docker push gate)
6. **Branch** — On a feature branch, not main?

---

## Part 9: Troubleshooting

### Hook Issues

**Hooks not firing at all**
- Check `.claude/settings.json` is valid JSON: `python3 -m json.tool .claude/settings.json`
- Verify hook files exist and have correct paths: `ls -la .claude/hooks/`
- Restart Claude Code session — hooks are loaded at session start
- Check the `matcher` field matches the tool name exactly

**Hook blocks unexpectedly**
- Read the error message — it tells you exactly why it blocked
- For `check-branch.sh`: set `auto_branch = false` in `claude-mastery-project.conf`
- For `check-rybbit.sh`: set `analytics = none` in conf, or add the Rybbit site ID
- For `block-secrets.py`: you're trying to access a sensitive file — use `/setup` instead

**Hook doesn't block when it should**
- Test manually: `echo '{"tool_input":{"command":"git commit"}}' | bash .claude/hooks/check-branch.sh; echo "Exit: $?"`
- Check the matcher — `Bash` only matches Bash tool calls, not Read/Write

### Port Conflicts

**"Port already in use" error**

```bash
# Find what's using the port
lsof -i :3000

# Kill it
kill -9 <PID>

# Or kill all test ports at once
pnpm test:kill-ports
```

**Dev server starts but tests fail with connection refused**
- Tests use different ports (4000/4010/4020). Check `playwright.config.ts`
- Run `pnpm test:kill-ports` to clear stale test processes

### TypeScript Errors

**"Cannot find module" after moving files**
- Check your import paths — did you update all references?
- Run `pnpm typecheck` to find all broken imports
- Check `tsconfig.json` path mappings

**"Type 'any' is not assignable"**
- This is the starter kit working as intended — `any` is banned
- Add proper type annotations or create a type in `src/types/`

**TypeScript compiles but runtime errors**
- Check for type assertions (`as`) that might be hiding mismatches
- Verify your `tsconfig.json` has `strict: true`

### Database Connection Issues

**"MongoServerSelectionError: connection timed out"**
- Check `MONGODB_URI` in `.env` — is the connection string correct?
- Whitelist your IP in MongoDB Atlas Network Access
- Try connecting with `mongosh` to verify the URI works

**"Too many open connections"**
- You're probably creating `new MongoClient()` outside the wrapper — don't
- Always use `import { queryOne, insertOne } from '@/core/db/index.js'`
- Check for hot-reload connection leaks — the wrapper handles this with `globalThis`

**Connection works locally but fails in Docker**
- The container can't reach `localhost` — use the actual MongoDB Atlas URI
- Check if `MONGODB_URI` is being passed to the container via env vars

### Git / Branch Issues

**"BLOCKED: You're on main"**
- This is the auto-branch hook working correctly
- **Prevention:** ALWAYS run `git branch --show-current` at the START of any task, before editing files. If on main, branch immediately: `git checkout -b feat/<task-name>`
- **If already blocked:** Create the branch now: `git checkout -b feat/my-feature` — your staged changes carry over, then commit
- Or disable with `auto_branch = false` in `claude-mastery-project.conf`

**Accidentally committed to main**
- If not pushed: `git reset HEAD~1` to undo the commit (keeps changes)
- If pushed: create a revert commit

**Merge conflicts after using /worktree**
- Each worktree is isolated — merge the branch normally
- `git merge task/add-auth` from main

### WSL Gotchas (Windows)

**Extremely slow file operations**
- Your project is probably on `/mnt/c/` — move it to `~/projects/`
- Check: `pwd` should show `/home/you/projects/...`, NOT `/mnt/c/Users/...`

**Playwright tests failing in WSL**
- Install browser dependencies: `npx playwright install --with-deps`
- Make sure you're running VS Code in WSL mode (green icon bottom-left)

**Hot reload not working**
- File watching doesn't work across the Windows/Linux boundary
- Move project to WSL filesystem: `~/projects/`

### pnpm / npm Issues

**"pnpm: command not found"**
- Install: `npm install -g pnpm`
- Or use corepack: `corepack enable`

**"ERR_PNPM_LOCKFILE_MISSING"**
- Run `pnpm install` to generate the lockfile
- If converting from npm: delete `package-lock.json`, run `pnpm import` then `pnpm install`

### E2E Test Issues

**Tests pass locally but fail in CI**
- Different browser versions — pin in `playwright.config.ts`
- Timeouts too short — increase in the config
- Flaky selectors — use `data-testid` attributes

**"Target closed" or "Frame detached" errors**
- Page navigated before assertion completed
- Add `await page.waitForURL(...)` before assertions

**Tests hanging**
- Kill stale processes: `pnpm test:kill-ports`
- Check if `webServer` in Playwright config is spawning correctly

---

## Part 10: FAQ

### General

**Q: Do I need to install all the MCP servers?**
A: No. MCP servers are optional. The starter kit works fully without any MCP servers. Install the ones that match your workflow — Context7 for up-to-date docs, Playwright for browser testing, ClassMCP for CSS projects.

**Q: Can I use this with JavaScript instead of TypeScript?**
A: Yes. Use `/new-project my-app clean` to get zero coding opinions — including no TypeScript enforcement. The `default` profile enforces TypeScript because it's a best practice for AI-assisted development, but `clean` mode lets you choose.

**Q: Does this work with monorepos?**
A: The starter kit is designed for single-project repositories. For monorepos, you could use `/convert-project-to-starter-kit` on individual packages, or customize the template to work with your monorepo structure.

**Q: Can I use npm or yarn instead of pnpm?**
A: Yes. The `default` profile uses pnpm, but you can specify any package manager during `/new-project` setup or change it in `claude-mastery-project.conf`.

### Commands & Hooks

**Q: What happens if a hook blocks something I need to do?**
A: Read the error message — it explains why. If you genuinely need to bypass it, edit `.claude/settings.json` to temporarily remove the hook, or change the relevant config setting (e.g., `auto_branch = false`).

**Q: Can I add my own slash commands?**
A: Yes. Create a `.md` file in `.claude/commands/`. The filename becomes the command name. Add a YAML frontmatter block with `description` and `allowed-tools`. See existing commands for examples.

**Q: Why does `/review` sometimes miss issues?**
A: `/review` is a structured prompt, not a linter. For comprehensive analysis, use it together with `/security-check` and the lint-on-save hook. RuleCatch provides automated monitoring across all sessions.

**Q: How do I update the starter kit in an existing project?**
A: Run `/update-project` to pull the latest commands, hooks, skills, and rules into a registered project. It shows a diff report before applying and preserves your custom files. For projects not yet using the starter kit, use `/convert-project-to-starter-kit` first.

### Database

**Q: Can I use Prisma or Mongoose?**
A: The starter kit recommends the native MongoDB driver through the wrapper for AI-assisted development (simpler mental model, fewer abstractions). But for `clean` profile projects, you can use any ORM or ODM you prefer.

**Q: What if I need multiple databases?**
A: The wrapper supports multiple connections via different URIs. Call `connect()` with different URIs and labels. Each gets its own pool.

**Q: How do I switch from MongoDB to PostgreSQL?**
A: Use the SQL wrapper at `src/core/db/sql.ts` instead. Set `DATABASE_URL=postgresql://...` in `.env`. The SQL wrapper has the same patterns (queryOne, queryMany, insertOne, withTransaction).

### Testing

**Q: Why 3 assertions minimum?**
A: A test with one assertion (like checking the URL) can pass even if the page is completely broken. Three assertions verify the URL is correct, the expected content is visible, and the data is accurate. This catches real bugs, not just "the page loaded."

**Q: Do I need E2E tests for every feature?**
A: The `check-e2e.sh` hook only blocks push to main if there are zero E2E tests. You don't need 100% E2E coverage — focus on critical user flows (login, checkout, data submission).

**Q: How do I debug a failing E2E test?**
A: Run `pnpm test:e2e:headed` to see the browser, or `pnpm test:e2e:ui` for Playwright's debugging UI. Check `pnpm test:e2e:report` for the last test report with screenshots and traces.

### Deployment

**Q: Is the Docker push gate mandatory?**
A: No, it's disabled by default. Enable with `docker_test_before_push = true` in `claude-mastery-project.conf`. Recommended for production workflows.

**Q: Why does the kit check for Rybbit before deploying?**
A: The `check-rybbit.sh` hook only activates if `analytics = rybbit` is set in your project profile. If you don't use Rybbit, set `analytics = none` or use the `clean` profile. The check prevents deploying without analytics tracking.

**Q: Can I deploy to platforms other than Dokploy?**
A: Yes. The kit supports Dokploy, Vercel, and static hosting (GitHub Pages, Netlify). Specify during `/new-project` or change `hosting` in your profile.

### RuleCatch

**Q: Is RuleCatch required?**
A: No. RuleCatch is completely optional. The `check-rulecatch.sh` hook skips silently if RuleCatch isn't installed. The free monitor mode (`pnpm ai:monitor`) works without any API key. The full experience (dashboards, violation tracking, alerts) requires a RuleCatch.AI account.

**Q: What does the free monitor show?**
A: Every tool call Claude makes (Read, Write, Edit, Bash), token usage per turn, cost per session, and which files are being accessed — all updating live in a separate terminal.

---

*This guide is part of the [Claude Code Starter Kit](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit) by [TheDecipherist](https://thedecipherist.com).*
