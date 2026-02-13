---
description: Create a new project with all scaffolding rules applied
argument-hint: <framework> <project-name>
allowed-tools: Bash, Write, Read
---

# New Project Scaffold

Create a new project with the following specifications:

**Framework and name:** $ARGUMENTS

## Required Steps

1. Create project directory
2. Initialize with the appropriate framework
3. Create ALL required files (see below)
4. Apply framework-specific rules
5. Initialize git repository
6. Create initial commit: "Initial project scaffold"
7. Display checklist of created files

## Required Files (EVERY Project)

- `.env` — Empty, for secrets (NEVER commit)
- `.env.example` — Template with placeholder values
- `.gitignore` — Must include: .env, .env.*, node_modules/, dist/, CLAUDE.local.md
- `.dockerignore` — Must include: .env, .git/, node_modules/
- `README.md` — Project overview (reference env vars, don't hardcode)
- `CLAUDE.md` — Must include: project overview, tech stack, build/test commands, architecture
- `tsconfig.json` — Strict mode enabled (for TS projects)

## Required Directory Structure

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

## Node.js/TypeScript Requirements

Add to entry point:
```typescript
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});
```

## Framework-Specific Rules

### Next.js
- Use App Router (not Pages Router)
- Create `src/app/` directory structure
- Strict mode in next.config

### Python
- Create `pyproject.toml` (not setup.py)
- Use `src/` layout
- Include `requirements.txt` AND `requirements-dev.txt`

### Docker
- Multi-stage builds ALWAYS
- Never run as root
- Include health checks

## Verification Checklist

After creation, verify and report:
- [ ] .env exists (empty)
- [ ] .env.example exists (with placeholders)
- [ ] .gitignore includes all required entries
- [ ] .dockerignore exists
- [ ] CLAUDE.md has all required sections
- [ ] Error handlers in entry point
- [ ] TypeScript strict mode enabled
- [ ] No file > 300 lines

Report any missing items.
