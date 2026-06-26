<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## SQL Database Setup (projects with `postgres`, `mysql`, `mssql`, or `sqlite` database)

When the project uses a SQL database (PostgreSQL, MySQL, MSSQL, or SQLite), StrictDB handles the connection via `STRICTDB_URI`:

1. Install StrictDB and the appropriate driver based on database choice:
   - All databases: `npm install strictdb@^0.1.0`
   - PostgreSQL: `npm install pg @types/pg`
   - MySQL: `npm install mysql2`
   - MSSQL: `npm install mssql`
   - SQLite: `npm install better-sqlite3 @types/better-sqlite3`
2. Set `STRICTDB_URI` in `.env.example` with placeholder
3. Add StrictDB rules to the project's CLAUDE.md

**The rule that MUST be in every SQL project's CLAUDE.md:**

> ALL SQL database access goes through StrictDB. No exceptions.
> NEVER create connection pools manually — StrictDB manages connections.
> NEVER import database drivers directly — use StrictDB's API.
> ALWAYS use parameterized queries — NEVER string-interpolate values into SQL.

**STRICTDB_URI examples for .env.example:**
```bash
# PostgreSQL
STRICTDB_URI=postgresql://user:password@localhost:5432/mydb

# MySQL
STRICTDB_URI=mysql://user:password@localhost:3306/mydb

# MSSQL
STRICTDB_URI=mssql://user:password@localhost:1433/mydb

# SQLite
STRICTDB_URI=file:./data/app.db
```

