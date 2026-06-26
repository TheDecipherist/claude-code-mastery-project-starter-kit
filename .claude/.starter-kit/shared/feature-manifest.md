<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## Feature Manifest — MANDATORY Final Step (ALL modes except Clean)

**After scaffolding completes and BEFORE the final verification checklist**, write `.claude/features.json` to the new project based on what was scaffolded.

### Map scaffolding choices to features

| Scaffolding Choice | Feature Name | Files to List |
|-------------------|-------------|---------------|
| `database = mongo` | `mongo` | `scripts/db-query.ts`, `scripts/queries/example-find-user.ts`, `scripts/queries/example-count-docs.ts` |
| `database = postgres\|mysql\|mssql\|sqlite` | `postgres` | `scripts/db-query.ts` |
| Vitest installed | `vitest` | `vitest.config.ts` |
| Playwright installed | `playwright` | `playwright.config.ts` |
| Docker selected | `docker` | `Dockerfile` |
| Content pipeline | `content` | `scripts/build-content.ts`, `scripts/content.config.json` |

### Write the manifest

```json
{
  "schemaVersion": 1,
  "installedBy": "claude-code-mastery-starter-kit",
  "language": "<node|go|python>",
  "features": {
    "<feature-name>": {
      "version": "1.0.0",
      "installedAt": "<current-ISO-timestamp>",
      "updatedAt": null,
      "files": ["<list-of-files>"]
    }
  }
}
```

Write to `$PROJECT_PATH/.claude/features.json`.

**For Clean mode:** The scaffold-clean.sh script already creates an empty manifest (`"features": {}`). No additional action needed.

**For Go/Python modes:** Map the same features (e.g., Go with MongoDB via StrictDB → `mongo` feature with `internal/database/mongo.go` in files).

---

