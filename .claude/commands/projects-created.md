---
description: List all projects created by the starter kit
allowed-tools: Read, Bash(ls:*), Bash(date:*), Bash(stat:*), Bash(wc:*)
---

# Projects Created — Starter Kit Project Registry

List every project that was scaffolded by `/new-project`, with creation date, profile used, and location.

## Steps

### 1. Read the registry

Read `~/.claude/starter-kit-projects.json`. If the file does not exist, tell the user:

> No projects have been created yet. Use `/new-project my-app` to scaffold your first project.

And stop.

### 2. Parse and validate

The registry format is:

```json
{
  "projects": [
    {
      "name": "my-app",
      "path": "/home/user/projects/my-app",
      "profile": "default",
      "language": "node",
      "framework": "next",
      "database": "mongo",
      "createdAt": "2025-01-15T10:30:00Z"
    }
  ]
}
```

### 3. Check which projects still exist on disk

For each project in the registry, check if the directory still exists:

```bash
ls -d /path/to/project 2>/dev/null
```

Mark projects whose directory no longer exists as `(missing)`.

### 4. Display the table

Print a formatted table sorted by creation date (newest first):

```
=== Projects Created by Starter Kit ===

 #  Name              Profile       Language   Framework   Database   Created          Path
 1  my-app            default       node       next        mongo      2025-01-15       ~/projects/my-app
 2  my-api            python-api    python     fastapi     postgres   2025-01-14       ~/projects/my-api
 3  old-project       go            go         gin         mongo      2025-01-10       ~/projects/old-project (missing)

Total: 3 projects (2 active, 1 missing)

Tip: Use /remove-project <name> to remove a project and its registry entry.
```

### 5. Handle empty registry

If the registry exists but has zero projects:

> No projects in the registry. Use `/new-project my-app` to scaffold a project.

### Notes

- The registry is stored at `~/.claude/starter-kit-projects.json` (global — shared across all starter kit instances)
- Projects are registered automatically by `/new-project` after successful scaffolding
- Missing projects still appear in the list — use `/remove-project` to clean them up
- The registry file is NEVER committed to git (it's in `~/.claude/`)
