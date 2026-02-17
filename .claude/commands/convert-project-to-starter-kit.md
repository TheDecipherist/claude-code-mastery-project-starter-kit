---
description: Convert an existing project to use the Claude Code Starter Kit — non-destructive merge
argument-hint: <project-path> [--force]
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# Convert Existing Project to Starter Kit

Merge all Claude Code Starter Kit infrastructure (commands, hooks, skills, agents, CLAUDE.md rules, project-docs templates) into an existing project. Non-destructive — preserves everything the user already has.

**Arguments:** $ARGUMENTS

---

## Step 0 — Resolve Source and Target

### Source (starter kit location)

Find the starter kit source directory:

1. If CWD has BOTH `claude-mastery-project.conf` AND `.claude/commands/new-project.md` → use CWD as source
2. Else read `~/.claude/starter-kit-source-path` → verify it still has both files
3. Else ask via AskUserQuestion: "Where is the starter kit cloned?" with a text input

Store as `$SOURCE`.

### Target (existing project)

Parse `$ARGUMENTS` for a path (everything that is not `--force`). Handle `~` expansion and `./` relative paths.

- If a path argument is provided → resolve to absolute path, store as `$TARGET`
- If no path AND CWD is NOT the starter kit (no `claude-mastery-project.conf` in CWD) → use CWD as `$TARGET`
- If no path AND CWD IS the starter kit → ask via AskUserQuestion: "Which project do you want to convert? Provide the full path."

Check for `--force` flag in `$ARGUMENTS`. If present, set `$FORCE=true` (skips conflict prompts — uses "keep existing, add missing" for everything).

### Validations (all must pass — stop with clear error if any fail)

1. `$TARGET` directory exists → if not: "Directory not found: $TARGET"
2. `$TARGET` is a git repo → run: `git -C "$TARGET" rev-parse --is-inside-work-tree 2>/dev/null`
   - If not a git repo: "This project must be a git repo. Run `git init && git commit --allow-empty -m 'init'` first."
3. `$TARGET` is NOT the starter kit itself (compare resolved paths of `$SOURCE` and `$TARGET`)
   - If same: "Cannot convert the starter kit itself. Provide the path to an existing project."
4. `$SOURCE` has expected starter kit files (`claude-mastery-project.conf` + `.claude/commands/new-project.md`)
   - If not: "Starter kit source is incomplete. Expected claude-mastery-project.conf and .claude/commands/new-project.md"

---

## Step 1 — Safety Commit (MANDATORY)

```bash
cd "$TARGET"
git status --porcelain
```

**Check commit count first:**
```bash
git -C "$TARGET" rev-list --count HEAD 2>/dev/null
```

- **If zero commits (fresh repo):** Warn the user: "This repo has no commits. We can't create a safety snapshot. Continue anyway?" via AskUserQuestion. If they say no, stop.

- **If uncommitted changes exist** (git status --porcelain has output):
  ```bash
  cd "$TARGET" && git add -A && git commit -m "chore: pre-conversion snapshot (before starter kit merge)"
  ```

- **If clean with history** (no uncommitted changes, has commits):
  ```bash
  cd "$TARGET" && git commit --allow-empty -m "chore: pre-conversion marker (before starter kit merge)"
  ```

Store the hash: `PRE_CONVERT_HASH=$(git -C "$TARGET" rev-parse HEAD)`

**STOP if git fails** (except "nothing to commit" which is fine — treat as clean).

---

## Step 2 — Detect Existing Setup

Scan the target project. Run these checks in parallel:

### Language detection

- `package.json` in `$TARGET` → Node.js
- `go.mod` in `$TARGET` → Go
- `pyproject.toml` OR `requirements.txt` in `$TARGET` → Python
- Multiple detected → ask which is primary via AskUserQuestion
- None → "unknown"

Store as `$LANGUAGE`.

### Existing Claude infrastructure

Count and report:

- `.claude/commands/*.md` files → `$EXISTING_COMMANDS` count
- `.claude/hooks/*.sh` + `.claude/hooks/*.py` files → `$EXISTING_HOOKS` count
- `.claude/skills/*/` directories → `$EXISTING_SKILLS` count
- `.claude/agents/*.md` files → `$EXISTING_AGENTS` count
- Check existence of: `.claude/settings.json`, `CLAUDE.md`, `CLAUDE.local.md`, `claude-mastery-project.conf`

### Existing project infrastructure

Check existence of: `project-docs/`, `.env.example`, `.gitignore`, `.dockerignore`

### Display detection report

```
=== Project Detection Report ===

Target:   $TARGET
Language: $LANGUAGE

Claude Infrastructure:
  Commands:     $EXISTING_COMMANDS files
  Hooks:        $EXISTING_HOOKS files
  Skills:       $EXISTING_SKILLS directories
  Agents:       $EXISTING_AGENTS files
  settings.json: exists / missing
  CLAUDE.md:     exists / missing
  CLAUDE.local.md: exists / missing
  claude-mastery-project.conf: exists / missing

Project Infrastructure:
  project-docs/: exists / missing
  .env.example:  exists / missing
  .gitignore:    exists / missing
  .dockerignore: exists / missing
```

---

## Step 3 — Conflict Resolution

**Skip this entire step if `$FORCE` is true.** When `--force` is set, use "keep existing, add missing" for everything.

Only ask about categories where the target has existing files. Use AskUserQuestion for each applicable question. Ask at most 4 questions at a time (AskUserQuestion limit).

**Batch 1 (if applicable):**

**Q1: Commands** (only if `$EXISTING_COMMANDS > 0`)
- "How should we handle your existing slash commands?"
  - Keep all mine, add only missing starter kit commands (Recommended)
  - Replace all with starter kit versions
  - Let me choose file by file

**Q2: Hooks** (only if `$EXISTING_HOOKS > 0`)
- "How should we handle your existing hooks?"
  - Keep all mine, add only missing starter kit hooks (Recommended)
  - Replace all with starter kit versions
  - Let me choose file by file

**Q3: Skills** (only if `$EXISTING_SKILLS > 0`)
- "How should we handle your existing skills?"
  - Keep all mine, add only missing starter kit skills (Recommended)
  - Replace all with starter kit versions

**Q4: Agents** (only if `$EXISTING_AGENTS > 0`)
- "How should we handle your existing agents?"
  - Keep all mine, add only missing starter kit agents (Recommended)
  - Replace all with starter kit versions

**Batch 2 (if applicable):**

**Q5: CLAUDE.md** (only if target has existing CLAUDE.md)
- "Your project has a CLAUDE.md. Merge starter kit sections into it?"
  - Yes, merge section by section — adds missing sections, keeps yours (Recommended)
  - No, leave my CLAUDE.md untouched

**Q6: settings.json** (only if target has existing `.claude/settings.json`)
- "Your project has a .claude/settings.json. Merge starter kit hooks into it?"
  - Yes, add missing hooks — keeps yours (Recommended)
  - No, leave it untouched

**Q7: Language-specific** (based on `$LANGUAGE`)
- Node.js: "Want the database wrapper (src/core/db/)? Test configs (vitest, playwright)? Merge scripts into package.json?"
  - Yes, add database wrapper + test configs + merge scripts (Recommended)
  - Just merge scripts into package.json
  - No, skip language-specific files
- Go: "Want Go-specific coding standards added to CLAUDE.md?"
  - Yes (Recommended)
  - No
- Python: "Want Python-specific coding standards added to CLAUDE.md?"
  - Yes (Recommended)
  - No

Store each answer. Default for `--force`: "keep mine, add missing" for all categories, "yes merge" for CLAUDE.md and settings.json, "yes" for language-specific.

---

## Step 4 — Merge .claude/ Directory

### Create directories

```bash
mkdir -p "$TARGET/.claude/commands"
mkdir -p "$TARGET/.claude/hooks"
mkdir -p "$TARGET/.claude/skills"
mkdir -p "$TARGET/.claude/agents"
```

### Copy files per category

For each category (commands, hooks, skills, agents), iterate through the source files:

**For commands:** List all `$SOURCE/.claude/commands/*.md` files.
**For hooks:** List all `$SOURCE/.claude/hooks/*.sh` and `$SOURCE/.claude/hooks/*.py` files.
**For skills:** List all `$SOURCE/.claude/skills/*/` directories (copy entire directory).
**For agents:** List all `$SOURCE/.claude/agents/*.md` files.

For each file/directory:

- File does NOT exist in target → **COPY** it. Increment `$ADDED`.
- File EXISTS + strategy is "keep mine, add missing" → **SKIP**. Increment `$SKIPPED`.
- File EXISTS + strategy is "replace all" → **OVERWRITE** (copy with force). Increment `$REPLACED`.
- File EXISTS + strategy is "choose file by file" → Show the filename and ask via AskUserQuestion: "File `<name>` exists in both. Keep yours or use starter kit version?" Options: Keep mine / Use starter kit. Act accordingly.

### Make hooks executable

```bash
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null
chmod +x "$TARGET/.claude/hooks/"*.py 2>/dev/null
```

### Merge settings.json

**If target has no `.claude/settings.json`:** Copy `$SOURCE/.claude/settings.json` directly.

**If target has `.claude/settings.json` and user said "yes, merge":**

1. Read both files as JSON
2. For `permissions.deny`: merge arrays — add entries from source that are missing in target (deduplicate by value)
3. For each hook event type (`PreToolUse`, `PostToolUse`, `Stop`):
   - For each matcher entry in source: check if target already has same matcher string
   - Same matcher → merge the `hooks` arrays (deduplicate by `command` string)
   - New matcher → add entire entry to target
4. NEVER remove existing entries from target
5. Write the merged result to `$TARGET/.claude/settings.json`

**If user said "no, leave untouched":** Skip.

Track and display counts: `ADDED`, `SKIPPED`, `REPLACED` per category.

---

## Step 5 — Merge CLAUDE.md

### If target has no CLAUDE.md

Create a minimal CLAUDE.md with security-only rules (safe for any project type):

```markdown
# CLAUDE.md — Project Instructions

---

## Critical Rules

### 0. NEVER Publish Sensitive Data

- NEVER commit passwords, API keys, tokens, or secrets to git/npm/docker
- NEVER commit `.env` files — ALWAYS verify `.env` is in `.gitignore`
- Before ANY commit: verify no secrets are included
- NEVER output secrets in suggestions, logs, or responses

### 5. NEVER Hardcode Credentials

- ALWAYS use environment variables for secrets
- NEVER put API keys, passwords, or tokens directly in code
- NEVER hardcode connection strings — use DATABASE_URL from .env

### 6. ALWAYS Ask Before Deploying

- NEVER auto-deploy, even if the fix seems simple
- NEVER assume approval — wait for explicit "yes, deploy"
- ALWAYS ask before deploying to production

---

## Workflow Preferences

- Quality over speed — if unsure, ask before executing
- Plan first, code second — use plan mode for non-trivial tasks
- One task, one chat — `/clear` between unrelated tasks
```

Report: `+ CLAUDE.md created (security-only rules)`

### If target has CLAUDE.md and user said "yes, merge"

Parse the starter kit CLAUDE.md and the target CLAUDE.md by `## ` (h2) section headers.

The starter kit CLAUDE.md sections to check:
- `Quick Reference — Scripts`
- `Critical Rules`
- `When Something Seems Wrong`
- `Windows Users`
- `Service Ports`
- `Project Structure`
- `Project Documentation`
- `Coding Standards`
- `Naming — NEVER Rename Mid-Project`
- `Plan Mode — Plan First, Code Second`
- `Documentation Sync`
- `CLAUDE.md Is Team Memory`
- `Workflow Preferences`

For each section:
- Normalize comparison: lowercase, strip dashes/extra spaces
- If a section with similar header exists in target → **SKIP**
- If missing → **APPEND** the entire section to the end of target's CLAUDE.md

**Special: Critical Rules sub-merge:**
If the target already has a "Critical Rules" section, parse both by `### ` (h3) sub-headers. For each numbered rule in the starter kit (Rule 0 through Rule 10):
- If the target has a sub-section with the same rule number → **SKIP**
- If missing → **APPEND** that rule sub-section inside the existing Critical Rules section

Report each section: `skipped (exists)` or `+ added`

### If user said "no, leave untouched"

Skip entirely.

---

## Step 6 — Infrastructure Files

Copy infrastructure files from source to target:

| File | If Missing in Target | If Exists in Target |
|------|---------------------|---------------------|
| `CLAUDE.local.md` | Copy from source | Skip |
| `claude-mastery-project.conf` | Copy from source | Skip |
| `project-docs/ARCHITECTURE.md` | Create `project-docs/` dir, copy | Skip |
| `project-docs/INFRASTRUCTURE.md` | Copy | Skip |
| `project-docs/DECISIONS.md` | Copy | Skip |
| `.env.example` | Copy from source | Merge: read both line by line, add lines from source whose key name (before `=`) doesn't exist in target. Append missing lines at end. |
| `.gitignore` | Copy from source | Merge: add lines from source that don't exist in target. Ensure `.env`, `CLAUDE.local.md`, `_ai_temp/` are present. |
| `.dockerignore` | Copy from source | Merge: add lines from source that don't exist in target. |

Create `project-docs/` directory if it doesn't exist before copying.

Report each file: `+ copied`, `merged (N lines added)`, or `skipped (exists)`

---

## Step 7 — Language-Specific (if user opted in)

### Node.js (if `$LANGUAGE` is Node.js and user opted in)

**Database wrapper** (if user chose "yes, add database wrapper"):
- Create `$TARGET/src/core/db/` directory
- Copy `$SOURCE/src/core/db/index.ts` if missing in target
- Copy `$SOURCE/src/core/db/sql.ts` if missing in target

**Test configs** (if user chose "yes"):
- Copy `$SOURCE/vitest.config.ts` if missing in target
- Copy `$SOURCE/playwright.config.ts` if missing in target

**Package.json scripts** (if user chose "yes" or "just merge scripts"):
- Read both `package.json` files
- For each script name in source's `scripts`: if target doesn't have that script name → add it
- NEVER modify existing scripts in target
- NEVER touch `dependencies` or `devDependencies`
- Write updated target `package.json`

**DB query system** (if user chose "yes"):
- Create `$TARGET/scripts/queries/` directory
- Copy `$SOURCE/scripts/db-query.ts` if missing
- Copy all files from `$SOURCE/scripts/queries/` if the directory was empty/missing

### Go (if `$LANGUAGE` is Go and user opted in)

- Check if target CLAUDE.md has a Go coding standards section (search for "Go" + "golangci" or "go.mod")
- If missing → append the Go coding standards section from the starter kit CLAUDE.md

### Python (if `$LANGUAGE` is Python and user opted in)

- Check if target CLAUDE.md has a Python coding standards section (search for "Python" + "pytest" or "pyproject")
- If missing → append the Python coding standards section from the starter kit CLAUDE.md

---

## Step 8 — Register in Project Registry

1. Read `~/.claude/starter-kit-projects.json`
   - If file doesn't exist → create with `{"projects":[]}`
   - If file exists but is invalid JSON → create fresh

2. Check if a project with the same `path` already exists in the `projects` array:
   - **Yes** → Update the existing entry: set `profile` to `"converted"`, update `convertedAt` to current ISO timestamp
   - **No** → Add a new entry

3. Entry format:
```json
{
  "name": "<directory-name-of-target>",
  "path": "<absolute-path-to-target>",
  "profile": "converted",
  "language": "<detected-language>",
  "framework": "unknown",
  "database": "unknown",
  "createdAt": "<current-ISO-timestamp>"
}
```

4. Write updated registry to `~/.claude/starter-kit-projects.json`

5. Save starter kit source path for future use:
   Write `$SOURCE` to `~/.claude/starter-kit-source-path`

---

## Step 9 — Final Commit + Summary

### Commit the conversion

```bash
cd "$TARGET"
git add -A
git commit -m "chore: merge Claude Code Starter Kit infrastructure"
```

Store: `CONVERT_HASH=$(git -C "$TARGET" rev-parse HEAD)`

### Display summary

```
=== Starter Kit Conversion Complete ===

Target:   $TARGET
Language: $LANGUAGE (detected)

Commands:      N added, N skipped, N replaced
Hooks:         N added, N skipped, N replaced
Skills:        N added, N skipped, N replaced
Agents:        N added, N skipped, N replaced
CLAUDE.md:     N sections added, N skipped (or: created with security rules)
settings.json: deep merged / copied / skipped
Infrastructure: N files added, N merged, N skipped

Pre-conversion commit: $PRE_CONVERT_HASH
Conversion commit:     $CONVERT_HASH

To undo: git revert HEAD
To review: git diff $PRE_CONVERT_HASH..HEAD

Registered in project registry. View with /projects-created.

Next steps:
  1. Run /setup to configure environment variables
  2. Run /help to see all 25 available commands
  3. Review CLAUDE.md and customize rules for your project
```

---

## Edge Cases

1. **Already converted** — Check registry for matching path with `profile: "converted"`. If found, ask: "This project was already converted. Re-merge to pick up new starter kit updates?" via AskUserQuestion. If yes, proceed normally (will add any new files that are missing). If no, stop.

2. **No git repo** — Block with clear error in Step 0 validation.

3. **Target IS the starter kit** — Block with clear error in Step 0 validation.

4. **Fresh repo (0 commits)** — Warn in Step 1, ask to continue.

5. **Binary/large files** — Only copy text files (`.md`, `.sh`, `.py`, `.ts`, `.json`, `.conf`). Never copy node_modules, dist, or binary artifacts.
