<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## MongoDB Test Query System (projects with `mongo` database)

When the project uses MongoDB (via StrictDB), ALWAYS scaffold the db-query system:

1. Create `scripts/db-query.ts` — the master index/CLI runner
2. Create `scripts/queries/` directory for individual query files
3. Add the db-query rules to the project's `CLAUDE.md`

**The rule that MUST be in every StrictDB/MongoDB project's CLAUDE.md:**

> ALL ad-hoc / test / dev database queries go through `scripts/db-query.ts`.
> When asked to look something up in the database:
> 1. Create a query file in `scripts/queries/<name>.ts`
> 2. Register it in `scripts/db-query.ts`
> 3. NEVER create standalone scripts or inline queries in `src/`

This prevents Claude from scattering random query scripts all over the project.

