---
description: List all available commands and skills
scope: project
allowed-tools: Read, Glob
---

# Help — All Available Commands

Display the complete list of commands and skills available in this project.

## Step 1 — Detect Context

Determine if we're running inside the starter kit or a scaffolded project:

1. Check if BOTH `claude-mastery-project.conf` AND `.claude/commands/new-project.md` exist in the project root
   - **Yes** → This is the **starter kit**. Show ALL commands (both `scope: project` and `scope: starter-kit`), grouped with a "KIT MANAGEMENT" section.
   - **No** → This is a **scaffolded project**. Show only the commands present in `.claude/commands/`.

## Step 2 — Enumerate Commands

1. Glob `.claude/commands/*.md` to find all command files
2. For each file, read the YAML frontmatter to extract:
   - `description` — the command description
   - `scope` — `project` or `starter-kit` (if present)
3. Build the command list dynamically from what's actually installed

## Step 3 — Display

Format the output as a grouped reference. Use the categories below for organization.

### If Starter Kit (show all commands with KIT MANAGEMENT section):

```
=== Claude Code Starter Kit — Command Reference ({N} commands) ===

GETTING STARTED
  /help              List all commands and skills (this screen)
  /quickstart        Interactive first-run walkthrough for new users
  /install-global    Install/merge global Claude config into ~/.claude/
  /setup             Interactive .env configuration — GitHub, database, Docker, analytics
  /setup --reset     Re-configure everything from scratch
  /show-user-guide   Open the comprehensive User Guide in your browser

KIT MANAGEMENT (starter kit only — not copied to projects)
  /new-project       Scaffold a new project from a profile (clean, default, api, go, vue, python-api, etc.)
  /set-project-profile-default  Set the default profile for /new-project (any profile name)
  /add-project-setup  Interactive wizard to create a named profile in claude-mastery-project.conf
  /projects-created  List all projects created by the starter kit with creation dates
  /remove-project    Remove a project from the registry and optionally delete it from disk
  /convert-project-to-starter-kit  Merge starter kit into an existing project (non-destructive)
  /update-project    Update a starter-kit project with the latest commands, hooks, and rules
  /update-project --clean  Remove starter-kit-scoped commands from a project

CODE QUALITY
  /review            Systematic code review against 7-point checklist
  /refactor <file>   Audit + refactor a file against all CLAUDE.md rules
  /security-check    Scan project for secrets, vulnerabilities, and .gitignore gaps
  /commit            Smart commit with conventional commit format

DEVELOPMENT
  /create-api <res>  Scaffold a full API endpoint — route, handler, types, tests
  /create-e2e <feat> Generate Playwright E2E test with explicit success criteria
  /test-plan         Generate a structured test plan for a feature
  /progress          Check project status — files, tests, git activity, next actions

INFRASTRUCTURE
  /diagram <type>    Generate diagrams from code: architecture, api, database, infrastructure, all
  /architecture      Display system architecture and data flow
  /optimize-docker   Audit Dockerfile against 12 production best practices
  /worktree <name>   Create isolated branch + worktree for a task

MONITORING
  /what-is-my-ai-doing   Live monitor of AI activity — tokens, cost, violations
```

### If Scaffolded Project (show only installed commands):

```
=== Command Reference ({N} commands) ===
```

Group installed commands into the same categories (GETTING STARTED, CODE QUALITY, DEVELOPMENT, INFRASTRUCTURE, MONITORING). Skip any category that has no installed commands. Use the descriptions from the frontmatter.

### Always append (both contexts):

```
=== Skills ===

Auto-activate when Claude detects the work — no command needed:

  API Conventions    Triggers: writing routes, handlers, or adapters
                     Service structure — routing, layering, where code lives
  MongoDB Rules      Triggers: queries, aggregations, indexes, connections, schema
                     Driver, StrictDB, and data-modeling rules for MongoDB
  Code Review        Triggers: "review", "audit", "check code", "security review"
                     Systematic review with severity-rated, cited findings (read-only)
  Debugger           Triggers: "crash", "stack trace", "fails in prod", "root cause"
                     Diagnoses failures by root cause, not symptom (read-only)
  Design Review      Triggers: "review UI", "layout", "accessibility", "does this look right"
                     Critiques UI/UX for usability, accessibility, distinctiveness (read-only)
  Test Writer        Triggers: "write tests", "add a test", "cover this"
                     Writes tests that catch bugs, with explicit assertions
  Dependency Vetting Triggers: "is this package safe", "should I add", "can I trust"
                     Vets a package for supply-chain risk before you install it (read-only)

Invoke explicitly (they write files):

  Create Service     Triggers: "create service", "new service", "scaffold service"
                     Scaffolds a microservice with server/handlers/adapters pattern
  MCP Builder        Triggers: "MCP server", "expose as tools", "wrap this API"
                     Builds an MCP server with well-designed tools and evals

=== Tips ===

  For detailed help on any command: ask "How do I use /command-name?"
  First time here? Run /quickstart for a guided walkthrough.
  Use /help anytime to see this list again.
```

**Note:** Only show the Skills section if `.claude/skills/` exists and contains files.
