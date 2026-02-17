---
description: Install global Claude config — merges into existing ~/.claude/ without overwriting
scope: starter-kit
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# Install Global Config

Install the starter kit's global Claude configuration into `~/.claude/`. This is a one-time setup that gives you security rules, hooks, and settings across ALL projects.

**Smart merge:** If you already have a global config, this merges new content — it never overwrites your existing rules.

## Step 1 — Check What Exists

```bash
# Check if global claude directory exists
ls -la ~/.claude/ 2>/dev/null || echo "NO_GLOBAL_DIR"

# Check for existing files
[ -f ~/.claude/CLAUDE.md ] && echo "EXISTING_CLAUDE_MD" || echo "NO_CLAUDE_MD"
[ -f ~/.claude/settings.json ] && echo "EXISTING_SETTINGS" || echo "NO_SETTINGS"
[ -d ~/.claude/hooks ] && echo "EXISTING_HOOKS" || echo "NO_HOOKS"
```

## Step 2 — Handle Each File

### 2A. ~/.claude/CLAUDE.md

**If NO existing file:**
- Copy `global-claude-md/CLAUDE.md` directly to `~/.claude/CLAUDE.md`
- Report: "Installed global CLAUDE.md (fresh install)"

**If existing file found:**
1. Read BOTH files:
   - The existing `~/.claude/CLAUDE.md`
   - The starter kit's `global-claude-md/CLAUDE.md`
2. Compare section by section. The starter kit has these sections:
   - `## Identity`
   - `## NEVER EVER DO`
   - `## New Project Setup`
   - `## Coding Standards (All Projects)`
   - `## Workflow`
3. For each section:
   - If the section header **already exists** in the user's file → **SKIP** (don't overwrite their version)
   - If the section header **does NOT exist** → **APPEND** it to the end of the user's file
4. Report exactly what was added and what was skipped:
   ```
   Global CLAUDE.md merge:
     ✓ Identity — already exists, skipped
     ✓ NEVER EVER DO — already exists, skipped
     + New Project Setup — added
     + Coding Standards — added
     ✓ Workflow — already exists, skipped
   ```

**IMPORTANT:** NEVER delete or overwrite existing content. Only append missing sections.

### 2B. ~/.claude/settings.json

**If NO existing file:**
- Copy `global-claude-md/settings.json` directly to `~/.claude/settings.json`
- Report: "Installed global settings.json (fresh install)"

**If existing file found:**
1. Read both settings files as JSON
2. Merge the `permissions.deny` array — add any entries from the starter kit that aren't already present
3. Merge the `hooks` object:
   - For `PreToolUse`: add hooks that aren't already present (match by `command` string)
   - For `Stop`: add hooks that aren't already present (match by `command` string)
4. Write the merged result back
5. Report what was added:
   ```
   Global settings.json merge:
     + Added deny rule: Read(.env.production)
     ✓ Hook block-secrets.py — already present, skipped
     + Added Stop hook: verify-no-secrets.sh
   ```

**IMPORTANT:** NEVER remove existing permissions or hooks. Only add missing ones.

### 2C. ~/.claude/hooks/

1. Create `~/.claude/hooks/` if it doesn't exist:
   ```bash
   mkdir -p ~/.claude/hooks
   ```

2. Check if the project has hooks to install:
   ```bash
   ls .claude/hooks/ 2>/dev/null
   ```

3. For each hook file in the project's `.claude/hooks/`:
   - If the file **already exists** at `~/.claude/hooks/` → **SKIP** (don't overwrite)
   - If the file **does NOT exist** → **COPY** it
   - Make all hooks executable: `chmod +x ~/.claude/hooks/*`

4. Report:
   ```
   Global hooks:
     + block-secrets.py — installed
     ✓ verify-no-secrets.sh — already exists, skipped
     + lint-on-save.sh — installed
   ```

## Step 3 — Verify Installation

After all merges, verify:

```bash
echo "=== Global CLAUDE.md ==="
[ -f ~/.claude/CLAUDE.md ] && echo "✓ exists" || echo "✗ MISSING"

echo "=== Global settings.json ==="
[ -f ~/.claude/settings.json ] && echo "✓ exists" || echo "✗ MISSING"

echo "=== Global hooks ==="
ls ~/.claude/hooks/ 2>/dev/null || echo "✗ NO HOOKS"
```

## Step 4 — Report

```
Global Config Installation Complete
====================================

~/.claude/CLAUDE.md:
  [fresh install / merged X new sections / already up to date]

~/.claude/settings.json:
  [fresh install / merged X new rules / already up to date]

~/.claude/hooks/:
  [X hooks installed / X already existed]

Your existing rules were NOT overwritten.
New sections were appended. Review ~/.claude/CLAUDE.md to customize.

TIP: Update the Identity section with your GitHub username:
  ~/.claude/CLAUDE.md → ## Identity
```
