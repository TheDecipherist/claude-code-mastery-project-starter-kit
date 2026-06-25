# Global CLAUDE.md — Security Gatekeeper & Standards

> Place this at ~/.claude/CLAUDE.md
> It applies to EVERY project you work on.
> Based on Claude Code Mastery Guides V1-V5 by TheDecipherist

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

### NEVER Publish Dynamic Data in Markdown Files
- NEVER hardcode repo names, project names, or URLs in `.md` files
- ALWAYS reference environment variables instead
- BAD: `docker push myusername/myproject:latest`
- GOOD: `docker push $DOCKER_HUB_REPO:latest`
- This applies to: CLAUDE.md, README.md, CONTRIBUTING.md, and all documentation

### NEVER Put Personal Instructions in Public Files
- NEVER add personal workflows or non-project instructions to a project's main `CLAUDE.md`
- ALWAYS store personal procedures in `.claude/LOCAL-INSTRUCTIONS.md` (gitignored)
- Examples of what belongs there: social media workflows, personal tracking, marketing procedures

### NEVER Rename Without a Plan
- NEVER do project-wide search-and-replace renames without a checklist
- Renaming causes cascading failures in .md, .env, comments, strings, and paths

### NEVER Push Docker Images Without Local Testing
- NEVER push a Docker image without testing it locally first
- ALWAYS run the container and verify it starts correctly before pushing
- Check for: no crash on startup, no 502 errors, basic pages load

#### Docker Pre-Push Checklist
1. Build: `docker build -t $IMAGE_NAME .`
2. Run: `docker run -d -p 3000:3000 --name test-container $IMAGE_NAME`
3. Wait for startup, then verify: `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000` (expect 200)
4. Check logs: `docker logs test-container`
5. Clean up: `docker stop test-container && docker rm test-container`
6. Only then push

---

## If Credentials Are Ever Exposed

1. IMMEDIATELY rotate/change the exposed credentials
2. Clean git history: `git filter-repo --replace-text <(echo 'OLD_SECRET==>REDACTED')`
3. Force push: `git push --force origin main`
4. Verify credentials are removed from ALL commits
5. Alert anyone who may have cloned the repo

---

## New Project Setup

When creating ANY new project:

### Required Files
- `.env` - Environment variables (NEVER commit)
- `.env.example` - Template with placeholders (committed)
- `.gitignore` - Must include: .env, .env.*, node_modules/, dist/, CLAUDE.local.md
- `.dockerignore` - Must include: .env, .git/, node_modules/
- `CLAUDE.md` - Project instructions
- `tsconfig.json` - TypeScript configuration (strict mode)

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

### TypeScript - Always
- All new files MUST be TypeScript
- Use strict mode
- Never use `any` unless absolutely necessary

---

## Local Instructions Storage

When you have personal procedures that are NOT project code:

- **Project `CLAUDE.md`** - code architecture, build/test/deploy commands, technical standards
- **`.claude/LOCAL-INSTRUCTIONS.md`** - personal workflows, social media posting, marketing procedures, anything that shouldn't be in the public repo

Setup:
1. Create `.claude/` in the project root if it doesn't exist
2. Add `.claude/` to `.gitignore`
3. Create `.claude/LOCAL-INSTRUCTIONS.md` for personal procedures

---

## Markdown Writing Rules

These apply to any `.md` file:

### No Em Dashes
- NEVER use em dashes (--)
- ALWAYS use a regular hyphen (-) instead

### Write Like a Human
- Avoid AI writing patterns: no "delve into", "leverage", "seamlessly", "robust", "comprehensive", "streamline"
- Be direct and specific - say what something does, not how impressive it is
- No filler sentences that add length without adding meaning

### No Repetition
- NEVER repeat a point already made earlier in the same document
- If the opening makes an argument, the body must go deeper - not restate it
- Introductions and conclusions are the worst offenders

---

## Default File Locations

### Documents and Reports
When asked to create documents (PDF, MD, reports, notes) with no specified location:
- ALWAYS default to the `/docs` directory in the project root
- Create `/docs` if it doesn't exist
- Add `/docs` to `.gitignore` - generated docs don't belong in git

### Tracking Files (CSVs, Logs, Metrics)
When tracking data in files:
- ALWAYS create tracking files in `/docs`
- NEVER commit tracking files to git
- Before creating any tracking file: verify `/docs` is in `.gitignore`

### Temporary AI Research Files
When creating research notes, API doc summaries, or analysis during a session:
- ALWAYS store in `_ai_temp/` directory
- Add `_ai_temp/` to `.gitignore` if not already there
- What goes here: research compilations, code analysis notes, temporary drafts, brainstorming

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
- ALWAYS use StrictDB for all database access (shared instance pattern)
- NEVER create database connections in individual files

### Async Performance
- When multiple `await` calls are independent, ALWAYS use `Promise.all`
- NEVER await independent operations sequentially - evaluate dependencies first

---

## Image Conversion

When converting images to WebP:
- Try `ffmpeg` first (most commonly available)
- Fallback: `cwebp` then `convert` (ImageMagick)

```bash
ffmpeg -i input.png -quality 85 output.webp
```

---

## Workflow

- One task, one chat
- Use `/clear` between unrelated tasks
- Quality over speed - ask if unsure
- Use Plan Mode for anything bigger than a simple fix
