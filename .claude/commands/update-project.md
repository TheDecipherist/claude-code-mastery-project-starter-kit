---
description: Update a starter-kit project with the latest commands, hooks, skills, and rules
scope: starter-kit
argument-hint: [--force | --clean]
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
---

# Update Starter Kit Project

Update an existing starter-kit project with the latest commands, hooks, skills, agents, and rules from the current starter kit source. Smart merge — replaces starter kit files with newer versions while preserving any custom files the user created themselves.

**Arguments:** $ARGUMENTS

---

## Step 0 — Resolve Source (Starter Kit)

Find the starter kit source directory:

1. If CWD has BOTH `claude-mastery-project.conf` AND `.claude/commands/new-project.md` → use CWD as `$SOURCE`
2. Else read `~/.claude/starter-kit-source-path` → verify it still has both files
3. Else ask via AskUserQuestion: "Where is the starter kit cloned?" with a text input

Store as `$SOURCE`.

---

## Step 1 — Registry Picker (Select Target)

1. Read `~/.claude/starter-kit-projects.json`
   - If file doesn't exist or empty → error: "No projects found. Use `/new-project` to create one first."
   - If file is invalid JSON → error: "Project registry is corrupted. Check `~/.claude/starter-kit-projects.json`."

2. Filter to projects whose `path` directory still exists on disk

3. If no valid projects remain → error: "No registered projects found on disk. Use `/new-project` to create one."

4. Display list with AskUserQuestion:
   - "Which project do you want to update?"
   - Options: up to 4 most recent projects (by `createdAt`), each showing: `name — language/framework — path`
   - If more than 4: the 4th option should be "Other (type a path)"

5. Store selected path as `$TARGET`

### Validations (all must pass — stop with clear error if any fail)

1. `$TARGET` directory exists → if not: "Directory not found: $TARGET"
2. `$TARGET` is a git repo → run: `git -C "$TARGET" rev-parse --is-inside-work-tree 2>/dev/null`
   - If not a git repo: "This project must be a git repo. Run `git init && git commit --allow-empty -m 'init'` first."
3. `$TARGET` is NOT the starter kit itself (compare resolved paths of `$SOURCE` and `$TARGET`)
   - If same: "Cannot update the starter kit itself."
4. `$TARGET` is registered in `~/.claude/starter-kit-projects.json`
   - If not registered: "This project isn't in the registry. Use `/convert-project-to-starter-kit` instead."

Parse flags from `$ARGUMENTS`:
- `--force` → set `$FORCE=true` (skips confirmation prompts)
- `--clean` → set `$CLEAN=true` (skip normal update, jump to **Clean Mode** section below)

---

## Step 2 — Safety Commit

```bash
cd "$TARGET"
git status --porcelain
```

- **If uncommitted changes exist** (git status --porcelain has output):
  ```bash
  cd "$TARGET" && git add -A && git commit -m "chore: pre-update snapshot (before starter kit update)"
  ```

- **If clean** (no uncommitted changes):
  ```bash
  cd "$TARGET" && git commit --allow-empty -m "chore: pre-update marker (before starter kit update)"
  ```

Store the hash: `PRE_UPDATE_HASH=$(git -C "$TARGET" rev-parse HEAD)`

**STOP if git fails** (except "nothing to commit" which is fine — treat as clean).

---

## Step 3 — Inventory & Diff

Build a manifest of what the starter kit currently has vs what the target has.

### Categories to compare

| Category | Source Location | Target Location |
|----------|----------------|-----------------|
| Commands | `$SOURCE/.claude/commands/*.md` (scope: project only) | `$TARGET/.claude/commands/*.md` |
| Hooks | `$SOURCE/.claude/hooks/*.{sh,py}` | `$TARGET/.claude/hooks/*.{sh,py}` |
| Skills | `$SOURCE/.claude/skills/*/SKILL.md` | `$TARGET/.claude/skills/*/SKILL.md` |
| Agents | `$SOURCE/.claude/agents/*.md` | `$TARGET/.claude/agents/*.md` |

**Command scope filtering:** Only include source commands that have `scope: project` in their YAML frontmatter. Commands with `scope: starter-kit` are kit-management commands and should never be copied to projects. If the target already has a starter-kit-scoped command (e.g., from a previous version), classify it as **CUSTOM** (user-created) — never overwrite or remove it.

### For each file, classify as:

- **NEW** — exists in source, not in target → will be added
- **UPDATED** — exists in both, content differs (compare with `diff -q`) → will be replaced
- **UNCHANGED** — exists in both, content is identical → skip
- **CUSTOM** — exists in target only, not in source → never touched (user-created)

### Display the diff report

```
=== Starter Kit Update Report ===

Target: $TARGET
Source: $SOURCE

Commands:
  + NEW:       update-project.md, show-user-guide.md
  ↻ UPDATED:   commit.md, review.md (starter kit versions changed)
  = UNCHANGED: help.md, progress.md, ... (12 files)
  ○ CUSTOM:    my-custom-command.md (yours, not touched)

Hooks:
  + NEW:       (none)
  ↻ UPDATED:   check-branch.sh
  = UNCHANGED: block-secrets.py, lint-on-save.sh, ...
  ○ CUSTOM:    (none)

Skills:     (all unchanged)
Agents:     (all unchanged)

settings.json: hooks will be deep-merged
CLAUDE.md:     3 new sections will be appended
Infrastructure: .gitignore (2 lines to add), .env.example (1 key to add)

Total: N files to add, N files to update, N unchanged, N custom (untouched)
```

---

## Step 4 — Confirm (unless --force)

If not `$FORCE`, ask via AskUserQuestion:

"Apply these updates? N new files, N updated files. Your custom files won't be touched."
- **Yes, update** (Recommended)
- **Show me the diffs first** — for each UPDATED file, show `diff` output between source and target, then ask again
- **No, cancel**

If user selects "No, cancel" → stop immediately with: "Update cancelled. No changes made."

---

## Step 5 — Apply Updates

### 5a. Commands, Hooks, Skills, Agents

For each **NEW** file: copy from source to target.
For each **UPDATED** file: overwrite target with source version.
For **CUSTOM** and **UNCHANGED**: skip entirely.

For skills: copy the entire skill directory (e.g., `$SOURCE/.claude/skills/code-review/` → `$TARGET/.claude/skills/code-review/`).

Make hooks executable:
```bash
chmod +x "$TARGET/.claude/hooks/"*.sh 2>/dev/null
chmod +x "$TARGET/.claude/hooks/"*.py 2>/dev/null
```

### 5b. settings.json — Deep Merge

Same merge logic as `/convert-project-to-starter-kit`:

1. Read both `$SOURCE/.claude/settings.json` and `$TARGET/.claude/settings.json` as JSON
2. `permissions.deny`: merge arrays, deduplicate by value
3. For each hook event type (`PreToolUse`, `PostToolUse`, `Stop`):
   - For each matcher entry in source: check if target already has same matcher string
   - Same matcher → merge the `hooks` arrays (deduplicate by `command` string)
   - New matcher → add entire entry to target
4. NEVER remove existing entries from target
5. Write merged result to `$TARGET/.claude/settings.json`

If target has no `.claude/settings.json`: copy from source directly.

### 5c. CLAUDE.md — Section Merge

Same as `/convert-project-to-starter-kit`:

1. Parse both by `## ` (h2) headers
2. For each section in source not in target → append at end of target CLAUDE.md
3. For Critical Rules: sub-merge by `### ` (h3) numbered rules — add missing rules, keep existing
4. NEVER remove or replace existing sections

If target has no `CLAUDE.md`: skip (don't create — the project should already have one from initial creation).

### 5d. Infrastructure Files

| File | If Missing in Target | If Exists in Target |
|------|---------------------|---------------------|
| `CLAUDE.local.md` | Copy from source | Skip |
| `claude-mastery-project.conf` | Copy from source | Skip |
| `project-docs/ARCHITECTURE.md` | Create `project-docs/` dir, copy | Skip |
| `project-docs/INFRASTRUCTURE.md` | Copy | Skip |
| `project-docs/DECISIONS.md` | Copy | Skip |
| `.env.example` | Copy from source | Merge: read both, add lines from source whose key name (before `=`) doesn't exist in target. Append missing lines at end. |
| `.gitignore` | Copy from source | Merge: add lines from source that don't exist in target. Ensure `.env`, `CLAUDE.local.md`, `_ai_temp/` are present. |
| `.dockerignore` | Copy from source | Merge: add lines from source that don't exist in target. |

---

## Step 6 — Update Registry

1. Read `~/.claude/starter-kit-projects.json`
2. Find the project entry by `path` matching `$TARGET`
3. Add or update `updatedAt` field with current ISO timestamp
4. Increment `updateCount` field (start at 1 if missing, increment if exists)
5. Write updated registry back to `~/.claude/starter-kit-projects.json`

---

## Step 7 — Commit + Summary

```bash
cd "$TARGET"
git add -A
git commit -m "chore: update Claude Code Starter Kit infrastructure"
```

Store: `UPDATE_HASH=$(git -C "$TARGET" rev-parse HEAD)`

**If nothing to commit** (all files unchanged): skip the commit, note "Already up to date."

### Display summary

```
=== Starter Kit Update Complete ===

Target:   $TARGET

Commands:      N added, N updated, N unchanged, N custom
Hooks:         N added, N updated, N unchanged, N custom
Skills:        N added, N updated, N unchanged, N custom
Agents:        N added, N updated, N unchanged, N custom
settings.json: deep merged (N new hooks added) / unchanged / copied
CLAUDE.md:     N sections added, N skipped (exists)
Infrastructure: N files added, N merged, N skipped

Pre-update commit:  $PRE_UPDATE_HASH
Update commit:      $UPDATE_HASH

To undo: git revert HEAD
To review: git diff $PRE_UPDATE_HASH..HEAD

Next: Run /help to see any new commands.
```

---

## Edge Cases

1. **Already up to date** — If all files are UNCHANGED and no infrastructure changes needed, report "Already up to date — no changes needed." and skip the update commit.

2. **Target has no .claude/ directory** — This shouldn't happen for registered projects, but if it does, create the directories and treat all files as NEW.

3. **Git fails** — If any git operation fails (commit, add), stop with a clear error. Never leave the project in a half-updated state.

4. **Custom files with same name as starter kit** — If a user happened to create a file with the same name as a starter kit file (e.g., `help.md`), it will show as UPDATED (content differs). The diff report makes this visible before applying.

---

## Clean Mode — `--clean`

**If `$CLEAN` is true, skip Steps 2-7 entirely and run this flow instead.**

Clean mode scans a project for commands that have `scope: starter-kit` in their frontmatter — these are kit-management commands that should NOT be in scaffolded projects. Older versions of the starter kit copied all commands without filtering, so existing projects may have them.

### Clean Step 1 — Scan for starter-kit commands

Read every `.md` file in `$TARGET/.claude/commands/`. For each file, parse the YAML frontmatter and check for `scope: starter-kit`.

Build a list of files to remove.

### Clean Step 2 — Display findings

If no `scope: starter-kit` commands found:
```
No cleanup needed — this project has no starter-kit-scoped commands.
```
Stop here.

If found, display the list:

```
=== Clean: Starter-Kit Commands Found ===

These commands are kit-management tools that don't belong in project repos:

  1. new-project.md          — Create a new project with all scaffolding rules applied
  2. update-project.md       — Update a starter-kit project with the latest commands, hooks, skills, and rules
  3. install-global.md       — Install global Claude config
  4. convert-project-to-starter-kit.md — Merge starter kit into an existing project
  5. quickstart.md           — Interactive first-run walkthrough for new users
  6. projects-created.md     — List all projects created by the starter kit
  7. remove-project.md       — Remove a project from the registry
  8. set-project-profile-default.md — Set the default profile for /new-project
  9. add-project-setup.md    — Create a named project profile

Found N starter-kit commands that should be removed.
```

### Clean Step 3 — Ask what to remove

Use AskUserQuestion:

"Which commands do you want to remove?"
- **Remove all N** (Recommended) — Delete all starter-kit-scoped commands
- **Let me pick** — Show each file and ask individually

**If "Remove all":** delete all listed files.

**If "Let me pick":** for each file, ask via AskUserQuestion (batch up to 4 at a time):
- "Remove `<filename>`? (<description>)"
  - Yes, remove it
  - No, keep it

### Clean Step 4 — Execute removal

For each file to remove:
```bash
rm "$TARGET/.claude/commands/<filename>"
```

### Clean Step 5 — Commit + Summary

```bash
cd "$TARGET"
git add -A
git commit -m "chore: remove starter-kit-scoped commands (clean)"
```

Display summary:

```
=== Clean Complete ===

Removed N starter-kit commands:
  - new-project.md
  - update-project.md
  - ...

Kept N project commands.

To undo: git revert HEAD
```

**If nothing was removed** (user said "no" to everything): skip the commit, note "No changes made."
