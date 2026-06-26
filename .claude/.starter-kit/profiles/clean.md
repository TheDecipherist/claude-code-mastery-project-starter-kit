<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## Clean Mode — `clean`

**If `clean` is detected in arguments, skip ALL of Steps 1-2 below and follow this section instead.**

Clean mode gives the user every piece of Claude Code infrastructure without imposing ANY opinions about how they should code, what language to use, what framework to pick, or how to structure their source code.

### What `clean` creates

```
project/
├── CLAUDE.md              # Security rules ONLY (see below)
├── CLAUDE.local.md        # Personal overrides template
├── .claude/
│   ├── settings.json      # Hooks configuration
│   ├── commands/          # Only scope: project commands (16 of 27)
│   │   ├── architecture.md
│   │   ├── commit.md
│   │   ├── create-api.md
│   │   ├── create-e2e.md
│   │   ├── diagram.md
│   │   ├── help.md
│   │   ├── optimize-docker.md
│   │   ├── progress.md
│   │   ├── refactor.md
│   │   ├── review.md
│   │   ├── security-check.md
│   │   ├── setup.md
│   │   ├── show-user-guide.md
│   │   ├── test-plan.md
│   │   ├── what-is-my-ai-doing.md
│   │   └── worktree.md
│   ├── skills/
│   │   ├── code-review/SKILL.md
│   │   └── create-service/SKILL.md
│   │   ├── code-reviewer.md
│   │   └── test-writer.md
│   └── hooks/
│       ├── lint-on-save.sh
│       └── verify-no-secrets.sh
├── project-docs/
│   ├── ARCHITECTURE.md
│   ├── INFRASTRUCTURE.md
│   └── DECISIONS.md
├── tests/
│   ├── CHECKLIST.md
│   └── ISSUES_FOUND.md
├── .env                   # Empty (NEVER commit)
├── .env.example           # Template with NODE_ENV and PORT
├── .gitignore             # Standard ignores
├── .dockerignore          # Standard ignores
└── README.md              # Minimal project readme
```

### What `clean` does NOT create

- No `src/` directory — user decides their own structure
- No `package.json` — user picks their own language, runtime, and package manager
- No `tsconfig.json` — user may not even use TypeScript
- No `vitest.config.ts` or `playwright.config.ts` — user picks their own test tools
- No database setup or `scripts/db-query.ts` — user picks their own database
- No content builder — user decides if they need one
- No SEO templates — user decides their own approach
- No port assignments — user decides their own ports
- No framework-specific configs — user picks their own framework


> The CLAUDE.md for `clean` mode is exactly `../shared/claude-md-base.md` (universal, non-opinionated rules), with no profile-specific additions. Read it and write it as the project CLAUDE.md.

### Clean mode steps

1. Resolve project path (same as Step 0 / 0.1 above)
2. **Run the batch scaffold script** — this replaces all individual file creation with a single command:

```bash
bash "$(pwd)/scripts/scaffold-clean.sh" "$PROJECT_PATH" "$PROJECT_NAME" "$(pwd)"
```

The script handles ALL of the following in one execution (~100ms) with a progress indicator:
- Creates all directories (.claude/, project-docs/, tests/)
- Copies project-scoped commands, all skills, and all hooks
- Writes settings.json (clean mode — 3 hooks only)
- Creates CLAUDE.md (security rules only), CLAUDE.local.md
- Creates project-docs templates (ARCHITECTURE, INFRASTRUCTURE, DECISIONS)
- Creates tests templates (CHECKLIST, ISSUES_FOUND)
- Creates .env, .env.example, .gitignore, .dockerignore, README.md
- Initializes git with initial commit
- Registers the project in ~/.claude/starter-kit-projects.json

**Do NOT create files individually — the script handles everything.**

3. After the script completes, display the verification checklist (the script output includes a summary)

### Clean verification checklist

- [ ] `.claude/` directory with `scope: project` commands only (16), skills, hooks
- [ ] `.claude/settings.json` with hooks wired up
- [ ] `CLAUDE.md` has ONLY security rules (no TypeScript, no ports, no quality gates)
- [ ] `project-docs/` has all three templates
- [ ] `tests/` has CHECKLIST.md and ISSUES_FOUND.md
- [ ] `.env` exists (empty)
- [ ] `.env.example` exists
- [ ] `.gitignore` includes .env, node_modules/, dist/, CLAUDE.local.md
- [ ] `.dockerignore` exists
- [ ] NO `package.json`, `tsconfig.json`, or framework configs created
- [ ] NO `src/` directory created
- [ ] Git initialized with initial commit

**After creating a `clean` project, the user can add their own language, framework, and structure — Claude will follow the security rules and use the slash commands without imposing any coding patterns.**

---

