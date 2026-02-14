# Claude Code Starter Kit

[![CI](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit/actions/workflows/ci.yml)

> ## [View the Full Interactive Guide →](https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/)
>
> The GitHub Pages site has the complete documentation with syntax highlighting, navigation, and visual examples.

> The definitive starting point for Claude Code projects.
> Based on [Claude Code Mastery Guides V1-V5](https://github.com/TheDecipherist/claude-code-mastery) by TheDecipherist.

---

## What Is This?

This is a **scaffold template**, not a runnable application. It provides the infrastructure (commands, hooks, skills, agents, documentation templates) that makes Claude Code dramatically more effective. You use it to **create** projects, not run it directly.

### Two Ways to Use It

**A. Scaffold a new project (most common):**
```bash
/new-project my-app clean    # or: /new-project my-app default
cd ~/projects/my-app
/setup
```
This creates a new project directory with all the Claude Code tooling pre-configured. Run `/quickstart` for a guided walkthrough.

**B. Customize the template itself:**
Clone this repo and modify the commands, hooks, skills, and rules to match your team's standards. Then use your customized version as the source for `/new-project`.

> **What NOT to do:** Don't clone this repo and run `pnpm dev` expecting a working app. This is the *template* that creates apps — it's not an app itself. If you're looking to build something, start with option A above.

## Learning Path

Progress through these phases at your own pace. Each builds on the previous one.

```
Phase 1                Phase 2              Phase 3              Phase 4              Phase 5
INITIAL SETUP          DAILY WORKFLOW       DOCS & TESTING       DEPLOYMENT           ADVANCED
(5 minutes)

/install-global   -->  /review         -->  /diagram all    -->  /optimize-docker -->  /refactor
/new-project           /commit              /test-plan           /security-check       /what-is-my-ai-doing
cd my-app              /progress            /create-e2e          deploy                /worktree
/setup                                                                                 custom rules
```

### First 5 Minutes

```bash
/install-global                    # One-time: install global Claude config
/new-project my-app clean          # Scaffold a project (or: default for full stack)
cd ~/projects/my-app               # Enter your new project
/setup                             # Configure .env interactively
pnpm install && pnpm dev           # Start building
```

Use `/help` to see all 20 commands at any time.

## See It In Action

<!-- Record with: asciinema rec demo.cast && agg demo.cast docs/demo.gif -->
![Starter Kit Demo](docs/demo.gif)

*Clone → `/setup` → `/diagram all` → hooks firing on file edit → `/review` catching issues*

<!-- Capture /progress output as a screenshot -->
![Slash Commands](docs/commands-preview.png)

> **Screenshots needed:** See `docs/screenshots/README.md` for the 8 screenshots and 3 animated recordings that complete this section.

## What's Included

Everything you need to start a Claude Code project the right way — security, automation, documentation, and testing all pre-configured.

- **CLAUDE.md** — Battle-tested project instructions with 11 numbered critical rules for security, TypeScript, database wrappers, testing, and deployment
- **Global CLAUDE.md** — Security gatekeeper for all projects. Never publish secrets, never commit .env files, standardized scaffolding rules
- **20 Slash Commands** — `/help`, `/quickstart`, `/install-global`, `/setup`, `/diagram`, `/review`, `/commit`, `/progress`, `/test-plan`, `/architecture`, `/new-project`, `/security-check`, `/optimize-docker`, `/create-e2e`, `/create-api`, `/worktree`, `/what-is-my-ai-doing`, `/refactor`, `/set-clean-as-default`, `/reset-to-defaults`
- **9 Hooks** — Deterministic enforcement that always runs. Block secrets, lint on save, verify no credentials, branch protection, port conflicts, Rybbit pre-deploy gate, E2E test gate, env sync warnings, and RuleCatch monitoring (optional — skips silently if not installed)
- **Skills** — Context-aware templates: systematic code review checklist and full microservice scaffolding
- **Custom Agents** — Read-only code reviewer for security audits. Test writer that creates tests with explicit assertions
- **Documentation Templates** — Pre-structured ARCHITECTURE.md, INFRASTRUCTURE.md, and DECISIONS.md templates
- **Testing Templates** — Master test checklist, issue tracking log, and a singleton database wrapper that prevents connection pool explosion
- **Live AI Monitor** — See every tool call, token, cost, and violation in real-time with `/what-is-my-ai-doing`. Zero token overhead (requires [RuleCatch](https://rulecatch.ai) — optional)

---

## Quick Start

### 1. Clone and Customize

```bash
# Clone the starter kit
git clone https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit my-project
cd my-project

# Remove git history and start fresh
rm -rf .git
git init

# Copy your .env
cp .env.example .env
```

### 2. Set Up Global Config (One Time)

```bash
# Run the install command — smart merges into existing config
/install-global
```

This installs global CLAUDE.md rules, settings.json hooks, and enforcement scripts (`block-secrets.py`, `verify-no-secrets.sh`, `check-rulecatch.sh`) into `~/.claude/`. If you already have a global config, it merges without overwriting.

<details>
<summary>Manual setup (if you prefer)</summary>

```bash
cp global-claude-md/CLAUDE.md ~/.claude/CLAUDE.md
cp global-claude-md/settings.json ~/.claude/settings.json
mkdir -p ~/.claude/hooks
cp .claude/hooks/block-secrets.py ~/.claude/hooks/
cp .claude/hooks/verify-no-secrets.sh ~/.claude/hooks/
cp .claude/hooks/check-rulecatch.sh ~/.claude/hooks/
```

</details>

### 3. Customize for Your Project

1. Run `/setup` — Interactive .env configuration (database, GitHub, Docker, analytics)
2. Edit `CLAUDE.md` — Update port assignments, add your specific rules
3. Run `/diagram all` — Auto-generate architecture, API, database, and infrastructure diagrams
4. Edit `CLAUDE.local.md` — Add your personal preferences

The database wrapper (`src/core/db/index.ts`) works out of the box — just set `DATABASE_URL` in your `.env` and it connects to MongoDB automatically. All query inputs are auto-sanitized against NoSQL injection (configurable via `DB_SANITIZE_INPUTS=false` or `sanitize = false` in conf).

### 4. Start Building

```bash
claude
```

That's it. Claude Code now has battle-tested rules, deterministic hooks, slash commands, and documentation templates all ready to go.

---

## Troubleshooting

### Hooks Not Firing

- Verify `.claude/settings.json` is valid JSON: `python3 -m json.tool .claude/settings.json`
- Check that hook file paths are correct and executable: `ls -la .claude/hooks/`
- Restart your Claude Code session — hooks are loaded at session start

### `pnpm dev` Fails or Does Nothing

This is a scaffold template, not a runnable app. Use `/new-project my-app` to create a project first, then run `pnpm dev` inside that project.

### Database Connection Errors

- Run `/setup` to configure your `.env` with a valid connection string
- Check that `MONGODB_URI` (or `DATABASE_URL`) is set in `.env`
- Verify your IP is whitelisted in MongoDB Atlas Network Access

### `/install-global` Reports Conflicts

This is normal. The command uses smart merge — it keeps your existing sections and only adds what's missing. If sections overlap, it preserves yours. Check the report output for details on what was added vs skipped.

### Port Already in Use

```bash
# Find what's using the port
lsof -i :3000

# Kill it
kill -9 <PID>

# Or kill all test ports at once
pnpm test:kill-ports
```

### E2E Tests Timing Out

- Kill stale processes on test ports: `pnpm test:kill-ports`
- Run headed to see what's happening: `pnpm test:e2e:headed`
- Check that `playwright.config.ts` has correct `webServer` commands and ports

### RuleCatch Not Monitoring

> **RuleCatch is optional.** The starter kit works fully without it — the hook skips silently if RuleCatch isn't installed. Only set this up if you want AI session analytics and rule monitoring.

- Install the AI-Pooler: `npx @rulecatch/ai-pooler init --api-key=YOUR_KEY --region=us`
- Verify your API key is set: check `RULECATCH_API_KEY` in `.env`
- Run `pnpm ai:monitor` in a separate terminal to see live output

---

## Project Structure

```
project/
├── CLAUDE.md                    # Project instructions (customize this!)
├── CLAUDE.local.md              # Personal overrides (gitignored)
├── .claude/
│   ├── settings.json            # Hooks configuration
│   ├── commands/
│   │   ├── help.md              # /help — list all commands, skills, and agents
│   │   ├── quickstart.md        # /quickstart — interactive first-run walkthrough
│   │   ├── review.md            # /review — code review
│   │   ├── commit.md            # /commit — smart commit
│   │   ├── progress.md          # /progress — project status
│   │   ├── test-plan.md         # /test-plan — generate test plan
│   │   ├── architecture.md      # /architecture — show system design
│   │   ├── new-project.md       # /new-project — scaffold new project
│   │   ├── security-check.md    # /security-check — scan for secrets
│   │   ├── optimize-docker.md   # /optimize-docker — Docker best practices
│   │   ├── create-e2e.md        # /create-e2e — generate E2E tests
│   │   ├── create-api.md        # /create-api — scaffold API endpoints
│   │   ├── worktree.md          # /worktree — isolated task branches
│   │   ├── what-is-my-ai-doing.md # /what-is-my-ai-doing — live AI monitor
│   │   ├── setup.md             # /setup — interactive .env configuration
│   │   ├── refactor.md          # /refactor — audit + refactor against all rules
│   │   ├── install-global.md    # /install-global — merge global config into ~/.claude/
│   │   ├── diagram.md           # /diagram — generate diagrams from actual code
│   │   ├── set-clean-as-default.md # /set-clean-as-default — clean as default profile
│   │   └── reset-to-defaults.md # /reset-to-defaults — reset to default profile
│   ├── skills/
│   │   ├── code-review/SKILL.md # Triggered code review checklist
│   │   └── create-service/SKILL.md # Service scaffolding template
│   ├── agents/
│   │   ├── code-reviewer.md     # Read-only review subagent
│   │   └── test-writer.md       # Test writing subagent
│   └── hooks/
│       ├── block-secrets.py     # PreToolUse: block sensitive files
│       ├── check-rybbit.sh      # PreToolUse: block deploy without Rybbit
│       ├── check-branch.sh      # PreToolUse: block commits on main
│       ├── check-ports.sh       # PreToolUse: block if port in use
│       ├── check-e2e.sh         # PreToolUse: block push without E2E tests
│       ├── lint-on-save.sh      # PostToolUse: lint after writes
│       ├── verify-no-secrets.sh # Stop: check for secrets
│       ├── check-rulecatch.sh   # Stop: report RuleCatch violations
│       └── check-env-sync.sh    # Stop: warn on .env/.env.example drift
├── project-docs/
│   ├── ARCHITECTURE.md          # System overview (authoritative)
│   ├── INFRASTRUCTURE.md        # Deployment details
│   └── DECISIONS.md             # Architectural decision records
├── docs/                        # GitHub Pages site
├── src/
│   ├── core/db/index.ts         # Centralized database wrapper
│   ├── handlers/                # Business logic
│   ├── adapters/                # External service wrappers
│   └── types/                   # Shared TypeScript types
├── scripts/
│   ├── db-query.ts              # Test Query Master — dev/test query index
│   ├── queries/                 # Individual dev/test query files
│   ├── build-content.ts         # Markdown → HTML article builder
│   └── content.config.json      # Article registry (SEO metadata)
├── content/                     # Markdown source files for articles
├── tests/
│   ├── CHECKLIST.md             # Master test tracker
│   ├── ISSUES_FOUND.md          # User-guided testing log
│   ├── e2e/                     # Playwright E2E tests
│   ├── unit/                    # Vitest unit tests
│   └── integration/             # Integration tests
├── global-claude-md/            # Copy to ~/.claude/ (one-time setup)
│   ├── CLAUDE.md                # Global security gatekeeper
│   └── settings.json            # Global hooks config
├── .env.example
├── .gitignore
├── .dockerignore
├── package.json                 # All npm scripts (dev, test, db:query, etc.)
├── claude-mastery-project.conf  # /new-project profiles + global root_dir
├── playwright.config.ts         # E2E test config (test ports, webServer)
├── vitest.config.ts             # Unit/integration test config
├── tsconfig.json
└── README.md
```

---

## Key Concepts

### Defense in Depth (V3)

Three layers of protection working together:
1. **CLAUDE.md rules** — Behavioral suggestions (weakest)
2. **Hooks** — Guaranteed to run, stronger than rules, but not bulletproof
3. **Git safety** — .gitignore as last line of defense (strongest)

### One Task, One Chat (V1-V3)

Research shows **39% performance degradation** when mixing topics, and a 2% misalignment early can cause **40% failure** by end of conversation. Use `/clear` between unrelated tasks.

### Quality Gates (V1/V2)

No file > 300 lines. No function > 50 lines. All tests pass. TypeScript compiles clean. These prevent the most common code quality issues in AI-assisted development.

### MCP Tool Search (V4)

With 10+ MCP servers, tool descriptions consume 50-70% of context. Tool Search lazy-loads on demand, saving **85% of context**.

### Plan First, Code Second (V5)

For non-trivial tasks, **always start in plan mode**. Don't let Claude write code until you've agreed on the plan. Bad plan = bad code.

Every step MUST have a unique name: `Step 3 (Auth System)`. When you change a step, Claude must **replace** it — not append. Claude forgets this. If the plan contradicts itself, tell Claude: "Rewrite the full plan."

### CLAUDE.md Is Team Memory

Every time Claude makes a mistake, **add a rule** to prevent it from happening again. Tell Claude: "Update CLAUDE.md so this doesn't happen again." Mistake rates actually drop over time. The file is checked into git — the whole team benefits from every lesson.

### Never Work on Main

**Auto-branch is on by default.** Every command that modifies code automatically creates a feature branch when it detects you're on main. Zero friction — you never accidentally break main. Delete the branch if Claude screws up. Use `/worktree` for parallel sessions in separate directories. Set `auto_branch = false` in `claude-mastery-project.conf` to disable.

### Every Command Enforces the Rules

Every slash command and skill has two built-in enforcement steps: **Auto-Branch** (automatically creates a feature branch when on main — no manual step) and **RuleCatch Report** (checks for violations after completion). The rules aren't just documented — they're enforced at every touchpoint.

### TypeScript Is Non-Negotiable (V5)

Types are specs that tell Claude what functions accept and return. Without types, Claude guesses — and guesses become runtime errors.

### Windows? Use WSL Mode

Most Windows developers don't know VS Code can run its entire backend inside WSL 2. HMR becomes **5-10x faster**, Playwright tests run significantly faster, and file watching actually works. Your project must live on the WSL filesystem (`~/projects/`), NOT `/mnt/c/`. Run `/setup` to auto-detect.

---

## CLAUDE.md — The Rulebook

The `CLAUDE.md` file is where you define the rules Claude Code must follow. These aren't suggestions — they're the operating manual for every session. Here are the critical rules included in this starter kit:

### Rule 0: NEVER Publish Sensitive Data

- NEVER commit passwords, API keys, tokens, or secrets to git/npm/docker
- NEVER commit `.env` files — ALWAYS verify `.env` is in `.gitignore`
- Before ANY commit: verify no secrets are included

### Rule 1: TypeScript Always

- ALWAYS use TypeScript for new files (strict mode)
- NEVER use `any` unless absolutely necessary and documented why
- When editing JavaScript files, convert to TypeScript first
- Types are specs — they tell you what functions accept and return

### Rule 2: API Versioning

```
CORRECT: /api/v1/users
WRONG:   /api/users
```

Every API endpoint MUST use `/api/v1/` prefix. No exceptions.

### Rule 3: Database Access — Wrapper Only

- NEVER create direct database connections outside `src/core/db/`
- ALWAYS use the centralized database wrapper
- All inputs auto-sanitized against NoSQL injection (disable with `DB_SANITIZE_INPUTS=false`)
- One connection pool. One place to change. One place to mock.

### Rule 4: Testing — Explicit Success Criteria

```typescript
// CORRECT — explicit success criteria
await expect(page).toHaveURL('/dashboard');
await expect(page.locator('h1')).toContainText('Welcome');

// WRONG — passes even if broken
await page.goto('/dashboard');
// no assertion!
```

### Rule 5: NEVER Hardcode Credentials

ALWAYS use environment variables. NEVER put API keys, passwords, or tokens directly in code. NEVER hardcode connection strings — use `DATABASE_URL` from `.env`.

### Rule 6: ALWAYS Ask Before Deploying

NEVER auto-deploy, even if the fix seems simple. NEVER assume approval — wait for explicit confirmation.

### Rule 7: Quality Gates

- No file > 300 lines (split if larger)
- No function > 50 lines (extract helper functions)
- All tests must pass before committing
- TypeScript must compile with no errors (`tsc --noEmit`)

### Rule 8: Parallelize Independent Awaits

When multiple `await` calls are independent, ALWAYS use `Promise.all`. Before writing sequential awaits, evaluate: does the second call need the first call's result?

```typescript
// CORRECT — independent operations run in parallel
const [users, products, orders] = await Promise.all([
  getUsers(),
  getProducts(),
  getOrders(),
]);

// WRONG — sequential when they don't depend on each other
const users = await getUsers();
const products = await getProducts();  // waits unnecessarily
const orders = await getOrders();      // waits unnecessarily
```

### Rule 9: Git Workflow — Auto-Branch on Main

- **Auto-branch is ON by default** — commands auto-create feature branches when on main
- Branch names match the command: `refactor/<file>`, `test/<feature>`, `feat/<scope>`
- Use `/worktree` for parallel sessions in separate directories
- Review the full diff (`git diff main...HEAD`) before merging
- If Claude screws up on a branch — delete it. Main was never touched.
- Disable with `auto_branch = false` in `claude-mastery-project.conf`

### Rule 10: Docker Push Gate — Local Test First

**Disabled by default.** When enabled, NO `docker push` is allowed until the image passes local verification:

1. Build the image
2. Run the container locally
3. Verify it doesn't crash (still running after 5s)
4. Health endpoint returns 200
5. No fatal errors in logs
6. Clean up, **then** push

Enable with `docker_test_before_push = true` in `claude-mastery-project.conf`. Applies to all commands that push Docker images.

### When Something Seems Wrong

The CLAUDE.md also includes a "Check Before Assuming" pattern:

- **Missing UI element?** → Check feature gates BEFORE assuming bug
- **Empty data?** → Check if services are running BEFORE assuming broken
- **404 error?** → Check service separation BEFORE adding endpoint
- **Auth failing?** → Check which auth system BEFORE debugging
- **Test failing?** → Read the error message fully BEFORE changing code

### Fixed Service Ports

| Service | Dev Port | Test Port |
|---------|----------|-----------|
| Website | 3000 | 4000 |
| API | 3001 | 4010 |
| Dashboard | 3002 | 4020 |

---

## Hooks — Stronger Than Rules

CLAUDE.md rules are suggestions. Hooks are **stronger** — they're guaranteed to **run** as shell/python scripts at specific lifecycle points. But hooks are not bulletproof: Claude may still work around their output. They're a significant upgrade over CLAUDE.md rules alone, but not an absolute guarantee.

### PreToolUse: `block-secrets.py`

Runs **before** Claude reads or edits any file. Blocks access to sensitive files like `.env`, `credentials.json`, SSH keys, and `.npmrc`.

```python
# Files that should NEVER be read or edited by Claude
SENSITIVE_FILENAMES = {
    '.env', '.env.local', '.env.production',
    'secrets.json', 'id_rsa', 'id_ed25519',
    '.npmrc', 'credentials.json',
    'service-account.json',
}

# Exit code 2 = block operation and tell Claude why
if path.name in SENSITIVE_FILENAMES:
    print(f"BLOCKED: Access to '{file_path}' denied.", file=sys.stderr)
    sys.exit(2)
```

### PreToolUse: `check-rybbit.sh`

Runs **before** any deployment command (`docker push`, `vercel deploy`, `dokploy`). If the project has `analytics = rybbit` in `claude-mastery-project.conf`, verifies that `NEXT_PUBLIC_RYBBIT_SITE_ID` is set in `.env` with a real value. Blocks with a link to https://app.rybbit.io if missing. Skips projects that don't use Rybbit.

### PreToolUse: `check-branch.sh`

Runs **before** any `git commit`. If auto-branch is enabled (default: true) and you're on main/master, blocks the commit and tells Claude to create a feature branch first. Respects the `auto_branch` setting in `claude-mastery-project.conf`.

### PreToolUse: `check-ports.sh`

Runs **before** dev server commands. Detects the target port from `-p`, `--port`, `PORT=`, or known script names (`dev:website`→3000, `dev:api`→3001, etc.). If the port is already in use, blocks and shows the PID + kill command.

### PreToolUse: `check-e2e.sh`

Runs **before** `git push` to main/master. Checks for real `.spec.ts` or `.test.ts` files in `tests/e2e/` (excluding the example template). Blocks push if no E2E tests exist.

### PostToolUse: `lint-on-save.sh`

Runs **after** Claude writes or edits a file. Automatically checks TypeScript compilation, ESLint, or Python linting depending on file extension.

```bash
case "$EXTENSION" in
    ts|tsx)
        npx tsc --noEmit --pretty "$FILE_PATH" 2>&1 | head -20
        ;;
    js|jsx)
        npx eslint "$FILE_PATH" 2>&1 | head -20
        ;;
    py)
        ruff check "$FILE_PATH" 2>&1 | head -20
        ;;
esac
```

### Stop: `verify-no-secrets.sh`

Runs when Claude **finishes a turn**. Scans all staged git files for accidentally committed secrets using regex patterns for API keys, AWS credentials, and credential URLs.

```bash
# Check staged file contents for common secret patterns
if grep -qEi '(api[_-]?key|secret[_-]?key|password|token)\s*[:=]\s*["\x27][A-Za-z0-9+/=_-]{16,}' "$file"; then
    VIOLATIONS="${VIOLATIONS}\n  - POSSIBLE SECRET in $file"
fi
# Check for AWS keys
if grep -qE 'AKIA[0-9A-Z]{16}' "$file"; then
    VIOLATIONS="${VIOLATIONS}\n  - AWS ACCESS KEY in $file"
fi
```

### Stop: `check-rulecatch.sh`

Runs when Claude **finishes a turn**. Checks RuleCatch for any rule violations detected during the session. Skips silently if RuleCatch isn't installed — zero overhead for users who haven't set it up yet.

### Stop: `check-env-sync.sh`

Runs when Claude **finishes a turn**. Compares key names (never values) between `.env` and `.env.example`. If `.env` has keys that `.env.example` doesn't document, prints a warning so other developers know those variables exist. Informational only — never blocks.

### Hook Configuration

Hooks are wired up in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write",
        "hooks": [{ "type": "command", "command": "python3 .claude/hooks/block-secrets.py" }]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/check-rybbit.sh" },
          { "type": "command", "command": "bash .claude/hooks/check-branch.sh" },
          { "type": "command", "command": "bash .claude/hooks/check-ports.sh" },
          { "type": "command", "command": "bash .claude/hooks/check-e2e.sh" }
        ]
      }
    ],
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{ "type": "command", "command": "bash .claude/hooks/lint-on-save.sh" }]
    }],
    "Stop": [{
      "hooks": [
        { "type": "command", "command": "bash .claude/hooks/verify-no-secrets.sh" },
        { "type": "command", "command": "bash .claude/hooks/check-rulecatch.sh" },
        { "type": "command", "command": "bash .claude/hooks/check-env-sync.sh" }
      ]
    }]
  }
}
```

---

## Slash Commands — On-Demand Tools

Invoke these with `/command` in any Claude Code session. Each command is a markdown file in `.claude/commands/` that gives Claude specific instructions and tool permissions.

### `/help`

Lists every command, skill, and agent in the starter kit, grouped by category: Getting Started, Project Scaffold, Code Quality, Development, Infrastructure, and Monitoring. Also shows skill triggers and agent descriptions. Run `/help` anytime to see what's available.

### `/quickstart`

Interactive first-run walkthrough for new users. Checks if global config is installed, asks for a project name and profile preference, then walks you through the first 5 minutes: scaffolding, setup, first dev server, first review, first commit. Designed for someone who just cloned the starter kit and doesn't know where to start.

### `/diagram`

Scans your actual code and generates ASCII diagrams automatically:

- `/diagram architecture` — services, connections, data flow (scans src/, routes, adapters)
- `/diagram api` — all API endpoints grouped by resource with handler locations
- `/diagram database` — collections, indexes, relationships (scans queries + types)
- `/diagram infrastructure` — deployment topology, regions, containers (scans .env + Docker)
- `/diagram all` — generate everything at once

Writes to `project-docs/ARCHITECTURE.md` and `project-docs/INFRASTRUCTURE.md`. Uses ASCII box-drawing — works everywhere, no external tools needed. Add `--update` to write without asking.

### `/install-global`

One-time setup: installs the starter kit's global Claude config into `~/.claude/`.

- **Smart merge** — if you already have a global `CLAUDE.md`, it appends missing sections without overwriting yours
- **settings.json** — merges deny rules and hooks (never removes existing ones)
- **Hooks** — copies `block-secrets.py`, `verify-no-secrets.sh`, and `check-rulecatch.sh` to `~/.claude/hooks/`

Reports exactly what was added, skipped, and merged. Your existing config is never overwritten.

### `/setup`

Interactive project configuration. Walks you through setting up your `.env` with real values:

- **Multi-region** — US + EU with isolated databases, VPS, and Dokploy per region
- **Database** — MongoDB/PostgreSQL per region (`MONGODB_URI_US`, `MONGODB_URI_EU`)
- **Deployment** — Dokploy on Hostinger VPS per region (IP, API key, app ID, webhook token)
- **Docker** — Hub username, image name, region tagging (`:latest` for US, `:eu` for EU)
- **GitHub** — username, SSH vs HTTPS
- **Analytics** — Rybbit site ID
- **RuleCatch** — API key, region
- **Auth** — auto-generates JWT secret

Multi-region writes the **region map** to both `.env` and `CLAUDE.md` so Claude always knows: US containers → US database, EU containers → EU database. Never cross-connects.

Skips variables that already have values. Use `/setup --reset` to re-configure everything. Never displays secrets back to you. Keeps `.env.example` in sync.

### `/what-is-my-ai-doing`

> **Requires [RuleCatch.AI](https://rulecatch.ai).** This command launches the RuleCatch AI-Pooler — if you haven't installed it yet, see the [Monitor Your Rules](#monitor-your-rules-with-rulecatchai-optional) section below.

Launches the RuleCatch AI-Pooler live monitor in a separate terminal:

- Every tool call (Read, Write, Edit, Bash)
- Token usage and cost per turn
- Rule violations as they happen
- Which files are being accessed

```bash
# Run in a separate terminal
npx @rulecatch/ai-pooler@latest monitor -v
```

Zero token overhead — runs completely outside Claude's context. Also available as `pnpm ai:monitor`.

### `/review`

Systematic code review against a 7-point checklist:

1. **Security** — OWASP Top 10, no secrets in code
2. **Types** — No `any`, proper null handling
3. **Error Handling** — No swallowed errors
4. **Performance** — No N+1 queries, no memory leaks
5. **Testing** — New code has explicit assertions
6. **Database** — Using centralized wrapper
7. **API Versioning** — All endpoints use `/api/v1/`

Issues are reported with severity (Critical / Warning / Info), file:line references, and suggested fixes.

### `/commit`

Smart commit with conventional commit format. Reviews staged changes, generates appropriate commit messages using the `type(scope): description` convention (feat, fix, docs, refactor, test, chore, perf). Warns if changes span multiple concerns and suggests splitting.

### `/test-plan`

Generates a structured test plan for any feature with prerequisites, happy path scenarios with specific expected outcomes, error cases and edge cases, pass/fail criteria table, and sign-off tracker.

### `/security-check`

Scans the project for security vulnerabilities: secrets in code, `.gitignore` coverage, sensitive files tracked by git, `.env` handling audit, and dependency vulnerability scan (`npm audit`).

### `/progress`

Checks the actual filesystem state and reports project status — source file counts by type, test coverage, recent git activity, and prioritized next actions.

### `/architecture`

Reads `project-docs/ARCHITECTURE.md` and displays the system overview, data flow diagrams, and service responsibility maps. If docs don't exist, scaffolds them.

### `/worktree`

Creates an isolated git worktree + branch for a task:

```bash
/worktree add-auth          # → task/add-auth branch
/worktree feat/new-dashboard # → uses prefix as-is
```

Each task gets its own branch and its own directory. Main stays untouched. Enables running **multiple Claude sessions in parallel** without conflicts. When done: merge into main (or open a PR), then `git worktree remove`.

### `/optimize-docker`

Audits your Dockerfile against 12 production best practices: multi-stage builds, layer caching, Alpine base images, non-root user, .dockerignore coverage, frozen lockfile, health checks, no secrets in build args, and pinned versions. Generates an optimized Dockerfile with before/after image size comparison.

### `/set-clean-as-default`

Sets `default_profile = clean` in `claude-mastery-project.conf` so `/new-project my-app` uses the `clean` profile automatically — all the AI goodies (commands, hooks, skills, agents), zero coding opinions. You can still override with `/new-project my-app default` or any other profile.

### `/reset-to-defaults`

Resets `default_profile = default` in `claude-mastery-project.conf` so `/new-project my-app` uses the full opinionated stack again (Next.js, MongoDB, Tailwind, Docker, CI, Rybbit, MCP servers).

### `/create-e2e`

Generates a properly structured Playwright E2E test for a feature. Reads the source code, identifies URLs/elements/data to verify, creates the test at `tests/e2e/[name].spec.ts` with happy path, error cases, and edge cases. Verifies the test meets the "done" checklist before finishing.

### `/create-api`

Scaffolds a production-ready API endpoint with full CRUD:

- **Types** — `src/types/<resource>.ts` (document, request, response shapes)
- **Handler** — `src/handlers/<resource>.ts` (business logic, indexes, CRUD)
- **Route** — `src/routes/v1/<resource>.ts` (thin routes, proper HTTP status codes)
- **Tests** — `tests/unit/<resource>.test.ts` (happy path, error cases, edge cases)

Uses the db wrapper with shared pool, auto-sanitized inputs, pagination (max 100), registered indexes, and `/api/v1/` prefix. Pass `--no-mongo` to skip MongoDB integration.

### `/refactor`

Audit + refactor any file against **every rule** in CLAUDE.md:

1. **Branch check** — verifies you're not on main (suggests `/worktree`)
2. **File size** — >300 lines = must split
3. **Function size** — >50 lines = must extract
4. **TypeScript** — no `any`, explicit types, strict mode
5. **Import hygiene** — no barrel imports, proper `import type`
6. **Error handling** — no swallowed errors, proper logging
7. **Database access** — wrapper only (`src/core/db/`)
8. **API routes** — `/api/v1/` prefix
9. **Promise.all** — parallelize independent awaits
10. **Security + dead code** — no secrets, no unused code

Presents a **named-step plan** before making changes. Splits files by type (types → `src/types/`, validation → colocated, helpers → colocated). Updates all imports across the project.

```bash
/refactor src/handlers/users.ts
/refactor src/server.ts --dry-run    # report only, no changes
```

### `/new-project`

Full project scaffolding with profiles:

```bash
/new-project my-app clean
/new-project my-app default
/new-project my-app fullstack next dokploy seo tailwind pnpm
/new-project my-api api fastify dokploy docker multiregion
/new-project my-site static-site
```

**`clean`** — All Claude infrastructure (commands, skills, agents, hooks, project-docs, tests templates) with **zero coding opinions**. No TypeScript enforcement, no port assignments, no database wrapper, no quality gates. Your project, your rules — Claude just works.

**`default`** and other profiles — Full opinionated scaffolding with project type, framework, SSR, hosting (Dokploy/Vercel/static), package manager, database, extras (Tailwind, Prisma, Docker, CI), and MCP servers. Use `claude-mastery-project.conf` to save your preferred stack.

---

## Skills — Triggered Expertise

Skills are context-aware templates that activate automatically when Claude detects relevant keywords in your conversation. Unlike slash commands (which you invoke explicitly with `/command`), skills load themselves when needed.

### What Triggers Skills?

Claude monitors your conversation for specific keywords. When it detects a match, it loads the relevant skill template — giving Claude structured instructions for that specific task. You don't need to do anything special.

| Skill | Trigger Keywords | What It Does |
|-------|-----------------|--------------|
| Code Review | `review`, `audit`, `check code`, `security review` | Loads a systematic 7-point review checklist with severity ratings |
| Create Service | `create service`, `new service`, `scaffold service` | Scaffolds a microservice with server/handlers/adapters pattern |

### How to Activate Skills

**You don't** — just use natural language. Say things like:

- "Review this file for security issues" → Code Review skill activates
- "Audit the authentication module" → Code Review skill activates
- "Create a new payment service" → Create Service skill activates
- "Scaffold a notification service" → Create Service skill activates

### Skills vs Commands

| | Skills | Commands |
|---|--------|---------|
| **How to use** | Automatic — just use natural language | Explicit — type `/command` |
| **When they load** | When Claude detects trigger keywords | When you invoke them |
| **Example** | "Review this code" | `/review` |
| **Best for** | Organic, conversational workflows | Deliberate, specific actions |

Both skills and commands can cover similar ground (e.g., code review). Skills are more natural; commands are more predictable. Use whichever fits your workflow.

### Code Review Skill

**Triggers:** `review`, `audit`, `check code`, `security review`

A systematic review checklist covering security (OWASP, input validation, CORS, rate limiting), TypeScript quality (no `any`, explicit return types, strict mode), error handling (no swallowed errors, user-facing messages), performance (N+1 queries, memory leaks, pagination), and architecture compliance (database wrapper, API versioning, service separation). Each issue is reported with severity, location, fix, and **why it matters**.

### Create Service Skill

**Triggers:** `create service`, `new service`, `scaffold service`

Generates a complete microservice following the server/handlers/adapters separation pattern:

```
┌─────────────────────────────────────────────────────┐
│                    YOUR SERVICE                      │
├─────────────────────────────────────────────────────┤
│  SERVER (server.ts)                                  │
│  → Express/Fastify entry point, defines routes       │
│  → NEVER contains business logic                     │
│                       │                              │
│                       ▼                              │
│  HANDLERS (handlers/)                                │
│  → Business logic lives here                         │
│  → One file per domain                               │
│                       │                              │
│                       ▼                              │
│  ADAPTERS (adapters/)                                │
│  → External service wrappers                         │
│  → Database, APIs, etc.                              │
└─────────────────────────────────────────────────────┘
```

Includes `package.json`, `tsconfig.json`, entry point with error handlers, health check endpoint, and a post-creation verification checklist.

---

## Custom Agents — Specialist Subagents

Agents are specialists that Claude delegates to automatically. They run with restricted tool access so they can't accidentally modify your code when they shouldn't.

### Code Reviewer Agent

**Tools:** Read, Grep, Glob (read-only)

*"You are a senior code reviewer. Your job is to find real problems — not nitpick style."*

**Priority order:**
1. **Security** — secrets in code, injection vulnerabilities, auth bypasses
2. **Correctness** — logic errors, race conditions, null pointer risks
3. **Performance** — N+1 queries, memory leaks, missing indexes
4. **Type Safety** — `any` usage, missing null checks, unsafe casts
5. **Maintainability** — dead code, unclear naming (lowest priority)

If the code is good, it says so — it doesn't invent issues to justify its existence.

### Test Writer Agent

**Tools:** Read, Write, Grep, Glob, Bash

*"You are a testing specialist. You write tests that CATCH BUGS, not tests that just pass."*

**Principles:**
- Every test MUST have explicit assertions — "page loads" is NOT a test
- Test behavior, not implementation details
- Cover happy path, error cases, AND edge cases
- Use realistic test data, not `"test"` / `"asdf"`
- Tests should be independent — no shared mutable state

```typescript
// GOOD — explicit, specific assertions
expect(result.status).toBe(200);
expect(result.body.user.email).toBe('test@example.com');

// BAD — passes even when broken
expect(result).toBeTruthy();  // too vague
```

---

## Database Wrapper — Production MongoDB

The starter kit includes a **production-grade MongoDB wrapper** at `src/core/db/index.ts` using the native driver (no Mongoose, no ODMs). It enforces every best practice that prevents the most common database failures in AI-assisted development.

### The Absolute Rule

**ALL database access goes through `src/core/db/index.ts`. No exceptions.** Never create `new MongoClient()` anywhere else. Never import `mongodb` directly in business logic.

```typescript
// CORRECT — import from the centralized wrapper
import { queryOne, insertOne, updateOne } from '@/core/db/index.js';

// WRONG — NEVER do this
import { MongoClient } from 'mongodb';  // FORBIDDEN outside src/core/db/
```

### Reading Data — Aggregation Only

```typescript
// Single document (automatic $limit: 1)
const user = await queryOne<User>('users', { email });

// Pipeline query
const recent = await queryMany<Order>('orders', [
  { $match: { userId, status: 'active' } },
  { $sort: { createdAt: -1 } },
  { $limit: 20 },
]);

// Join — $limit enforced BEFORE $lookup automatically
const userWithOrders = await queryWithLookup<UserWithOrders>('users', {
  match: { _id: userId },
  lookup: { from: 'orders', localField: '_id', foreignField: 'userId', as: 'orders' },
});
```

### Writing Data — BulkWrite Only

```typescript
// Insert
await insertOne('users', { email, name, createdAt: new Date() });
await insertMany('events', batchOfEvents);

// Update — use $inc for counters (NEVER read-modify-write)
await updateOne<Stats>('stats',
  { date },
  { $inc: { pageViews: 1 } },
  true // upsert
);

// Complex batch (auto-retries E11000 concurrent races)
await bulkOps('sessions', [
  { updateOne: { filter: { sessionId }, update: { $inc: { events: 1 } }, upsert: true } },
]);
```

### Connection Pool Presets

| Preset | Max Pool | Min Pool | Use Case |
|--------|----------|----------|----------|
| `high` | 20 | 2 | APIs, high-traffic services |
| `standard` | 10 | 2 | Default for most services |
| `low` | 5 | 1 | Background workers, cron jobs |

### Additional Features

- **Singleton per URI** — same URI always returns the same client, prevents pool exhaustion
- **Next.js hot-reload safe** — persists connections via `globalThis` during development
- **NoSQL injection sanitization** — automatic on all inputs (configurable)
- **Transaction support** — `withTransaction()` for multi-document atomic operations
- **Change Stream access** — `rawCollection()` for real-time event processing
- **Graceful shutdown** — `gracefulShutdown()` closes all pools on `SIGTERM`, `SIGINT`, `uncaughtException`, and `unhandledRejection` — no zombie connections on crash
- **E11000 auto-retry** — handles concurrent upsert race conditions automatically
- **$limit before $lookup** — `queryWithLookup()` enforces this for join performance
- **Index management** — `registerIndex()` + `ensureIndexes()` at startup

### Test Query Master — `scripts/db-query.ts`

**Every** dev/test database query gets its own file in `scripts/queries/` and is registered in the master index. Production code in `src/` stays clean.

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

Register in `scripts/db-query.ts` and run: `npx tsx scripts/db-query.ts find-expired-sessions`

### Content Builder — `scripts/build-content.ts`

A config-driven Markdown-to-HTML article builder. Write content in `content/` as Markdown, register it in `scripts/content.config.json`, and build fully SEO-ready static HTML pages. Each generated page includes Open Graph, Twitter Cards, Schema.org JSON-LD, syntax highlighting, and optional sidebar TOC.

```bash
pnpm content:build              # Build all published articles
pnpm content:build:id my-post   # Build a single article
pnpm content:list               # List all articles and status
```

---

## Documentation Templates

Pre-structured docs that Claude actually follows. Each template uses the "STOP" pattern — explicit boundaries that prevent Claude from making unauthorized changes.

### ARCHITECTURE.md

`project-docs/ARCHITECTURE.md` — Starts with **"This document is AUTHORITATIVE. No exceptions."** Includes ASCII architecture diagram with data flow, service responsibility table (Does / Does NOT), technology choices with rationale, and an "If You Are About To... STOP" section that blocks scope creep.

```
## If You Are About To...
- Add an endpoint to the wrong service → STOP. Check the table above.
- Create a direct database connection → STOP. Use the wrapper.
- Skip TypeScript for a quick fix → STOP. TypeScript is non-negotiable.
- Deploy without tests → STOP. Write tests first.
```

### DECISIONS.md

`project-docs/DECISIONS.md` — Architectural Decision Records (ADRs) that document **why** you chose X over Y. Includes two starter decisions:
- **ADR-001: TypeScript Over JavaScript** — AI needs explicit type contracts to avoid guessing
- **ADR-002: Centralized Database Wrapper** — prevents connection pool exhaustion

Each ADR has: Context, Decision, Alternatives Considered (with pros/cons table), and Consequences.

### INFRASTRUCTURE.md

`project-docs/INFRASTRUCTURE.md` — Deployment and environment details: environment overview diagram, environment variables table, deployment prerequisites and steps, rollback procedures, and monitoring setup.

---

## Testing Methodology

From the V5 testing methodology — a structured approach to testing that prevents the most common AI-assisted testing failures.

### CHECKLIST.md

`tests/CHECKLIST.md` — A master test status tracker that gives you a single-glance view of what's tested and what's not. Uses visual status indicators for every feature area.

### ISSUES_FOUND.md

`tests/ISSUES_FOUND.md` — A user-guided testing log where you document issues discovered during testing. Each entry includes: what was tested, what was expected, what actually happened, severity, and current status. Queue observations, fix in batch — not one at a time.

### E2E Test Requirements

Every E2E test (Playwright) must verify:

1. Correct URL after navigation
2. Key visible elements are present
3. Correct data is displayed
4. Error states show proper messages

### E2E Infrastructure

The Playwright config is pre-wired with test ports, automatic server spawning, and port cleanup:

1. `pnpm test:e2e` — kills anything on test ports (4000, 4010, 4020)
2. Playwright spawns servers via `webServer` config on test ports
3. Tests run against the test servers
4. Servers shut down automatically when tests complete

```bash
pnpm test              # ALL tests (unit + E2E)
pnpm test:unit         # Unit/integration only (Vitest)
pnpm test:e2e          # E2E only (kills ports → spawns servers → Playwright)
pnpm test:e2e:headed   # E2E with visible browser
pnpm test:e2e:ui       # E2E with Playwright UI mode
pnpm test:e2e:report   # Open last HTML report
```

---

## Windows Users — VS Code in WSL Mode

If you're developing on Windows, this is the single biggest performance improvement you can make.

**VS Code can run its entire backend inside WSL 2** while the UI stays on Windows. Your terminal, extensions, git, Node.js, and Claude Code all run natively in Linux.

| Without WSL Mode | With WSL Mode |
|-------------------|---------------|
| HMR takes 2-5 seconds per change | HMR is near-instant (<200ms) |
| Playwright tests are slow and flaky | Native Linux speed |
| File watching misses changes | Reliable and fast |
| Node.js ops hit NTFS translation | Native ext4 filesystem |
| `git status` takes seconds | Instant |

### Setup (One Time)

```bash
# 1. Install WSL 2 (PowerShell as admin)
wsl --install

# 2. Restart your computer

# 3. Install VS Code extension
#    Search for "WSL" by Microsoft (ms-vscode-remote.remote-wsl)

# 4. Connect VS Code to WSL
#    Click green "><" icon in bottom-left → "Connect to WSL"

# 5. Clone projects INSIDE WSL (not /mnt/c/)
mkdir -p ~/projects
cd ~/projects
git clone git@github.com:YourUser/your-project.git
code your-project    # opens in WSL mode automatically
```

### The Critical Mistake

**Your project MUST live on the WSL filesystem** (`~/projects/`), NOT on `/mnt/c/`. Having WSL but keeping your project on the Windows filesystem gives you the worst of both worlds.

```bash
# Check your setup:
pwd

# GOOD — native Linux filesystem
/home/you/projects/my-app

# BAD — still hitting Windows filesystem through WSL
/mnt/c/Users/you/projects/my-app
```

Run `/setup` in Claude Code to auto-detect your environment and get specific instructions.

---

## Global CLAUDE.md — Security Gatekeeper

The global `CLAUDE.md` lives at `~/.claude/CLAUDE.md` and applies to **every project** you work on. It's your organization-wide security gatekeeper.

The starter kit includes a complete global config template in `global-claude-md/` with:

- **Absolute Rules** — NEVER publish sensitive data. NEVER commit `.env` files. NEVER auto-deploy. NEVER hardcode credentials. NEVER rename without a plan. These apply to every project, every session.
- **New Project Standards** — Every new project automatically gets: `.env` + `.env.example`, proper `.gitignore`, `.dockerignore`, TypeScript strict mode, `src/tests/project-docs/.claude/` directory structure.
- **Coding Standards** — Error handling requirements, testing standards, quality gates, database wrapper pattern — all enforced across every project.
- **Global Permission Denials** — The companion `settings.json` explicitly denies Claude access to `.env`, `.env.local`, `secrets.json`, `id_rsa`, and `credentials.json` at the permission level — before hooks even run.

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

### Naming Safety

Renaming packages, modules, or key variables mid-project causes cascading failures. If you must rename:

1. Create a checklist of ALL files and references first
2. Use IDE semantic rename (not search-and-replace)
3. Full project search for old name after renaming
4. Check: `.md`, `.txt`, `.env`, comments, strings, paths
5. Start a FRESH Claude session after renaming

### Plan Mode — Named Steps + Replace, Don't Append

Every plan step MUST have a unique, descriptive name:

```
Step 1 (Project Setup): Initialize repo with TypeScript
Step 2 (Database Layer): Create MongoDB wrapper
Step 3 (Auth System): Implement JWT authentication
```

When modifying a plan:
- **REPLACE** the named step entirely: "Change Step 3 (Auth System) to use session cookies"
- **NEVER** just append: "Also, use session cookies" ← Step 3 still says JWT
- After any change, Claude must **rewrite the full updated plan**
- If the plan contradicts itself, tell Claude: "Rewrite the full plan — Step 3 and Step 7 contradict"
- If fundamentally changing direction: `/clear` → state requirements fresh

---

## All npm Scripts

| Command | What it does |
|---------|-------------|
| **Development** | |
| `pnpm dev` | Dev server with hot reload |
| `pnpm dev:website` | Dev server on port 3000 |
| `pnpm dev:api` | Dev server on port 3001 |
| `pnpm dev:dashboard` | Dev server on port 3002 |
| `pnpm build` | Type-check + compile TypeScript |
| `pnpm start` | Run production build |
| `pnpm typecheck` | TypeScript check only (no emit) |
| **Testing** | |
| `pnpm test` | Run ALL tests (unit + E2E) |
| `pnpm test:unit` | Unit/integration tests (Vitest) |
| `pnpm test:unit:watch` | Unit tests in watch mode |
| `pnpm test:coverage` | Unit tests with coverage report |
| `pnpm test:e2e` | E2E tests (kills ports → spawns servers → Playwright) |
| `pnpm test:e2e:headed` | E2E with visible browser |
| `pnpm test:e2e:ui` | E2E with Playwright UI mode |
| `pnpm test:e2e:chromium` | E2E on Chromium only (fast) |
| `pnpm test:e2e:report` | Open last Playwright HTML report |
| `pnpm test:kill-ports` | Kill processes on test ports (4000, 4010, 4020) |
| **Database** | |
| `pnpm db:query <name>` | Run a dev/test database query |
| `pnpm db:query:list` | List all registered queries |
| **Content** | |
| `pnpm content:build` | Build all published MD → HTML |
| `pnpm content:build:id <id>` | Build a single article by ID |
| `pnpm content:list` | List all articles |
| **Monitoring & Docker** | |
| `pnpm ai:monitor` | Live AI activity monitor (run in separate terminal) |
| `pnpm docker:optimize` | Audit Dockerfile (use `/optimize-docker` in Claude) |
| **Utility** | |
| `pnpm clean` | Remove dist/, coverage/, test-results/ |

---

## Monitor Your Rules with RuleCatch.AI (Optional)

> **Not required.** The starter kit works fully without RuleCatch. All hooks, commands, and quality gates function independently. If you don't install it, the `check-rulecatch.sh` hook simply skips silently with zero overhead.

> **Full disclosure:** RuleCatch.AI is built by [TheDecipherist](https://github.com/TheDecipherist) — the same developer behind this starter kit. It's included because it's an integral part of the workflow this kit teaches, and it's purpose-built for catching the exact issues AI-assisted development introduces. It is fully optional but recommended.

**Why you'd want it anyway:** AI models break your CLAUDE.md rules more often than you'd expect — wrong language, skipped patterns, hardcoded values, ignored constraints. Code that looks right and passes linting, but violates your project's actual standards. [RuleCatch.AI](https://rulecatch.ai?utm_source=github-pages&utm_medium=article&utm_campaign=rulecatch&utm_content=tutorial) bridges the gap between detecting these violations and fixing them. It monitors every tool call in real-time, and with the MCP server installed, Claude can query its own violations and generate fix plans — ask it: *"What rules am I breaking the most?"* or *"Create a plan to fix today's violations."*

**How it works — three components:**

| Component | What it does |
|-----------|-------------|
| **[AI-Pooler](https://www.npmjs.com/package/@rulecatch/ai-pooler)** | Collects tool calls from Claude via hooks. Runs outside the AI context — zero token overhead, invisible to the model |
| **[Dashboard](https://rulecatch.ai?utm_source=github-pages&utm_medium=article&utm_campaign=rulecatch&utm_content=tutorial)** | Shows violations across 18 rule categories, session analytics (tokens, cost, lines/hour), trend reports, and per-file attribution. Alerts via Slack, Discord, PagerDuty, and more |
| **[MCP Server](https://www.npmjs.com/package/@rulecatch/mcp-server)** | Gives Claude direct read access to violation data. Ask: *"Show all security violations this week"* or *"Create a plan to fix today's violations"* — Claude reviews, analyzes, and generates file-by-file fix plans without leaving your session |

- **200+ pre-built rules** across security, TypeScript, React, Next.js, MongoDB, Docker, and more — violations detected in under 100ms
- **Privacy-first** — AES-256-GCM client-side encryption. You hold the key — RuleCatch never sees your plaintext data. US and EU data isolation, fully GDPR compliant

**Quick setup:**

```bash
# Install the AI-Pooler (hooks into Claude Code automatically)
npx @rulecatch/ai-pooler init --api-key=dc_your_key --region=us

# Add the MCP server to query violations from Claude
npx @rulecatch/mcp-server init
```

npm: [@rulecatch/ai-pooler](https://www.npmjs.com/package/@rulecatch/ai-pooler) · [@rulecatch/mcp-server](https://www.npmjs.com/package/@rulecatch/mcp-server)

[Explore RuleCatch.AI →](https://rulecatch.ai?utm_source=github-pages&utm_medium=article&utm_campaign=rulecatch&utm_content=tutorial) · 7-day free trial - no credit card required

---

## Recommended MCP Servers

```bash
# Live documentation (eliminates outdated API answers)
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest

# GitHub integration (PRs, issues, CI/CD)
claude mcp add github -- npx -y @modelcontextprotocol/server-github

# E2E testing
claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp

# AI development analytics & rule monitoring (RuleCatch.AI)
npx @rulecatch/mcp-server init
```

See the [V4 guide](https://github.com/TheDecipherist/claude-code-mastery) for the complete MCP server directory.

---

## Credits

Based on the [Claude Code Mastery Guide](https://github.com/TheDecipherist/claude-code-mastery) series by [TheDecipherist](https://thedecipherist.com):
- V1: Global CLAUDE.md, Security Gatekeeper, Project Scaffolding, Context7
- V2: Skills & Hooks, Enforcement over Suggestion, Quality Gates
- V3: LSP, CLAUDE.md, MCP, Skills & Hooks
- V4: 85% Context Reduction, Custom Agents & Session Teleportation
- V5: Renaming Problem, Plan Mode, Testing Methodology & Rules That Stick

Community contributors: u/BlueVajra, u/stratofax, u/antoniocs, u/GeckoLogic, u/headset38, u/tulensrma, u/jcheroske, u/ptinsley, u/Keksy, u/lev606
