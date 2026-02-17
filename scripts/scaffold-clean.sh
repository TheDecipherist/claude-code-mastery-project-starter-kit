#!/usr/bin/env bash
# scaffold-clean.sh — Fast batch scaffold for clean mode projects
# Replaces ~15 individual tool calls with a single script execution
#
# Usage: bash scripts/scaffold-clean.sh <project-path> <project-name> <starter-kit-root>
#
# Creates a complete clean-mode project with progress indicators.

set -euo pipefail

# ── Arguments ──────────────────────────────────────────────────────────────────
PROJECT_PATH="$1"
PROJECT_NAME="$2"
STARTER_KIT="$3"
REGISTRY="${HOME}/.claude/starter-kit-projects.json"

# ── Validation ─────────────────────────────────────────────────────────────────
if [ -d "$PROJECT_PATH" ]; then
  echo "ERROR: Directory already exists: $PROJECT_PATH"
  echo "Remove it first or choose a different name."
  exit 1
fi

if [ ! -d "$STARTER_KIT/.claude/commands" ]; then
  echo "ERROR: Starter kit not found at: $STARTER_KIT"
  exit 1
fi

# ── Progress Tracking ──────────────────────────────────────────────────────────
TOTAL_STEPS=8
CURRENT=0
START_NS=$(date +%s%N)

progress() {
  CURRENT=$((CURRENT + 1))
  local pct=$((CURRENT * 100 / TOTAL_STEPS))
  local now_ns=$(date +%s%N)
  local elapsed_ms=$(( (now_ns - START_NS) / 1000000 ))

  # Progress bar (20 chars)
  local filled=$((pct / 5))
  local empty=$((20 - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="\xe2\x96\x88"; done
  for ((i=0; i<empty; i++)); do bar+="\xe2\x96\x91"; done

  # Estimated time remaining
  local eta=""
  if [ "$CURRENT" -eq "$TOTAL_STEPS" ]; then
    eta="Done!"
  elif [ "$elapsed_ms" -gt 0 ] && [ "$CURRENT" -gt 0 ]; then
    local ms_per_step=$((elapsed_ms / CURRENT))
    local remaining_ms=$(( (TOTAL_STEPS - CURRENT) * ms_per_step ))
    if [ "$remaining_ms" -ge 1000 ]; then
      local remaining_s=$((remaining_ms / 1000))
      local remaining_frac=$(( (remaining_ms % 1000) / 100 ))
      eta="~${remaining_s}.${remaining_frac}s remaining"
    else
      eta="~${remaining_ms}ms remaining"
    fi
  else
    eta="estimating..."
  fi

  printf "[%d/%d] %3d%%  $(echo -e "$bar")  %-40s %s\n" \
    "$CURRENT" "$TOTAL_STEPS" "$pct" "$1" "$eta"
}

# ── Header ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEW PROJECT: $PROJECT_NAME (clean mode)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 1: Create directories ─────────────────────────────────────────────────
progress "Creating directory structure..."
mkdir -p "$PROJECT_PATH"/.claude/{commands,skills,agents,hooks}
mkdir -p "$PROJECT_PATH"/project-docs
mkdir -p "$PROJECT_PATH"/tests

# ── Step 2: Copy 16 project-scoped commands ────────────────────────────────────
progress "Copying 16 project commands..."
for cmd in architecture commit create-api create-e2e diagram help \
           optimize-docker progress refactor review security-check \
           setup show-user-guide test-plan what-is-my-ai-doing worktree; do
  cp "$STARTER_KIT/.claude/commands/${cmd}.md" "$PROJECT_PATH/.claude/commands/"
done

# ── Step 3: Copy skills, agents, hooks ─────────────────────────────────────────
progress "Copying skills, agents, hooks..."
cp -r "$STARTER_KIT/.claude/skills/code-review" "$PROJECT_PATH/.claude/skills/"
cp -r "$STARTER_KIT/.claude/skills/create-service" "$PROJECT_PATH/.claude/skills/"
cp "$STARTER_KIT/.claude/agents/code-reviewer.md" "$PROJECT_PATH/.claude/agents/"
cp "$STARTER_KIT/.claude/agents/test-writer.md" "$PROJECT_PATH/.claude/agents/"
cp "$STARTER_KIT/.claude/hooks/block-secrets.py" "$PROJECT_PATH/.claude/hooks/"
cp "$STARTER_KIT/.claude/hooks/lint-on-save.sh" "$PROJECT_PATH/.claude/hooks/"
cp "$STARTER_KIT/.claude/hooks/verify-no-secrets.sh" "$PROJECT_PATH/.claude/hooks/"

# ── Step 4: Write settings.json (clean mode — 3 hooks only) ───────────────────
progress "Writing settings.json..."
cat > "$PROJECT_PATH/.claude/settings.json" << 'SETTINGS_EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/block-secrets.py"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/lint-on-save.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/verify-no-secrets.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF

# ── Step 5: Create CLAUDE.md + CLAUDE.local.md ────────────────────────────────
progress "Creating CLAUDE.md files..."

cat > "$PROJECT_PATH/CLAUDE.md" << 'CLAUDEMD_EOF'
# CLAUDE.md — Project Instructions

---

## Critical Rules

### 0. NEVER Publish Sensitive Data

- NEVER commit passwords, API keys, tokens, or secrets to git/npm/docker
- NEVER commit `.env` files — ALWAYS verify `.env` is in `.gitignore`
- Before ANY commit: verify no secrets are included
- NEVER output secrets in suggestions, logs, or responses

### 1. NEVER Hardcode Credentials

- ALWAYS use environment variables for secrets
- NEVER put API keys, passwords, or tokens directly in code
- NEVER hardcode connection strings — use environment variables from .env

### 2. ALWAYS Ask Before Deploying

- NEVER auto-deploy, even if the fix seems simple
- NEVER assume approval — wait for explicit "yes, deploy"
- ALWAYS ask before deploying to production

---

## When Something Seems Wrong

Before jumping to conclusions:

- Missing UI element? → Check feature gates BEFORE assuming bug
- Empty data? → Check if services are running BEFORE assuming broken
- 404 error? → Check service separation BEFORE adding endpoint
- Auth failing? → Check which auth system BEFORE debugging
- Test failing? → Read the error message fully BEFORE changing code

---

## Project Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| `project-docs/ARCHITECTURE.md` | System overview & data flow | Before architectural changes |
| `project-docs/INFRASTRUCTURE.md` | Deployment details | Before environment changes |
| `project-docs/DECISIONS.md` | Architectural decisions | Before proposing alternatives |

**ALWAYS read relevant docs before making cross-service changes.**

---

## Git Workflow — Branch FIRST, Work Second

**Auto-branch hook is ON by default.** A hook blocks commits to `main`. **ALWAYS check and branch BEFORE editing any files:**

```bash
# MANDATORY first step — do this BEFORE writing or editing anything:
git branch --show-current
# If on main → create a feature branch IMMEDIATELY:
git checkout -b feat/<task-name>
# NOW start working.
```

If you edit files on `main` and then try to commit, the hook will block you. Branch first — it takes 1 second and avoids wasted work.

---

## Workflow Preferences

- Quality over speed — if unsure, ask before executing
- One task, one chat — `/clear` between unrelated tasks
- When testing: queue observations, fix in batch (not one at a time)

---

## Naming — NEVER Rename Mid-Project

If you must rename packages, modules, or key variables:

1. Create a checklist of ALL files and references first
2. Use IDE semantic rename (not search-and-replace)
3. Full project search for old name after renaming
4. Check: .md files, .txt files, .env files, comments, strings, paths
5. Start a FRESH Claude session after renaming
CLAUDEMD_EOF

cat > "$PROJECT_PATH/CLAUDE.local.md" << 'LOCALMD_EOF'
# CLAUDE.local.md — Personal Overrides

> **This file is gitignored.** It's for YOUR personal preferences — things that shouldn't be shared with the team.
>
> **When to use this vs CLAUDE.md:**
> - `CLAUDE.md` = team rules (checked into git, everyone follows them)
> - `CLAUDE.local.md` = personal preferences (gitignored, only affects you)

---

## My Identity

- GitHub: YourUsername
- SSH: `git@github.com:YourUsername/<repo>.git`

## Communication Style

<!-- Uncomment the style that fits you: -->
<!-- - Respond concisely — I prefer terse explanations -->
<!-- - Be thorough — explain your reasoning in detail -->
<!-- - Show me the code first, explain after -->
<!-- - Always explain trade-offs before making a choice -->

## Commit Preferences

- When creating commits, use conventional commit format (feat:, fix:, docs:, etc.)

## Testing Preferences

<!-- Uncomment what matches your workflow: -->
<!-- - Run tests after every code change automatically -->
<!-- - Only run tests when I ask -->
<!-- - Always run E2E tests headed so I can watch -->
<!-- - Prefer unit tests over E2E for new features -->

## Deployment Preferences

<!-- Uncomment what matches your workflow: -->
<!-- - Always ask before deploying (default CLAUDE.md behavior) -->
<!-- - Deploy to staging automatically, ask before production -->
<!-- - I handle deployments myself — just build and test -->

## Code Style

<!-- Uncomment what matches your preferences: -->
<!-- - I prefer named exports over default exports -->
<!-- - Use arrow functions for React components -->
<!-- - Prefer early returns over nested if/else -->
<!-- - Use verbose variable names, never abbreviate -->

## Local Environment

- Node version: 20.x
- Package manager: (your choice)
- OS: (your OS here)

## Project-Specific Notes

<!-- Add anything specific to how YOU work on this project -->
LOCALMD_EOF

# ── Step 6: Create project templates ──────────────────────────────────────────
progress "Creating project templates..."

cat > "$PROJECT_PATH/project-docs/ARCHITECTURE.md" << 'ARCH_EOF'
# Architecture

> System overview and data flow for the project.

## Overview

<!-- Describe the high-level architecture here -->

## Components

<!-- List major components and their responsibilities -->

## Data Flow

<!-- Describe how data moves through the system -->

## Dependencies

<!-- List external services and dependencies -->
ARCH_EOF

cat > "$PROJECT_PATH/project-docs/INFRASTRUCTURE.md" << 'INFRA_EOF'
# Infrastructure

> Deployment and environment details.

## Environments

<!-- List environments: development, staging, production -->

## Deployment

<!-- Describe the deployment process -->

## Environment Variables

<!-- List required environment variables and their purpose -->

## Monitoring

<!-- Describe monitoring and alerting setup -->
INFRA_EOF

cat > "$PROJECT_PATH/project-docs/DECISIONS.md" << 'DEC_EOF'
# Architectural Decisions

> Record of key technical decisions and their rationale.

## Template

### Decision: [Title]
- **Date:** YYYY-MM-DD
- **Status:** Accepted / Superseded / Deprecated
- **Context:** What prompted the decision
- **Decision:** What was decided
- **Consequences:** What are the trade-offs
- **Alternatives considered:** What else was evaluated

---

<!-- Add decisions below -->
DEC_EOF

cat > "$PROJECT_PATH/tests/CHECKLIST.md" << 'CHECK_EOF'
# Test Checklist

> Track what needs testing and what's been verified.

## Test Coverage

| Area | Unit Tests | Integration Tests | E2E Tests | Status |
|------|-----------|-------------------|-----------|--------|
| <!-- feature --> | <!-- yes/no --> | <!-- yes/no --> | <!-- yes/no --> | <!-- pending/done --> |

## Manual Test Cases

- [ ] <!-- Describe manual test case -->

## Regression Tests

- [ ] <!-- Describe regression test case -->
CHECK_EOF

cat > "$PROJECT_PATH/tests/ISSUES_FOUND.md" << 'ISSUES_EOF'
# Issues Found During Testing

> Track bugs and issues discovered during testing sessions.

## Template

### Issue: [Title]
- **Found:** YYYY-MM-DD
- **Severity:** Critical / High / Medium / Low
- **Status:** Open / Fixed / Won't Fix
- **Description:** What happened
- **Steps to reproduce:** How to trigger the issue
- **Expected behavior:** What should happen
- **Actual behavior:** What actually happened
- **Fix:** How it was resolved (if fixed)

---

<!-- Add issues below -->
ISSUES_EOF

# ── Step 7: Create config files ───────────────────────────────────────────────
progress "Creating config files (.env, .gitignore, README)..."

touch "$PROJECT_PATH/.env"

cat > "$PROJECT_PATH/.env.example" << 'ENVEX_EOF'
# Environment Variables
NODE_ENV=development
PORT=3000
ENVEX_EOF

cat > "$PROJECT_PATH/.gitignore" << 'GI_EOF'
# Environment
.env
.env.*
.env.local

# Dependencies
node_modules/
vendor/
.venv/
__pycache__/

# Build output
dist/
build/
bin/
out/

# Test artifacts
coverage/
test-results/
playwright-report/
.pytest_cache/
htmlcov/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Claude local overrides
CLAUDE.local.md

# Temporary AI research files
_ai_temp/
GI_EOF

cat > "$PROJECT_PATH/.dockerignore" << 'DI_EOF'
.env
.env.*
.git/
node_modules/
dist/
coverage/
test-results/
playwright-report/
.venv/
__pycache__/
*.md
!README.md
_ai_temp/
DI_EOF

cat > "$PROJECT_PATH/README.md" << README_EOF
# $PROJECT_NAME

> Scaffolded with [Claude Code Mastery Starter Kit](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit) (clean mode)

## Getting Started

This project was created with **clean mode** — all Claude Code infrastructure is in place with zero coding opinions. You decide your own language, framework, and structure.

## What's Included

- \`.claude/\` — 16 slash commands, 2 skills, 2 agents, 3 hooks
- \`project-docs/\` — Architecture, Infrastructure, and Decisions templates
- \`tests/\` — Test checklist and issue tracking templates
- \`CLAUDE.md\` — Security rules only (no coding opinions)
- \`.env\` / \`.env.example\` — Environment variable pattern

## Available Commands

Run \`/help\` in Claude Code to see all 16 available commands.

## Project Documentation

| Document | Purpose |
|----------|---------|
| \`project-docs/ARCHITECTURE.md\` | System overview & data flow |
| \`project-docs/INFRASTRUCTURE.md\` | Deployment details |
| \`project-docs/DECISIONS.md\` | Architectural decisions |
README_EOF

# ── Step 8: Git init + register project ───────────────────────────────────────
progress "Initializing git + registering project..."

git -C "$PROJECT_PATH" init -q
git -C "$PROJECT_PATH" add -A
git -C "$PROJECT_PATH" commit -q -m "Initial clean project scaffold"

# Register in project registry
python3 << PYEOF
import json, os
from datetime import datetime, timezone

registry = "$REGISTRY"
if os.path.exists(registry):
    with open(registry) as f:
        data = json.load(f)
else:
    os.makedirs(os.path.dirname(registry), exist_ok=True)
    data = {"projects": []}

data["projects"].append({
    "name": "$PROJECT_NAME",
    "path": os.path.realpath("$PROJECT_PATH"),
    "profile": "clean",
    "language": "none",
    "framework": "none",
    "database": "none",
    "createdAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
})

with open(registry, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

# ── Summary ────────────────────────────────────────────────────────────────────
END_NS=$(date +%s%N)
TOTAL_MS=$(( (END_NS - START_NS) / 1000000 ))
FILE_COUNT=$(find "$PROJECT_PATH" -type f -not -path '*/.git/*' | wc -l)

# Format elapsed time
if [ "$TOTAL_MS" -ge 1000 ]; then
  TOTAL_S=$((TOTAL_MS / 1000))
  TOTAL_FRAC=$(( (TOTAL_MS % 1000) / 100 ))
  TIME_STR="${TOTAL_S}.${TOTAL_FRAC}s"
else
  TIME_STR="${TOTAL_MS}ms"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Completed in ${TIME_STR}"
echo "  Created at: $PROJECT_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ${FILE_COUNT} files  |  16 commands  |  2 skills  |  2 agents  |  3 hooks"
echo ""
echo "  Next steps:"
echo "    cd $PROJECT_PATH"
echo "    claude     # Start Claude Code — run /help to see commands"
echo ""
