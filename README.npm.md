# @claude-code-mastery/starter-kit

A Claude Code toolkit that installs 27 commands, 11 skills, 10 hooks, and scaffolding templates into Claude Code globally - so every project you open already has them available.

**Requires:** Node.js 20+ and [Claude Code](https://claude.ai/code)

---

## Install

```bash
npx @claude-code-mastery/starter-kit init
```

That's the only command you need to run once. Everything else happens inside Claude Code.

---

## What gets installed

After `init`, your `~/.claude/` directory looks like this:

```
~/.claude/
├── starter-kit/                  <- package files live here (single source of truth)
│   ├── commands/                 <- 27 slash commands
│   ├── hooks/                    <- 10 lifecycle hooks
│   ├── skills/                   <- 11 skill files
│   └── .starter-kit/             <- scaffolding templates for /new-project
├── commands/
│   ├── new-project.md  -> (symlink to starter-kit/commands/new-project.md)
│   ├── review.md       -> (symlink to starter-kit/commands/review.md)
│   └── ...             -> one symlink per command
├── skills/
│   ├── code-review/    -> (symlink to starter-kit/skills/code-review/)
│   └── ...
└── settings.json       <- hooks registered with absolute paths
```

Commands and skills are **symlinked**, not copied. When you update the package, the symlinks point to the new files immediately - no re-linking needed.

Hooks are registered by absolute path in `~/.claude/settings.json`, which is the same pattern Claude Code uses for its own global configuration.

---

## Commands

Once installed, these slash commands are available in every Claude Code session:

| Command | What it does |
|---|---|
| `/new-project <name> [profile]` | Scaffold a new project with full Claude Code tooling |
| `/convert-project-to-starter-kit` | Add kit infrastructure to an existing project (non-destructive) |
| `/add-feature <capability>` | Add MongoDB, Docker, testing, etc. to an existing project |
| `/review` | Review code for bugs, security issues, and best practices |
| `/commit` | Generate a conventional commit message from staged changes |
| `/create-api <resource>` | Scaffold a full API endpoint with route, handler, types, and tests |
| `/create-e2e <feature>` | Create a Playwright E2E test with explicit success criteria |
| `/refactor <file>` | Refactor a file following project best practices |
| `/security-check` | Scan for exposed secrets, missing .gitignore entries, unsafe patterns |
| `/optimize-docker` | Audit a Dockerfile against 12 best practices |
| `/diagram <type>` | Generate architecture, API, database, or infrastructure diagrams |
| `/worktree <name>` | Create an isolated git worktree and branch for a task |
| `/setup` | Configure .env, GitHub, Docker, analytics, and services interactively |
| `/test-plan <feature>` | Generate a structured test plan |
| `/progress` | Show what's done, pending, and next in the project |
| `/starter-kit update` | Update to the latest version from npm |
| `/starter-kit status` | Show installed version vs latest |
| `/starter-kit add` | Install the kit into the current project's .claude/ directory |

---

## Skills

Skills are expertise files Claude loads when relevant. These install automatically:

- `code-review` - security, performance, and correctness checks with severity rankings
- `test-writer` - tests with explicit assertions and realistic data
- `debugger` - root cause diagnosis for crashes, stack traces, and intermittent bugs
- `dependency-vetting` - supply-chain risk assessment before adding a package
- `design-review` - usability, accessibility, and visual feedback on UI
- `mongodb-rules` - native-driver and StrictDB rules for MongoDB data access
- `api-conventions` - routing and layering conventions for service code
- `create-service` - scaffolding patterns for new services
- `mcp-builder` - MCP server development patterns
- `terminal-tui` - Ink + React TUI patterns, resize handling
- `schema-source-of-truth` - one canonical Zod schema per entity, derived across all layers; catches the same shape defined four times drift

---

## Hooks

Hooks fire automatically during Claude Code sessions:

| Hook | When it fires | What it does |
|---|---|---|
| `check-branch.sh` | Before commit | Blocks commits directly to main |
| `check-rybbit.sh` | Before deploy commands | Ensures analytics are configured |
| `check-ports.sh` | Before starting servers | Checks for port conflicts |
| `check-e2e.sh` | Before E2E tests | Validates test configuration |
| `check-env-sync.sh` | After editing .env | Flags when .env.example is out of sync |
| `check-rulecatch.sh` | After commits | Runs RuleCatch violation checks |
| `block-dangerous-bash.py` | Before Bash tool | Blocks destructive shell commands |
| `check-file-length.py` | After Write/Edit | Warns when files exceed 300 lines |
| `lint-on-save.sh` | After Write/Edit | Runs linter on changed files |
| `verify-no-secrets.sh` | Before commit | Scans staged files for secrets |

---

## How Claude Code discovers the installed content

Claude Code does not scan `node_modules/`. Instead it looks in specific directories:

| Content type | Where Claude Code looks |
|---|---|
| Commands | `~/.claude/commands/` and `<project>/.claude/commands/` |
| Skills | `~/.claude/skills/` and `<project>/.claude/skills/` |
| Hooks | Absolute paths registered in `~/.claude/settings.json` |

After `init`, the package files live in `~/.claude/starter-kit/` and are exposed via symlinks and hook registrations in exactly the places Claude Code already checks. No configuration changes to Claude Code are needed.

---

## Updating

```bash
npx @claude-code-mastery/starter-kit update
```

Or from inside Claude Code after the first install:

```
/starter-kit update
```

This overwrites `~/.claude/starter-kit/` with the latest package content. Because commands and skills are symlinked, they reflect the update without any re-linking step.

---

## Adding to a specific project

To give a project its own local copy of the commands and hooks (useful for team repos):

```
/starter-kit add
```

This copies from `~/.claude/starter-kit/` into the current project's `.claude/` directory. Existing files are not overwritten.

---

## Checking what's installed

```bash
npx @claude-code-mastery/starter-kit status
```

Or from Claude Code:

```
/starter-kit status
```

---

## Profiles for /new-project

The `/new-project` command uses profiles to scaffold different project types:

| Profile | What it creates |
|---|---|
| `clean` | Minimal structure - just the Claude Code tooling, no framework |
| `node` (default) | Node.js + TypeScript, Express or similar, StrictDB |
| `go` | Go project with standard layout, golangci-lint, Makefile |
| `python` | Python + FastAPI or Django, pytest, ruff, Pydantic |

```bash
# Examples inside Claude Code:
/new-project my-api node
/new-project my-service go
/new-project my-site clean
```

---

## Source and contributing

The package content lives in the starter kit repo:
[github.com/TheDecipherist/claude-code-mastery-project-starter-kit](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit)

Clone the repo to customize commands, hooks, or skills for your own team, or fork it and publish under your own org.
