# Starter Kit Verification Test

> Comprehensive verification that every feature the starter kit claims to provide actually works.
>
> **How to use:** Run `/new-project TESTPROJECT default` to scaffold a project, then walk through each section below checking off items. Delete TESTPROJECT when done.

---

## Prerequisites

Before running this verification:

1. You are in the starter kit root directory
2. Node.js >= 20 is installed: `node --version`
3. pnpm is installed: `pnpm --version`
4. Python 3 is installed (for hooks): `python3 --version`
5. Git is installed: `git --version`

---

## Section 1: Starter Kit Source Files Exist

> Verify the starter kit itself is complete before testing `/new-project`.

### 1.1 Slash Commands (23 files)

```bash
ls -1 .claude/commands/
```

- [ ] `architecture.md` exists
- [ ] `commit.md` exists
- [ ] `create-api.md` exists
- [ ] `create-e2e.md` exists
- [ ] `diagram.md` exists
- [ ] `help.md` exists
- [ ] `install-global.md` exists
- [ ] `new-project.md` exists
- [ ] `optimize-docker.md` exists
- [ ] `progress.md` exists
- [ ] `quickstart.md` exists
- [ ] `refactor.md` exists
- [ ] `review.md` exists
- [ ] `security-check.md` exists
- [ ] `set-project-profile-default.md` exists
- [ ] `add-project-setup.md` exists
- [ ] `setup.md` exists
- [ ] `test-plan.md` exists
- [ ] `what-is-my-ai-doing.md` exists
- [ ] `worktree.md` exists
- [ ] `projects-created.md` exists
- [ ] `remove-project.md` exists
- [ ] `convert-project-to-starter-kit.md` exists
- [ ] **Total: 23 files** (`ls .claude/commands/ | wc -l` = 23)

### 1.2 Skills (2 directories)

```bash
ls -1 .claude/skills/*/SKILL.md
```

- [ ] `.claude/skills/code-review/SKILL.md` exists
- [ ] `.claude/skills/create-service/SKILL.md` exists

### 1.3 Agents (2 files)

```bash
ls -1 .claude/agents/
```

- [ ] `.claude/agents/code-reviewer.md` exists
- [ ] `.claude/agents/test-writer.md` exists

### 1.4 Hooks (4 files)

```bash
ls -1 .claude/hooks/
```

- [ ] `.claude/hooks/block-secrets.py` exists
- [ ] `.claude/hooks/check-rybbit.sh` exists
- [ ] `.claude/hooks/check-branch.sh` exists
- [ ] `.claude/hooks/check-ports.sh` exists
- [ ] `.claude/hooks/check-e2e.sh` exists
- [ ] `.claude/hooks/lint-on-save.sh` exists
- [ ] `.claude/hooks/verify-no-secrets.sh` exists
- [ ] `.claude/hooks/check-rulecatch.sh` exists
- [ ] `.claude/hooks/check-env-sync.sh` exists

### 1.5 Settings

```bash
cat .claude/settings.json | python3 -m json.tool
```

- [ ] `.claude/settings.json` is valid JSON
- [ ] Has `PreToolUse` hook for `Read|Edit|Write` → `block-secrets.py`
- [ ] Has `PreToolUse` hook for `Bash` → `check-rybbit.sh`, `check-branch.sh`, `check-ports.sh`, `check-e2e.sh`
- [ ] Has `PostToolUse` hook for `Write` → `lint-on-save.sh`
- [ ] Has `Stop` hook → `verify-no-secrets.sh`
- [ ] Has `Stop` hook → `check-rulecatch.sh`
- [ ] Has `Stop` hook → `check-env-sync.sh`

### 1.6 Global Claude Config Templates

```bash
ls -1 global-claude-md/
```

- [ ] `global-claude-md/CLAUDE.md` exists
- [ ] `global-claude-md/settings.json` exists
- [ ] `global-claude-md/settings.json` has `permissions.deny` list for sensitive files
- [ ] `global-claude-md/settings.json` has `PreToolUse` hook → `~/.claude/hooks/block-secrets.py`
- [ ] `global-claude-md/settings.json` has `Stop` hooks → `verify-no-secrets.sh` and `check-rulecatch.sh`

### 1.7 Database Wrapper

```bash
wc -l src/core/db/index.ts
```

- [ ] `src/core/db/index.ts` exists
- [ ] File size < 700 lines (currently ~655)
- [ ] Exports: `connect`, `closePool`, `getDb`, `getCollection`
- [ ] Exports: `queryOne`, `queryMany`, `queryWithLookup`, `count`
- [ ] Exports: `insertOne`, `insertMany`, `updateOne`, `updateMany`, `deleteOne`, `deleteMany`, `bulkOps`
- [ ] Exports: `withTransaction`, `rawCollection`
- [ ] Exports: `registerIndex`, `ensureIndexes`
- [ ] Exports: `gracefulShutdown`
- [ ] Exports: `sanitizeFilter`, `configureSanitization`
- [ ] Uses `MongoClient` singleton via `globalThis` symbol
- [ ] Has pool presets: `high` (20), `standard` (10), `low` (5)
- [ ] `sanitize()` function strips `$`-prefixed keys
- [ ] `sanitizePipeline()` only sanitizes `$match` stages

Verify exports exist:

```bash
grep -c "^export " src/core/db/index.ts
```

Expected: >= 18 exported functions/interfaces.

### 1.8 Scripts Directory

```bash
ls -1 scripts/
```

- [ ] `scripts/db-query.ts` exists
- [ ] `scripts/build-content.ts` exists
- [ ] `scripts/content.config.json` exists
- [ ] `scripts/queries/` directory exists

```bash
ls -1 scripts/queries/
```

- [ ] `scripts/queries/example-find-user.ts` exists
- [ ] `scripts/queries/example-count-docs.ts` exists

### 1.9 Project Documentation Templates

```bash
ls -1 project-docs/
```

- [ ] `project-docs/ARCHITECTURE.md` exists
- [ ] `project-docs/INFRASTRUCTURE.md` exists
- [ ] `project-docs/DECISIONS.md` exists

### 1.10 Test Infrastructure

```bash
ls -R tests/
```

- [ ] `tests/unit/` directory exists
- [ ] `tests/integration/` directory exists
- [ ] `tests/e2e/` directory exists
- [ ] `tests/e2e/example-homepage.spec.ts` exists
- [ ] `tests/CHECKLIST.md` exists
- [ ] `tests/ISSUES_FOUND.md` exists

### 1.11 Config Files

- [ ] `package.json` exists and is valid JSON
- [ ] `tsconfig.json` exists and is valid JSON
- [ ] `playwright.config.ts` exists
- [ ] `vitest.config.ts` exists
- [ ] `claude-mastery-project.conf` exists
- [ ] `.env.example` exists
- [ ] `.gitignore` exists
- [ ] `.dockerignore` exists
- [ ] `CLAUDE.md` exists
- [ ] `CLAUDE.local.md` exists
- [ ] `README.md` exists
- [ ] `content/getting-started.md` exists

---

## Section 2: Package.json Scripts (31 scripts)

> Verify every script defined in package.json exists and is correctly defined.

```bash
cat package.json | python3 -c "import sys,json; [print(k) for k in json.load(sys.stdin)['scripts']]"
```

### 2.1 Dev Scripts

- [ ] `dev` = `tsx watch src/index.ts`
- [ ] `dev:website` = `PORT=3000 tsx watch src/index.ts`
- [ ] `dev:api` = `PORT=3001 tsx watch src/index.ts`
- [ ] `dev:dashboard` = `PORT=3002 tsx watch src/index.ts`
- [ ] `dev:test:website` = `PORT=4000 tsx watch src/index.ts`
- [ ] `dev:test:api` = `PORT=4010 tsx watch src/index.ts`
- [ ] `dev:test:dashboard` = `PORT=4020 tsx watch src/index.ts`

### 2.2 Build & Run Scripts

- [ ] `build` = `tsc --noEmit && tsc`
- [ ] `start` = `node dist/index.js`
- [ ] `typecheck` = `tsc --noEmit`
- [ ] `lint` = `tsc --noEmit`

### 2.3 Test Scripts

- [ ] `test` = `pnpm test:unit && pnpm test:e2e`
- [ ] `test:unit` = `vitest run`
- [ ] `test:unit:watch` = `vitest`
- [ ] `test:coverage` = `vitest run --coverage`
- [ ] `test:e2e` = `pnpm test:kill-ports && playwright test`
- [ ] `test:e2e:ui` = `pnpm test:kill-ports && playwright test --ui`
- [ ] `test:e2e:headed` = `pnpm test:kill-ports && playwright test --headed`
- [ ] `test:e2e:report` = `playwright show-report`
- [ ] `test:e2e:chromium` — exists (not in starter kit package.json but referenced in CLAUDE.md)
- [ ] `test:kill-ports` = `lsof -ti:4000,4010,4020 | xargs kill -9 2>/dev/null || true`

### 2.4 Database Scripts

- [ ] `db:query` = `tsx scripts/db-query.ts`
- [ ] `db:query:list` = `tsx scripts/db-query.ts --list`

### 2.5 Content Scripts

- [ ] `content:build` = `tsx scripts/build-content.ts`
- [ ] `content:build:id` = `tsx scripts/build-content.ts --id`
- [ ] `content:list` = `tsx scripts/build-content.ts --list`
- [ ] `content:dry-run` = `tsx scripts/build-content.ts --dry-run`

### 2.6 Utility Scripts

- [ ] `ai:monitor` = `npx @rulecatch/ai-pooler@latest monitor -v`
- [ ] `docker:optimize` — exists (echo helper)
- [ ] `clean` = `rm -rf dist coverage test-results playwright-report`
- [ ] `precommit` = `tsc --noEmit`

### 2.7 Dependencies

```bash
cat package.json | python3 -c "import sys,json; d=json.load(sys.stdin); print('deps:', list(d.get('dependencies',{}).keys())); print('devDeps:', list(d.get('devDependencies',{}).keys()))"
```

- [ ] `mongodb` in dependencies (^6.5.0)
- [ ] `@playwright/test` in devDependencies (^1.42.0)
- [ ] `tsx` in devDependencies (^4.7.0)
- [ ] `typescript` in devDependencies (^5.4.0)
- [ ] `vitest` in devDependencies (^2.0.0)
- [ ] `engines.node` >= 20.0.0

---

## Section 3: TypeScript Configuration

```bash
cat tsconfig.json | python3 -m json.tool
```

- [ ] `target` = `ES2022`
- [ ] `module` = `ESNext`
- [ ] `moduleResolution` = `bundler`
- [ ] `strict` = `true`
- [ ] `noUncheckedIndexedAccess` = `true`
- [ ] `noImplicitOverride` = `true`
- [ ] `esModuleInterop` = `true`
- [ ] `skipLibCheck` = `true`
- [ ] `declaration` = `true`
- [ ] `declarationMap` = `true`
- [ ] `sourceMap` = `true`
- [ ] `outDir` = `dist`
- [ ] `rootDir` = `src`

---

## Section 4: Playwright Configuration

```bash
head -74 playwright.config.ts
```

- [ ] `testDir` = `./tests/e2e`
- [ ] `baseURL` = `http://localhost:4000` (test port, not dev port)
- [ ] Has `webServer` config for test ports
- [ ] `webServer[0].command` includes `pnpm dev:test:website`
- [ ] `webServer[0].port` = `4000`
- [ ] Has at minimum `chromium` project
- [ ] Has `firefox` project
- [ ] Has `webkit` project
- [ ] Has mobile chrome project
- [ ] `trace` = `on-first-retry`
- [ ] `screenshot` = `only-on-failure`
- [ ] `fullyParallel` = `true`

---

## Section 5: Vitest Configuration

```bash
cat vitest.config.ts
```

- [ ] Includes `tests/unit/**/*.test.ts`
- [ ] Includes `tests/integration/**/*.test.ts`
- [ ] Excludes `tests/e2e/**/*`
- [ ] Environment = `node`
- [ ] Coverage provider = `v8`

---

## Section 6: Security Verification

### 6.1 .gitignore Coverage

```bash
cat .gitignore
```

- [ ] `.env` is listed
- [ ] `.env.local` is listed (or `.env.*` wildcard)
- [ ] `.env.production` is listed
- [ ] `.env.staging` is listed
- [ ] `secrets.json` is listed
- [ ] `credentials.json` is listed
- [ ] `service-account.json` is listed
- [ ] `CLAUDE.local.md` is listed
- [ ] `node_modules/` is listed
- [ ] `dist/` is listed
- [ ] `coverage/` is listed
- [ ] `test-results/` is listed
- [ ] `playwright-report/` is listed

### 6.2 .dockerignore Coverage

```bash
cat .dockerignore
```

- [ ] `.env` is listed
- [ ] `.env.*` is listed
- [ ] `.git/` is listed
- [ ] `node_modules/` is listed
- [ ] `.claude/` is listed
- [ ] `CLAUDE.md` is listed
- [ ] `CLAUDE.local.md` is listed
- [ ] `project-docs/` is listed
- [ ] `coverage/` is listed
- [ ] `test-results/` is listed

### 6.3 .env.example (no real secrets)

```bash
cat .env.example
```

- [ ] Contains `NODE_ENV=development`
- [ ] Contains `PORT=3001`
- [ ] Contains `DATABASE_URL=your_database_connection_string_here` (placeholder, not real)
- [ ] Contains `DB_SANITIZE_INPUTS=true`
- [ ] Contains `JWT_SECRET=your_jwt_secret_here` (placeholder, not real)
- [ ] No real API keys, passwords, or tokens present

### 6.4 block-secrets.py Hook Works

```bash
echo '{"tool_input":{"file_path":"/path/to/.env"}}' | python3 .claude/hooks/block-secrets.py; echo "Exit: $?"
```

- [ ] Exit code = 2 (blocked)
- [ ] Prints "BLOCKED" message to stderr

```bash
echo '{"tool_input":{"file_path":"/path/to/normal-file.ts"}}' | python3 .claude/hooks/block-secrets.py; echo "Exit: $?"
```

- [ ] Exit code = 0 (allowed)

Test all sensitive filenames:

```bash
for f in .env .env.local .env.production secrets.json id_rsa id_ed25519 .npmrc credentials.json service-account.json; do
  result=$(echo "{\"tool_input\":{\"file_path\":\"/test/$f\"}}" | python3 .claude/hooks/block-secrets.py 2>&1; echo "EXIT:$?")
  echo "$f → $result"
done
```

- [ ] All sensitive files return exit code 2
- [ ] All print "BLOCKED" message

Test sensitive path patterns:

```bash
for p in "/home/.ssh/config" "/path/aws/credentials" "/data/private_key.pem" "/path/secret_key.txt"; do
  result=$(echo "{\"tool_input\":{\"file_path\":\"$p\"}}" | python3 .claude/hooks/block-secrets.py 2>&1; echo "EXIT:$?")
  echo "$p → $result"
done
```

- [ ] All sensitive paths return exit code 2

### 6.5 verify-no-secrets.sh Behavior

> This hook only runs inside a git repo with staged files. Test the script logic:

```bash
bash -c 'file .claude/hooks/verify-no-secrets.sh'
```

- [ ] File is a valid bash script
- [ ] Script checks for `git rev-parse --is-inside-work-tree`
- [ ] Script checks `git diff --cached --name-only`
- [ ] Script checks for sensitive filename patterns
- [ ] Script greps staged content for API key patterns
- [ ] Script greps staged content for AWS access keys (`AKIA...`)
- [ ] Returns exit 2 when violations found
- [ ] Returns exit 0 when clean

### 6.6 lint-on-save.sh Behavior

```bash
bash -c 'file .claude/hooks/lint-on-save.sh'
```

- [ ] File is a valid bash script
- [ ] Handles `.ts`/`.tsx` files → runs `tsc --noEmit`
- [ ] Handles `.js`/`.jsx` files → runs eslint
- [ ] Handles `.py` files → runs ruff or flake8
- [ ] Returns exit 0 (never blocks)

### 6.7 check-rulecatch.sh Behavior

```bash
bash -c 'file .claude/hooks/check-rulecatch.sh'
```

- [ ] File is a valid bash script
- [ ] Checks if `npx` is available
- [ ] Checks if `@rulecatch/ai-pooler` is installed
- [ ] Returns exit 0 (warns, never blocks)

### 6.8 check-rybbit.sh Behavior

```bash
bash -c 'file .claude/hooks/check-rybbit.sh'
```

- [ ] File is a valid bash script
- [ ] Skips non-deployment commands (exit 0)
- [ ] Checks `claude-mastery-project.conf` for `analytics = rybbit`
- [ ] If no conf or `analytics = none` → exit 0
- [ ] Checks `.env` for `NEXT_PUBLIC_RYBBIT_SITE_ID`
- [ ] Blocks if missing, empty, or placeholder value → exit 2
- [ ] Error message points to https://app.rybbit.io

### 6.9 check-branch.sh Behavior

```bash
bash -c 'file .claude/hooks/check-branch.sh'
```

- [ ] File is a valid bash script
- [ ] Skips non-`git commit` commands → exit 0
- [ ] Skips if not in a git repo → exit 0
- [ ] If not on main/master → exit 0
- [ ] Checks `auto_branch` setting (default: true)
- [ ] If auto_branch=true and on main → exit 2
- [ ] If auto_branch=false → exit 0

### 6.10 check-ports.sh Behavior

```bash
bash -c 'file .claude/hooks/check-ports.sh'
```

- [ ] File is a valid bash script
- [ ] Extracts port from `-p`, `--port`, `PORT=`, or known script names
- [ ] Maps `dev:website`→3000, `dev:api`→3001, `dev:dashboard`→3002
- [ ] Maps test ports: `dev:test:website`→4000, `dev:test:api`→4010, `dev:test:dashboard`→4020
- [ ] If no port detected → exit 0
- [ ] If `lsof` unavailable → exit 0
- [ ] If port in use → exit 2 showing PID and kill command

### 6.11 check-e2e.sh Behavior

```bash
bash -c 'file .claude/hooks/check-e2e.sh'
```

- [ ] File is a valid bash script
- [ ] Skips non-`git push` commands → exit 0
- [ ] Detects push to main/master (explicit or current branch)
- [ ] Checks `tests/e2e/` for `.spec.ts` or `.test.ts` files
- [ ] Excludes `example-homepage.spec.ts` from the count
- [ ] Blocks if no real E2E tests → exit 2
- [ ] If real tests exist → exit 0

### 6.12 check-env-sync.sh Behavior

```bash
bash -c 'file .claude/hooks/check-env-sync.sh'
```

- [ ] File is a valid bash script
- [ ] Skips if `.env` or `.env.example` doesn't exist → exit 0
- [ ] Extracts key names only (never reads values)
- [ ] Finds keys in `.env` missing from `.env.example`
- [ ] Prints warning listing missing key names
- [ ] Always returns exit 0 (informational, never blocks)

---

## Section 7: Configuration File (claude-mastery-project.conf)

```bash
cat claude-mastery-project.conf
```

### 7.1 Global Settings

- [ ] `root_dir = ~/projects`
- [ ] `auto_branch = true`
- [ ] `sanitize = true`
- [ ] `docker_test_before_push = false`

### 7.2 Profiles Exist

- [ ] `[clean]` profile exists — `opinionated = false`
- [ ] `[default]` profile exists — `type = fullstack`, `framework = next`, `database = mongo`
- [ ] `[api]` profile exists — `type = api`, `framework = fastify`
- [ ] `[static-site]` profile exists — `framework = astro`, `database = none`
- [ ] `[quick]` profile exists — `framework = vite`, `hosting = vercel`
- [ ] `[enterprise]` profile exists — has `multiregion` in options
- [ ] `[go]` profile exists — `language = go`, `type = api`, `framework = gin`

### 7.3 Profile Fields Consistent

For `[default]`:
- [ ] `type` = fullstack
- [ ] `framework` = next
- [ ] `hosting` = dokploy
- [ ] `package_manager` = pnpm
- [ ] `database` = mongo
- [ ] `analytics` = rybbit
- [ ] `options` includes: seo, tailwind, docker, ci
- [ ] `mcp` includes: playwright, context7, rulecatch
- [ ] `npm` = @rulecatch/ai-pooler

---

## Section 8: E2E Test Template Quality

```bash
cat tests/e2e/example-homepage.spec.ts
```

- [ ] Imports from `@playwright/test`
- [ ] Uses `test.describe()` for grouping
- [ ] **Happy path test** has >= 3 assertions:
  - [ ] URL assertion (`toHaveURL`)
  - [ ] Element visibility assertion (`toBeVisible`)
  - [ ] Content assertion (`toContainText` or `toHaveTitle`)
- [ ] **Navigation test** verifies URL change and content
- [ ] **Error handling test** checks 404 status and error page content
- [ ] **Responsive test** changes viewport and verifies mobile behavior
- [ ] No empty tests (every `test()` block has assertions)

---

## Section 9: Database Wrapper Compiles

> Verify the db wrapper has no TypeScript errors.

```bash
cd /home/tim_carter81/projects/claude-code-mastery-project-starter-kit && pnpm install 2>&1 | tail -5
```

- [ ] `pnpm install` succeeds

```bash
pnpm typecheck 2>&1
```

- [ ] TypeScript compiles with zero errors
- [ ] `src/core/db/index.ts` passes type checking

---

## Section 10: Content System

### 10.1 Content Config Valid

```bash
cat scripts/content.config.json | python3 -m json.tool > /dev/null && echo "VALID JSON" || echo "INVALID"
```

- [ ] `content.config.json` is valid JSON
- [ ] Has `siteUrl` field
- [ ] Has `siteName` field
- [ ] Has `author` field
- [ ] Has `outputDir` field
- [ ] Has `categories` array
- [ ] Has `articles` array with >= 1 entry
- [ ] First article has: id, published, mdSource, htmlOutput, title, description, url
- [ ] Second article has `sidebar: true` and `children` array (advanced feature)
- [ ] `published` flag exists (true/false per article)

### 10.2 Content Source Exists

- [ ] `content/getting-started.md` exists and has content

### 10.3 Content Scripts Run

```bash
pnpm content:list 2>&1
```

- [ ] Lists articles with their published status

```bash
pnpm content:dry-run 2>&1
```

- [ ] Shows what would be built without writing files

---

## Section 11: DB Query System

### 11.1 Query Registry

```bash
pnpm db:query --help 2>&1
```

- [ ] Shows usage information
- [ ] Shows `--list` option
- [ ] Shows example commands

### 11.2 Query List

```bash
pnpm db:query:list 2>&1
```

- [ ] Lists `example-find-user` with description
- [ ] Lists `example-count-docs` with description
- [ ] Closes pool after listing (no hanging process)

---

## Section 12: CLAUDE.md Completeness

> Verify the project CLAUDE.md covers all documented features.

```bash
wc -l CLAUDE.md
```

### 12.1 Required Sections

- [ ] Quick Reference scripts table exists
- [ ] Rule 0: NEVER Publish Sensitive Data
- [ ] Rule 1: TypeScript Always
- [ ] Rule 2: API Versioning (`/api/v1/`)
- [ ] Rule 3: Database Access — Wrapper Only
- [ ] Rule 4: Testing — Explicit Success Criteria
- [ ] Rule 5: NEVER Hardcode Credentials
- [ ] Rule 6: ALWAYS Ask Before Deploying
- [ ] Rule 7: Quality Gates (300 lines, 50 lines)
- [ ] Rule 8: Parallelize Independent Awaits
- [ ] Rule 9: Git Workflow — NEVER Work on Main
- [ ] Rule 10: Docker Push Gate
- [ ] Service Ports table (3000/3001/3002 dev, 4000/4010/4020 test)
- [ ] Project Structure diagram
- [ ] Project Documentation table
- [ ] Coding Standards section
- [ ] Plan Mode section
- [ ] Workflow Preferences section

### 12.2 Scripts Table Matches Package.json

Cross-reference every script in the Quick Reference table with `package.json`:

```bash
# Extract script names from package.json
cat package.json | python3 -c "import sys,json; [print(k) for k in sorted(json.load(sys.stdin)['scripts'])]"
```

- [ ] Every script in the CLAUDE.md table exists in package.json
- [ ] No phantom scripts (listed in CLAUDE.md but missing from package.json)

---

## Section 13: /new-project Command Verification

> This is the main test. Run `/new-project` and verify the output.

### 13.1 Create Test Project

In Claude Code, run:

```
/new-project TESTPROJECT default
```

This should create `~/projects/TESTPROJECT` using the `[default]` profile.

### 13.2 Verify Directory Created

```bash
ls ~/projects/TESTPROJECT/
```

- [ ] Directory exists at `~/projects/TESTPROJECT`

### 13.3 Verify Core Files

```bash
ls -la ~/projects/TESTPROJECT/
```

- [ ] `.env` exists (empty or minimal)
- [ ] `.env.example` exists with placeholders
- [ ] `.gitignore` exists and includes `.env`
- [ ] `.dockerignore` exists
- [ ] `CLAUDE.md` exists with project-specific rules
- [ ] `CLAUDE.local.md` exists (personal overrides template)
- [ ] `README.md` exists
- [ ] `package.json` exists
- [ ] `tsconfig.json` exists (strict mode)

### 13.4 Verify Directory Structure

```bash
ls -R ~/projects/TESTPROJECT/src/ 2>/dev/null
ls -R ~/projects/TESTPROJECT/tests/ 2>/dev/null
ls -R ~/projects/TESTPROJECT/project-docs/ 2>/dev/null
ls -R ~/projects/TESTPROJECT/.claude/ 2>/dev/null
ls -R ~/projects/TESTPROJECT/scripts/ 2>/dev/null
```

- [ ] `src/` directory exists
- [ ] `src/core/db/index.ts` exists (MongoDB wrapper — default profile has `database = mongo`)
- [ ] `tests/unit/` exists
- [ ] `tests/integration/` exists
- [ ] `tests/e2e/` exists
- [ ] `project-docs/ARCHITECTURE.md` exists
- [ ] `project-docs/INFRASTRUCTURE.md` exists
- [ ] `project-docs/DECISIONS.md` exists
- [ ] `.claude/commands/` directory exists with commands
- [ ] `.claude/skills/` directory exists with skills
- [ ] `.claude/agents/` directory exists with agents
- [ ] `.claude/hooks/` directory exists with hooks
- [ ] `.claude/settings.json` exists with hooks wired
- [ ] `scripts/db-query.ts` exists (mongo profile)
- [ ] `scripts/queries/` directory exists

### 13.5 Verify Test Infrastructure

```bash
cat ~/projects/TESTPROJECT/playwright.config.ts 2>/dev/null | head -5
cat ~/projects/TESTPROJECT/vitest.config.ts 2>/dev/null | head -5
```

- [ ] `playwright.config.ts` exists with test port 4000
- [ ] `vitest.config.ts` exists

### 13.6 Verify TypeScript Strict Mode

```bash
cat ~/projects/TESTPROJECT/tsconfig.json | python3 -c "import sys,json; c=json.load(sys.stdin)['compilerOptions']; print('strict:', c.get('strict')); print('noUncheckedIndexedAccess:', c.get('noUncheckedIndexedAccess'))"
```

- [ ] `strict` = true
- [ ] `noUncheckedIndexedAccess` = true

### 13.7 Verify Git Initialized

```bash
cd ~/projects/TESTPROJECT && git log --oneline -1
```

- [ ] Git repo initialized
- [ ] Has initial commit

### 13.8 Verify Default Profile Applied

Since `default` profile was used:

- [ ] Framework is Next.js (check package.json for `next`)
- [ ] Package manager is pnpm (check for `pnpm-lock.yaml`)
- [ ] Database is MongoDB (check for `src/core/db/index.ts`)
- [ ] Has SEO setup (check for meta tags in layout)
- [ ] Has Tailwind CSS (check for `tailwindcss` in dependencies)
- [ ] Has Docker setup (check for `Dockerfile`)
- [ ] Has CI setup (check for `.github/workflows/`)
- [ ] Rybbit analytics placeholder in `.env.example`

### 13.9 Verify Package.json Scripts

```bash
cat ~/projects/TESTPROJECT/package.json | python3 -c "import sys,json; [print(k) for k in sorted(json.load(sys.stdin)['scripts'])]"
```

- [ ] Has `dev` script
- [ ] Has `build` script
- [ ] Has `test` script (runs unit + e2e)
- [ ] Has `test:unit` script
- [ ] Has `test:e2e` script
- [ ] Has `test:kill-ports` script
- [ ] Has `dev:test:website` script (PORT=4000)

### 13.10 Verify CLAUDE.md Content

```bash
head -50 ~/projects/TESTPROJECT/CLAUDE.md
```

- [ ] Has project-specific overview (not generic starter kit text)
- [ ] Has tech stack section mentioning Next.js, MongoDB, etc.
- [ ] Has port assignments
- [ ] Has build/test/dev commands
- [ ] Has database rules (wrapper-only access)

### 13.11 Verify Error Handlers

```bash
grep -l "gracefulShutdown\|uncaughtException\|unhandledRejection" ~/projects/TESTPROJECT/src/*.ts ~/projects/TESTPROJECT/src/**/*.ts 2>/dev/null
```

- [ ] Entry point has `gracefulShutdown` wired to SIGTERM/SIGINT
- [ ] Entry point has `uncaughtException` handler
- [ ] Entry point has `unhandledRejection` handler

---

## Section 14: /new-project Clean Mode

> Verify clean mode creates infrastructure without opinions.

### 14.1 Create Clean Test Project

In Claude Code, run:

```
/new-project TESTPROJECT-CLEAN clean
```

### 14.2 Verify Clean Mode Output

```bash
ls -la ~/projects/TESTPROJECT-CLEAN/
```

**Should exist:**

- [ ] `.claude/` with all commands, skills, agents, hooks
- [ ] `.claude/settings.json` with hooks wired
- [ ] `CLAUDE.md` — security rules ONLY (no TypeScript, no ports, no quality gates)
- [ ] `CLAUDE.local.md` — personal overrides template
- [ ] `project-docs/ARCHITECTURE.md`
- [ ] `project-docs/INFRASTRUCTURE.md`
- [ ] `project-docs/DECISIONS.md`
- [ ] `tests/CHECKLIST.md`
- [ ] `tests/ISSUES_FOUND.md`
- [ ] `.env` (empty)
- [ ] `.env.example`
- [ ] `.gitignore`
- [ ] `.dockerignore`
- [ ] `README.md`
- [ ] Git initialized with initial commit

**Should NOT exist:**

- [ ] No `package.json` — user picks their own language/runtime
- [ ] No `tsconfig.json` — user may not use TypeScript
- [ ] No `src/` directory — user decides structure
- [ ] No `vitest.config.ts` or `playwright.config.ts`
- [ ] No `scripts/db-query.ts`
- [ ] No `scripts/build-content.ts`
- [ ] No framework-specific configs

### 14.3 Verify Clean CLAUDE.md

```bash
cat ~/projects/TESTPROJECT-CLEAN/CLAUDE.md
```

- [ ] Has "NEVER Publish Sensitive Data" rule
- [ ] Has "NEVER Hardcode Credentials" rule
- [ ] Has "ALWAYS Ask Before Deploying" rule
- [ ] Does NOT have TypeScript rules
- [ ] Does NOT have API versioning rules
- [ ] Does NOT have port assignments
- [ ] Does NOT have quality gate numbers (300 lines, 50 lines)
- [ ] Does NOT have database wrapper rules

---

## Section 15: /new-project Go Mode

> Verify Go mode creates a proper Go project without Node.js artifacts.

### 15.1 Create Go Test Project

In Claude Code, run:

```
/new-project TESTPROJECT-GO go
```

This should create `~/projects/TESTPROJECT-GO` using the `[go]` profile.

### 15.2 Verify Go Project Structure

```bash
ls -la ~/projects/TESTPROJECT-GO/
ls -R ~/projects/TESTPROJECT-GO/cmd/ 2>/dev/null
ls -R ~/projects/TESTPROJECT-GO/internal/ 2>/dev/null
```

**Should exist:**

- [ ] `go.mod` exists with correct module path
- [ ] `go.sum` exists
- [ ] `cmd/server/main.go` exists
- [ ] `internal/handlers/health.go` exists
- [ ] `internal/middleware/` directory exists
- [ ] `internal/models/` directory exists
- [ ] `Makefile` exists with build, test, lint targets
- [ ] `Dockerfile` exists (multi-stage with scratch)
- [ ] `.golangci.yml` exists
- [ ] `.env` exists
- [ ] `.env.example` exists
- [ ] `.gitignore` exists with Go-specific entries (bin/, *.exe)
- [ ] `.dockerignore` exists
- [ ] `CLAUDE.md` exists with Go-specific rules
- [ ] `CLAUDE.local.md` exists
- [ ] `README.md` exists
- [ ] `project-docs/ARCHITECTURE.md` exists
- [ ] `project-docs/INFRASTRUCTURE.md` exists
- [ ] `project-docs/DECISIONS.md` exists
- [ ] `.claude/` has commands, skills, agents, hooks, settings.json
- [ ] Git initialized with initial commit

### 15.3 Verify Go CLAUDE.md Has Go Rules

```bash
cat ~/projects/TESTPROJECT-GO/CLAUDE.md
```

- [ ] Has error handling rule (never ignore errors)
- [ ] Has context.Context propagation rule
- [ ] Has table-driven tests rule
- [ ] Has API versioning rule (`/api/v1/`)
- [ ] Has graceful shutdown rule
- [ ] Does NOT have TypeScript rules
- [ ] Does NOT have Node.js-specific rules (package.json scripts, vitest, playwright)

### 15.4 Verify Go Build Succeeds

```bash
cd ~/projects/TESTPROJECT-GO && go build ./...
```

- [ ] `go build ./...` exits with code 0

### 15.5 Verify Go Vet Passes

```bash
cd ~/projects/TESTPROJECT-GO && go vet ./...
```

- [ ] `go vet ./...` exits with code 0

### 15.6 Verify No Node.js Artifacts

```bash
ls ~/projects/TESTPROJECT-GO/package.json 2>/dev/null
ls ~/projects/TESTPROJECT-GO/tsconfig.json 2>/dev/null
ls ~/projects/TESTPROJECT-GO/node_modules/ 2>/dev/null
```

- [ ] No `package.json`
- [ ] No `tsconfig.json`
- [ ] No `node_modules/`
- [ ] No `vitest.config.ts`
- [ ] No `playwright.config.ts`

---

## Section 16: SQL Database Wrapper

> Verify the SQL wrapper template exists and exports the expected API.

### 16.1 File Exists

```bash
wc -l src/core/db/sql.ts
```

- [ ] `src/core/db/sql.ts` exists
- [ ] File size < 400 lines

### 16.2 Exports

```bash
grep -c "^export " src/core/db/sql.ts
```

- [ ] Exports: `connect`, `getPool`, `closePool`, `gracefulShutdown`
- [ ] Exports: `queryOne`, `queryMany`, `count`
- [ ] Exports: `execute`, `insertOne`, `insertMany`, `updateOne`, `deleteOne`
- [ ] Exports: `withTransaction`
- [ ] Exports: `buildWhere`
- [ ] Expected: >= 12 exported functions/interfaces

### 16.3 Driver Detection

```bash
grep "detectDriver" src/core/db/sql.ts
```

- [ ] Detects `postgresql://` and `postgres://` → pg
- [ ] Detects `mysql://` → mysql2
- [ ] Detects `mssql://` → mssql
- [ ] Detects `file:` and `sqlite:` → better-sqlite3

### 16.4 Pool Presets

- [ ] `high` preset = max 20
- [ ] `standard` preset = max 10
- [ ] `low` preset = max 5

---

## Section 17: /new-project Python Mode

> Verify Python mode creates a proper Python project without Node.js or Go artifacts.

### 17.1 Create Python Test Project

In Claude Code, run:

```
/new-project TESTPROJECT-PYTHON python-api
```

### 17.2 Verify Python Project Structure

```bash
ls -la ~/projects/TESTPROJECT-PYTHON/
ls -R ~/projects/TESTPROJECT-PYTHON/src/ 2>/dev/null
```

**Should exist:**

- [ ] `pyproject.toml` exists
- [ ] `requirements.txt` exists
- [ ] `requirements-dev.txt` exists
- [ ] `ruff.toml` exists
- [ ] `Makefile` exists with dev, test, lint targets
- [ ] `src/app/main.py` exists
- [ ] `src/app/config.py` exists
- [ ] `src/app/api/v1/` directory exists
- [ ] `tests/conftest.py` exists
- [ ] `tests/test_health.py` exists
- [ ] `.env` exists
- [ ] `.env.example` exists
- [ ] `.gitignore` includes Python-specific entries (__pycache__, .venv)
- [ ] `CLAUDE.md` has Python-specific rules
- [ ] `CLAUDE.local.md` exists
- [ ] `project-docs/ARCHITECTURE.md` exists
- [ ] `.claude/` has commands, skills, agents, hooks, settings.json
- [ ] Git initialized with initial commit

### 17.3 Verify Python CLAUDE.md

```bash
cat ~/projects/TESTPROJECT-PYTHON/CLAUDE.md
```

- [ ] Has type hints rule
- [ ] Has async/await rule
- [ ] Has pytest rule
- [ ] Has virtual environment rule
- [ ] Has API versioning rule (`/api/v1/`)
- [ ] Does NOT have TypeScript rules
- [ ] Does NOT have Node.js-specific rules

### 17.4 Verify No Node.js/Go Artifacts

- [ ] No `package.json`
- [ ] No `tsconfig.json`
- [ ] No `node_modules/`
- [ ] No `go.mod`
- [ ] No `vitest.config.ts`

---

## Section 18: New Commands Verification

### 18.1 Old Commands Removed

```bash
ls .claude/commands/set-clean-as-default.md 2>/dev/null && echo "EXISTS" || echo "GONE"
ls .claude/commands/reset-to-defaults.md 2>/dev/null && echo "EXISTS" || echo "GONE"
```

- [ ] `set-clean-as-default.md` is GONE
- [ ] `reset-to-defaults.md` is GONE

### 18.2 New Commands Exist

```bash
ls .claude/commands/set-project-profile-default.md 2>/dev/null && echo "EXISTS" || echo "MISSING"
ls .claude/commands/add-project-setup.md 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

- [ ] `set-project-profile-default.md` EXISTS
- [ ] `add-project-setup.md` EXISTS

### 18.3 New Project Management Commands Exist

```bash
ls .claude/commands/projects-created.md 2>/dev/null && echo "EXISTS" || echo "MISSING"
ls .claude/commands/remove-project.md 2>/dev/null && echo "EXISTS" || echo "MISSING"
```

- [ ] `projects-created.md` EXISTS
- [ ] `remove-project.md` EXISTS

### 18.4 Command Count is 23

```bash
ls .claude/commands/ | wc -l
```

- [ ] Total: 23 files

### 18.5 New Profiles in Config

```bash
cat claude-mastery-project.conf
```

- [ ] `[vue]` profile exists
- [ ] `[nuxt]` profile exists
- [ ] `[svelte]` profile exists
- [ ] `[sveltekit]` profile exists
- [ ] `[angular]` profile exists
- [ ] `[python-api]` profile exists — `language = python`, `framework = fastapi`
- [ ] `[django]` profile exists — `language = python`, `framework = django`
- [ ] `[flask]` profile exists — `language = python`, `framework = flask`
- [ ] Total profiles: 15 (7 existing + 8 new)

### 18.6 Documentation Sync

- [ ] `help.md` lists `/set-project-profile-default` and `/add-project-setup`
- [ ] `help.md` lists `/projects-created` and `/remove-project`
- [ ] `help.md` does NOT list `/set-clean-as-default` or `/reset-to-defaults`
- [ ] `help.md` header says "23 commands"
- [ ] `CLAUDE.md` quick reference has all new commands (including `/projects-created`, `/remove-project`, `/convert-project-to-starter-kit`)
- [ ] `README.md` says "23 Slash Commands" and lists all new commands
- [ ] `docs/index.html` says "23 Slash Commands" and has command cards for all new commands
- [ ] "Supported Technologies" section in README.md
- [ ] "Supported Technologies" section in docs/index.html
- [ ] Project structure trees in README.md and docs/index.html include `projects-created.md`, `remove-project.md`, and `convert-project-to-starter-kit.md`

### 18.7 Project Registry

- [ ] `/projects-created` reads from `~/.claude/starter-kit-projects.json`
- [ ] `/remove-project` reads and writes `~/.claude/starter-kit-projects.json`
- [ ] `/new-project` has a "Project Registry" section that writes to `~/.claude/starter-kit-projects.json`

---

## Section 19: /convert-project-to-starter-kit Verification

> Verify the convert command merges starter kit infrastructure into an existing project non-destructively.

### 19.1 Create Test Target

```bash
mkdir /tmp/test-convert && cd /tmp/test-convert && git init && touch README.md && git add . && git commit -m "init"
```

- [ ] Test repo created with initial commit

### 19.2 Run Conversion

In Claude Code (from the starter kit directory), run:

```
/convert-project-to-starter-kit /tmp/test-convert
```

### 19.3 Verify Pre-Conversion Commit

```bash
cd /tmp/test-convert && git log --oneline | head -5
```

- [ ] Pre-conversion commit exists ("chore: pre-conversion snapshot" or "chore: pre-conversion marker")
- [ ] Conversion commit exists ("chore: merge Claude Code Starter Kit infrastructure")

### 19.4 Verify Commands Copied

```bash
ls /tmp/test-convert/.claude/commands/ | wc -l
```

- [ ] `.claude/commands/` has 23 files

### 19.5 Verify Hooks Copied

```bash
ls /tmp/test-convert/.claude/hooks/ | wc -l
```

- [ ] `.claude/hooks/` has 9 files (block-secrets.py + 8 .sh hooks)
- [ ] All `.sh` files are executable: `ls -la /tmp/test-convert/.claude/hooks/*.sh`

### 19.6 Verify Skills and Agents Copied

- [ ] `.claude/skills/code-review/SKILL.md` exists
- [ ] `.claude/skills/create-service/SKILL.md` exists
- [ ] `.claude/agents/code-reviewer.md` exists
- [ ] `.claude/agents/test-writer.md` exists

### 19.7 Verify CLAUDE.md Created

```bash
cat /tmp/test-convert/CLAUDE.md
```

- [ ] CLAUDE.md exists with security-only rules (Rule 0, Rule 5, Rule 6)
- [ ] Has "NEVER Publish Sensitive Data" section
- [ ] Has "NEVER Hardcode Credentials" section
- [ ] Has "ALWAYS Ask Before Deploying" section

### 19.8 Verify settings.json

```bash
cat /tmp/test-convert/.claude/settings.json | python3 -m json.tool
```

- [ ] `.claude/settings.json` exists and is valid JSON
- [ ] Has hooks wired for PreToolUse, PostToolUse, and Stop

### 19.9 Verify Infrastructure Files

- [ ] `CLAUDE.local.md` exists
- [ ] `claude-mastery-project.conf` exists
- [ ] `project-docs/ARCHITECTURE.md` exists
- [ ] `project-docs/INFRASTRUCTURE.md` exists
- [ ] `project-docs/DECISIONS.md` exists
- [ ] `.gitignore` exists and includes `.env`
- [ ] `.env.example` exists

### 19.10 Verify Project Registry

```bash
cat ~/.claude/starter-kit-projects.json | python3 -m json.tool
```

- [ ] Registry has an entry with `"path": "/tmp/test-convert"`
- [ ] Entry has `"profile": "converted"`
- [ ] `/projects-created` shows the converted project

### 19.11 Verify Revert Works

```bash
cd /tmp/test-convert && git revert HEAD --no-edit
```

- [ ] `git revert HEAD` completes cleanly
- [ ] `.claude/commands/` no longer exists (reverted to pre-conversion state)

### 19.12 Cleanup

```bash
rm -rf /tmp/test-convert
```

- [ ] Test project removed

---

## Section 20: Cleanup (Extended)

After completing all tests:

```bash
rm -rf ~/projects/TESTPROJECT
rm -rf ~/projects/TESTPROJECT-CLEAN
rm -rf ~/projects/TESTPROJECT-GO
rm -rf ~/projects/TESTPROJECT-PYTHON
rm -rf /tmp/test-convert
```

- [ ] Test projects removed

---

## Results Summary

| Section | Total Checks | Passed | Failed | Notes |
|---------|-------------|--------|--------|-------|
| 1. Source Files | | | | |
| 2. Package.json Scripts | | | | |
| 3. TypeScript Config | | | | |
| 4. Playwright Config | | | | |
| 5. Vitest Config | | | | |
| 6. Security | | | | |
| 7. Project Conf | | | | |
| 8. E2E Template | | | | |
| 9. DB Wrapper Compiles | | | | |
| 10. Content System | | | | |
| 11. DB Query System | | | | |
| 12. CLAUDE.md Completeness | | | | |
| 13. /new-project default | | | | |
| 14. /new-project clean | | | | |
| 15. /new-project go | | | | |
| 16. SQL Wrapper | | | | |
| 17. /new-project python | | | | |
| 18. New Commands | | | | |
| 19. Convert Command | | | | |
| 20. Cleanup | | | | |
| **TOTAL** | | | | |

**Tested by:** _______________
**Date:** _______________
**Starter Kit Version:** _______________
