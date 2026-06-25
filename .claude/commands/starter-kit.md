---
description: "Manage the @claude-code-mastery/starter-kit installation — update, check status, or add to the current project."
scope: project
argument-hint: "update | status | add"
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
---

# /starter-kit

Manage the globally installed @claude-code-mastery/starter-kit.

The kit is installed in `~/.claude/starter-kit/`. Commands and skills are symlinked from there into `~/.claude/commands/` and `~/.claude/skills/`, so updating the starter-kit directory instantly updates everything without needing to re-symlink.

## Detect subcommand

Read the user's argument: **$ARGUMENTS**

- `update` → run Update flow below
- `status` → run Status flow below
- `add` → run Add flow below
- empty or unrecognised → show usage

---

## Update flow

Check whether npm is available, then run:

```bash
npx @claude-code-mastery/starter-kit update
```

This overwrites `~/.claude/starter-kit/` with the latest published version, symlinks any new commands or skills that were added, and registers any new hooks in `~/.claude/settings.json`.

After the command completes, report the version that is now installed:

```bash
cat ~/.claude/starter-kit/version
```

Tell the user: "✅ Starter kit updated to v<version>. New commands and hooks are active immediately."

If npm / npx is not available, tell the user to install Node.js from https://nodejs.org and then run `npx @claude-code-mastery/starter-kit update` in their terminal.

---

## Status flow

Check the installed version and compare with the registry:

```bash
npx @claude-code-mastery/starter-kit status
```

Show the output to the user as-is. If the kit is not installed, tell the user to run `npx @claude-code-mastery/starter-kit init` from any terminal to install it.

---

## Add flow

Install the starter kit into the **current project's** `.claude/` directory. This is the project-level equivalent of the global install — it gives the project its own copy of commands, hooks, and skills that Claude Code picks up automatically.

Steps:
1. Check whether `~/.claude/starter-kit/` exists. If not, tell the user to run the global install first: `npx @claude-code-mastery/starter-kit init`
2. Check whether `.claude/` already exists in the current project:
   - If it does, ask the user: "`.claude/` already exists in this project. Merge the starter-kit files in? Existing files with matching names will NOT be overwritten." (yes / no)
   - If no: stop.
3. Copy from `~/.claude/starter-kit/` into `.claude/`:
   ```bash
   cp -rn ~/.claude/starter-kit/commands/ .claude/commands/
   cp -rn ~/.claude/starter-kit/hooks/ .claude/hooks/
   cp -rn ~/.claude/starter-kit/skills/ .claude/skills/
   cp -rn ~/.claude/starter-kit/agents/ .claude/agents/
   ```
   (`-n` = no-clobber: never overwrites existing files)
4. If `.claude/settings.json` does not exist in the project, copy from the starter-kit:
   ```bash
   cp ~/.claude/starter-kit/settings.json .claude/settings.json
   ```
   If it does exist, remind the user to manually merge the hook entries from `~/.claude/starter-kit/settings.json` if needed.
5. Report: "✅ Starter kit added to this project's .claude/ directory. Commands and hooks are active for this project."

---

## Usage (when no subcommand given)

```
/starter-kit update   — update to latest version from npm
/starter-kit status   — show installed version vs latest
/starter-kit add      — add kit to current project's .claude/
```
