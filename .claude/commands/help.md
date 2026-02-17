---
description: List all available commands, skills, and agents
allowed-tools: ""
---

# Help — All Available Commands

Display the complete list of commands, skills, and agents available in this starter kit.

**Print this exactly:**

```
=== Claude Code Starter Kit — Command Reference (25 commands) ===

GETTING STARTED
  /help              List all commands, skills, and agents (this screen)
  /quickstart        Interactive first-run walkthrough for new users
  /install-global    Install/merge global Claude config into ~/.claude/
  /setup             Interactive .env configuration — GitHub, database, Docker, analytics
  /setup --reset     Re-configure everything from scratch
  /show-user-guide   Open the comprehensive User Guide in your browser

PROJECT SCAFFOLD
  /new-project       Scaffold a new project from a profile (clean, default, api, go, vue, python-api, etc.)
  /set-project-profile-default  Set the default profile for /new-project (any profile name)
  /add-project-setup  Interactive wizard to create a named profile in claude-mastery-project.conf
  /projects-created  List all projects created by the starter kit with creation dates
  /remove-project    Remove a project from the registry and optionally delete it from disk
  /convert-project-to-starter-kit  Merge starter kit into an existing project (non-destructive)
  /update-project    Update a starter-kit project with the latest commands, hooks, and rules

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

=== Skills (activate automatically) ===

  Code Review        Triggers: "review", "audit", "check code", "security review"
                     Loads a systematic review checklist with severity-rated findings

  Create Service     Triggers: "create service", "new service", "scaffold service"
                     Scaffolds a microservice with server/handlers/adapters pattern

Skills activate when Claude detects relevant keywords — no command needed.

=== Custom Agents ===

  Code Reviewer      Read-only security & quality audit (Tools: Read, Grep, Glob)
  Test Writer        Creates tests with explicit assertions (Tools: Read, Write, Grep, Glob, Bash)

=== Tips ===

  For detailed help on any command: ask "How do I use /command-name?"
  First time here? Run /quickstart for a guided walkthrough.
  Use /help anytime to see this list again.
```
