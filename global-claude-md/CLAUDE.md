# Global CLAUDE.md — Security Gatekeeper & Standards

> Place this at ~/.claude/CLAUDE.md
> It applies to EVERY project you work on.
> Based on Claude Code Mastery Guides V3-V5 by TheDecipherist

---

## Identity

- GitHub: **YourUsername**
- SSH: `git@github.com:YourUsername/<repo>.git`

---

## NEVER EVER DO

These rules are ABSOLUTE and apply to every project:

### NEVER Publish Sensitive Data
- NEVER publish passwords, API keys, tokens to git/npm/docker
- Before ANY commit: verify no secrets included
- NEVER output secrets in responses, logs, or suggestions

### NEVER Commit .env Files
- NEVER commit `.env` to git
- ALWAYS verify `.env` is in `.gitignore`

### NEVER Auto-Deploy
- ALWAYS ask before deploying to production
- NEVER assume approval — wait for explicit "yes, deploy"

### NEVER Hardcode Credentials
- ALWAYS use environment variables for secrets
- NEVER put API keys, passwords, or tokens directly in source code

### NEVER Rename Without a Plan
- NEVER do project-wide search-and-replace renames without a checklist
- Renaming causes cascading failures in .md, .env, comments, strings, and paths

---

## New Project Setup

When creating ANY new project:

### Required Files
- `.env` — Environment variables (NEVER commit)
- `.env.example` — Template with placeholders (committed)
- `.gitignore` — Must include: .env, .env.*, node_modules/, dist/, CLAUDE.local.md
- `.dockerignore` — Must include: .env, .git/, node_modules/
- `CLAUDE.md` — Project instructions
- `tsconfig.json` — TypeScript configuration (strict mode)

### Required Structure
```
project/
├── src/
├── tests/
├── project-docs/
├── .claude/
│   ├── commands/
│   ├── skills/
│   └── agents/
└── scripts/
```

### TypeScript — Always
- All new files MUST be TypeScript
- Use strict mode
- Never use `any` unless absolutely necessary

---

## Coding Standards (All Projects)

### Error Handling
- NEVER swallow errors silently
- ALWAYS log errors with context before re-throwing
- Add `process.on('unhandledRejection')` handler to entry points

### Testing
- ALWAYS define explicit success criteria
- "Page loads" is NOT a success criterion
- Every test must assert something meaningful

### Quality Gates
- No file > 300 lines (split if larger)
- No function > 50 lines (extract helpers)
- All tests must pass before committing
- TypeScript compiles with no errors
- No linter warnings

### Database
- ALWAYS use a centralized database wrapper (singleton pattern)
- NEVER create database connections in individual files

---

## Workflow

- One task, one chat
- Use `/clear` between unrelated tasks
- Quality over speed — ask if unsure
- Use Plan Mode for anything bigger than a simple fix
