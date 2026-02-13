---
description: Smart commit with context — generates conventional commit message
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*)
argument-hint: [optional commit message override]
---

# Smart Commit

## Context
- Current git status: !`git status --short`
- Current diff: !`git diff HEAD --stat`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`

## Auto-Branch (if on main)

Before committing, check the current branch:

```bash
git branch --show-current
```

**Default behavior** (`auto_branch = true` in `claude-mastery-project.conf`):
- If on `main` or `master`: automatically create a feature branch from the staged changes context:
  ```bash
  git checkout -b feat/<scope-from-changes>
  ```
  Report: "Created branch `feat/<scope>` — committing there instead of main."
  Then proceed with the commit on the new branch.
- If already on a feature branch: proceed normally
- If not a git repo: skip this check

**To disable:** Set `auto_branch = false` in `claude-mastery-project.conf`. When disabled, warn and ask the user to confirm before committing to main.

## Task

Review the staged changes and create a commit.

### Rules
1. Use **conventional commit** format: `type(scope): description`
   - Types: feat, fix, docs, style, refactor, test, chore, perf
2. Description should be concise but descriptive (max 72 chars)
3. If changes span multiple concerns, suggest splitting into multiple commits
4. NEVER commit .env files or secrets
5. Verify .gitignore includes .env before committing

### If message provided
Use this as the commit message: $ARGUMENTS

### If no message provided
Generate an appropriate commit message based on the diff.

### RuleCatch Report (post-commit)

After the commit succeeds, check RuleCatch for violations in the committed files:

- If the RuleCatch MCP server is available: query for violations on the files in this commit
- Report: "RuleCatch: X violations found in committed files" (with details if any)
- If no MCP available: remind the user — "Check your RuleCatch dashboard for violations in this commit"
- If violations are found: DO NOT undo the commit, just report them so the user can decide
