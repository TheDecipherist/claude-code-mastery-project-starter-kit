---
description: Remove a project created by the starter kit
scope: starter-kit
argument-hint: <project-name>
allowed-tools: Read, Edit, Bash(rm:*), Bash(ls:*), AskUserQuestion
---

# Remove Project — Unregister and Optionally Delete

Remove a project from the starter kit registry and optionally delete its files from disk.

**Arguments:** $ARGUMENTS

## Steps

### 1. Read the registry

Read `~/.claude/starter-kit-projects.json`. If the file does not exist, tell the user:

> No projects have been created yet. Nothing to remove.

And stop.

### 2. Find the project

Search the registry for a project matching $ARGUMENTS (by name).

**If no argument provided:**
- List all projects by name
- Ask via AskUserQuestion: "Which project do you want to remove?"
- Options: list all project names from the registry

**If the project name is not found:**
- Tell the user: "Project `<name>` not found in the registry."
- Show the list of registered projects
- Stop

### 3. Show project details

Display the project details:

```
Project: my-app
Path:    ~/projects/my-app
Profile: default
Language: node
Framework: next
Created: 2025-01-15
Status:  exists on disk / directory not found
```

### 4. Ask what to do

Ask via AskUserQuestion: "What do you want to do with this project?"

- **Remove from registry only** — Keep the files, just remove the tracking entry
- **Delete everything** — Delete the project directory AND remove from registry

### 5a. If "Remove from registry only"

- Read `~/.claude/starter-kit-projects.json`
- Remove the matching project entry from the `projects` array
- Write the updated registry back
- Confirm: "Removed `<name>` from the project registry. Files at `<path>` are untouched."

### 5b. If "Delete everything"

**Safety check — ask for explicit confirmation:**

Ask via AskUserQuestion: "Are you sure you want to permanently delete `<path>` and all its contents? This cannot be undone."

- **Yes, delete it** — Proceed with deletion
- **No, cancel** — Stop without deleting

**If confirmed:**

1. Check if the project directory exists on disk
2. If it exists:
   - Check for uncommitted git changes: `cd <path> && git status --porcelain 2>/dev/null`
   - If there are uncommitted changes, WARN the user and ask again: "This project has uncommitted changes. Are you SURE you want to delete?"
   - Delete the directory: `rm -rf <path>`
3. Remove the entry from `~/.claude/starter-kit-projects.json`
4. Confirm: "Deleted `<path>` and removed `<name>` from the registry."

**If the directory doesn't exist:**
- Just remove from registry
- Confirm: "Directory `<path>` was already gone. Removed `<name>` from the registry."

### Safety Rules

- NEVER delete without explicit user confirmation
- ALWAYS warn about uncommitted changes before deletion
- NEVER delete directories outside the registered path
- ALWAYS show what will be deleted before doing it
- The registry itself (`~/.claude/starter-kit-projects.json`) is never deleted — only entries are removed
