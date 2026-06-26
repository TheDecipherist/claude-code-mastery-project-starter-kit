---
description: Create a new project with all scaffolding rules applied
scope: starter-kit
argument-hint: <path> [profile-or-options...]
allowed-tools: Bash, Write, Read, AskUserQuestion
---

# New Project Scaffold

Create a new project with all best practices from the Claude Code Mastery Guides.

**Arguments:** $ARGUMENTS

## Argument Parsing

### Step 0 — Read the config file

Before parsing arguments, read `claude-mastery-project.conf` (in the starter kit root or `~/.claude/claude-mastery-project.conf` as fallback).

Extract the `[global]` section for `root_dir` and `default_profile`.

- `root_dir` — Default parent directory for new projects
- `default_profile` — Profile to use when no profile is specified in arguments (e.g., `default_profile = clean`). If not set, ask the user as before.

### Step 0.0 — Global Claude Config (one-time setup)

Check if the user already has the global Claude config installed:

```bash
# Check if global CLAUDE.md exists
ls ~/.claude/CLAUDE.md 2>/dev/null
```

**If `~/.claude/CLAUDE.md` does NOT exist:**
- ASK: "You don't have a global CLAUDE.md yet. Want me to install the Claude Code Mastery global config to `~/.claude/`? This sets up security rules, hooks, and standards that apply to ALL your projects. (This is a one-time setup.)"
- If yes: copy `global-claude-md/CLAUDE.md` → `~/.claude/CLAUDE.md` and `global-claude-md/settings.json` → `~/.claude/settings.json`
- Also copy hooks: `mkdir -p ~/.claude/hooks && cp .claude/hooks/verify-no-secrets.sh ~/.claude/hooks/`

**If `~/.claude/CLAUDE.md` DOES exist:**
- ASK: "You already have a global CLAUDE.md. Want me to check if the starter kit version has anything new to merge in?"
- If yes: diff the two files and show what's different. Let the user decide what to merge.
- If no: skip and continue.

**This step typically only happens once.** After the first install, the global config persists across all projects.

### Step 0.1 — Resolve the project path

The **first argument** is the project name or path. Resolve it using `root_dir`:

1. **Explicit path** (starts with `./`, `../`, `~/`, or `/`) → use as-is
   - `/new-project ~/code/my-app` → creates at `~/code/my-app`
   - `/new-project ./my-app` → creates at `./my-app`

2. **Just a name** (no path separators) → prepend `root_dir` from `[global]`
   - Config has `root_dir = ~/projects`
   - `/new-project my-app` → creates at `~/projects/my-app`
   - `/new-project tims-api` → creates at `~/projects/tims-api`

3. **No argument at all** → ASK the user for the project name, then prepend `root_dir`

Everything after the project name/path is shorthand options or a profile name.

### Shorthand Arguments (after the path/name)

Parse remaining $ARGUMENTS for these keywords:

**Profiles:** `clean`, `default`, `api`, `static-site`, `quick`, `enterprise`, `go`, `vue`, `nuxt`, `svelte`, `sveltekit`, `angular`, `python-api`, `django`, `flask` (from `claude-mastery-project.conf`)
**Special:** `clean` — Claude infrastructure only, zero coding opinions (see Clean Mode below)
**Languages:** `go`, `golang` (triggers Go scaffolding — see Go Mode below) | `python`, `py` (triggers Python Mode below)
**Project types:** `webapp`, `api`, `fullstack`, `cli`
**Frameworks:** `vite`, `react`, `next`, `nextjs`, `astro`, `fastify`, `express`, `hono`, `vue`, `nuxt`, `svelte`, `sveltekit`, `angular`
**Go Frameworks:** `gin`, `chi`, `echo`, `fiber`, `stdlib`
**Python Frameworks:** `fastapi`, `django`, `flask`
**Options:** `seo`, `ssr`, `tailwind`, `prisma`, `docker`, `ci`, `multiregion`
**Hosting:** `dokploy`, `vercel`, `static`
**Database:** `mongo`, `postgres`, `mysql`, `mssql`, `sqlite`
**Analytics:** `rybbit`
**MCP servers:** `playwright`, `context7`, `rulecatch`
**NPM extras:** `ai-pooler` (installs @rulecatch/ai-pooler)
**Package managers:** `pnpm`, `npm`, `bun`

Examples:
- `/new-project my-app` — creates at ~/projects/my-app (from root_dir), asks questions
- `/new-project my-app clean` — Claude infrastructure only, no coding opinions
- `/new-project my-app default` — creates at ~/projects/my-app with default profile
- `/new-project my-app fullstack next seo tailwind pnpm` — ~/projects/my-app, skips all questions
- `/new-project ./custom-path/my-app api fastify` — explicit path, ignores root_dir
- `/new-project ~/code/my-app default` — explicit path, uses default profile
- `/new-project my-app fullstack next mongo playwright context7 rulecatch` — full stack
- `/new-project my-api go` — Go API with Gin, MongoDB, Docker
- `/new-project my-api go chi postgres` — Go with Chi, PostgreSQL
- `/new-project my-cli go cli` — Go CLI with Cobra
- `/new-project my-app vue` — Vue 3 SPA with Tailwind
- `/new-project my-app nuxt` — Nuxt full-stack with MongoDB, Docker
- `/new-project my-app svelte` — Svelte SPA with Tailwind
- `/new-project my-app sveltekit` — SvelteKit full-stack with MongoDB, Docker
- `/new-project my-app angular` — Angular SPA with Tailwind
- `/new-project my-api python-api` — FastAPI with PostgreSQL, Docker
- `/new-project my-app django` — Django full-stack with PostgreSQL, Docker
- `/new-project my-api flask` — Flask API with PostgreSQL, Docker
- `/new-project my-api python fastapi postgres docker` — Python API with overrides

Any keyword not provided = check `default_profile` in `[global]` first, then ask the user. If `default_profile` is set (e.g., `default_profile = clean`) and no profile was specified in the arguments, use that profile automatically.

---

## Project Registry — MANDATORY Final Step (ALL modes)

**After EVERY successful project scaffold (Clean, Go, Python, or Node.js), register the project in `~/.claude/starter-kit-projects.json`.**

This enables `/projects-created` and `/remove-project` to track all projects.

### How to register

1. Read `~/.claude/starter-kit-projects.json` (create if it doesn't exist)
2. Append a new entry to the `projects` array:

```json
{
  "name": "my-app",
  "path": "/home/user/projects/my-app",
  "profile": "default",
  "language": "node",
  "framework": "next",
  "database": "mongo",
  "createdAt": "2025-01-15T10:30:00Z"
}
```

3. Write the updated file back

**Field mapping:**
- `name` — project directory name (last segment of path)
- `path` — absolute path to the project directory
- `profile` — profile name used (e.g., `clean`, `default`, `go`, `python-api`), or `custom` if built from shorthand args
- `language` — `node`, `go`, or `python`
- `framework` — the chosen framework (e.g., `next`, `gin`, `fastapi`), or `none` for clean mode
- `database` — `mongo`, `postgres`, `mysql`, `mssql`, `sqlite`, or `none`
- `createdAt` — ISO 8601 timestamp of creation

**If the file doesn't exist yet**, create it with:

```json
{
  "projects": []
}
```

**This step happens AFTER git init and initial commit, as the very last action before displaying the verification checklist.**

---


---

## Route to the Profile

The detailed scaffolding lives in `.claude/.starter-kit/`, split so only the parts a run actually needs are loaded. Based on the resolved mode/language, read the matching profile file and follow it exactly:

| Mode / language | Read and follow |
| --- | --- |
| `clean` | `.claude/.starter-kit/profiles/clean.md` |
| `go` / `golang` / `gin`, `chi`, `echo`, `fiber`, `stdlib` | `.claude/.starter-kit/profiles/go.md` |
| `python` / `py` / `fastapi`, `django`, `flask` | `.claude/.starter-kit/profiles/python.md` |
| default / `node` / any JS-TS framework | `.claude/.starter-kit/profiles/node.md` |

Read exactly one profile, the one the mode/language resolves to. Do NOT read the others.

`.claude/.starter-kit/` is kit-internal scaffolding source. It is read while running `/new-project`, but it is **never copied into the scaffolded project** (the new project doesn't have `/new-project`). Copy only `skills/`, `hooks/`, `settings.json`, and `scope: project` commands, as the steps below specify.

Every profile except `clean` builds its CLAUDE.md from `.claude/.starter-kit/shared/claude-md-base.md` plus its own rules; read the base first. For `clean`, the base *is* the CLAUDE.md.

## Load Only the Shared Modules the Choices Require

After the profile, read only the shared modules the user's selections call for, nothing more:

| If the user selected | Also read and apply |
| --- | --- |
| a SQL database (`postgres`, `mysql`, `mssql`, `sqlite`) | `.claude/.starter-kit/shared/sql-setup.md` |
| `mongo` | `.claude/.starter-kit/shared/mongo-setup.md` |
| a web (HTML-serving) project | `.claude/.starter-kit/shared/seo.md` |
| Dokploy hosting | `.claude/.starter-kit/shared/deployment-dokploy.md` |
| Rybbit analytics | `.claude/.starter-kit/shared/analytics-rybbit.md` |
| MCP servers or AI-Pooler | `.claude/.starter-kit/shared/mcp-and-pooler.md` |

Profile presets (the `claude-mastery-project.conf` format) are documented in `.claude/.starter-kit/shared/profile-config.md`; read it only when creating or resolving a profile.

**Example:** a `node` + `mongo` run reads `profiles/node.md`, `shared/claude-md-base.md`, `shared/mongo-setup.md`, and `shared/seo.md`. It never loads `go.md` or `python.md`.

## Feature Manifest — MANDATORY Final Step (ALL modes except Clean)

Follow `.claude/.starter-kit/shared/feature-manifest.md` to map the scaffolding choices to features and write the project's feature manifest.

## Verification Checklist

After creation, verify and report:

**Core files:**
- [ ] .env exists (empty)
- [ ] .env.example exists (with placeholders)
- [ ] .gitignore includes all required entries
- [ ] .dockerignore exists
- [ ] CLAUDE.md has all required sections (overview, stack, commands, ports)
- [ ] package.json has ALL required scripts (dev, build, test, test:e2e, test:kill-ports)
- [ ] Error handlers in entry point (gracefulShutdown for StrictDB projects)
- [ ] TypeScript strict mode enabled

**Testing:**
- [ ] vitest.config.ts created and configured
- [ ] playwright.config.ts created with test ports (4000/4010/4020) and webServer
- [ ] test:kill-ports script kills test ports BEFORE E2E runs
- [ ] tests/e2e/ directory exists
- [ ] tests/unit/ directory exists
- [ ] Example E2E test has minimum 3 assertions (URL, element, data)
- [ ] `pnpm test` runs unit + E2E in sequence

**Web projects:**
- [ ] SEO meta tags in layout/head
- [ ] JSON-LD structured data included
- [ ] robots.txt created

**Infrastructure:**
- [ ] Dockerfile with multi-stage build (Docker projects)
- [ ] scripts/deploy.sh created (Dokploy projects)
- [ ] Multi-region deploy script (if multiregion selected)

**Database (StrictDB projects):**
- [ ] StrictDB installed as dependency
- [ ] scripts/db-query.ts — Test Query Master
- [ ] scripts/queries/ directory
- [ ] db-query rules in CLAUDE.md

**Content (if web project with articles/posts):**
- [ ] scripts/build-content.ts
- [ ] scripts/content.config.json
- [ ] content/ directory

**Extras:**
- [ ] MCP servers installed (if selected)
- [ ] claude-mastery-project.conf created (if using profiles)
- [ ] No file > 300 lines
- [ ] All independent awaits use Promise.all

Report any missing items.
