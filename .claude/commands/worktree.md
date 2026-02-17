---
description: Create a git worktree + branch for an isolated task
scope: project
argument-hint: <branch-name> [base-branch]
allowed-tools: Bash, Read, AskUserQuestion
---

# Git Worktree — Isolated Task Branch

Create a new git worktree so this task runs on its own branch in its own directory. Main stays untouched. If anything goes wrong, delete the branch — zero risk.

**Arguments:** $ARGUMENTS

## Step 0 — Parse Arguments

- **First argument:** branch name (required). If not provided, ASK the user.
- **Second argument:** base branch to branch from (optional, defaults to `main` or `master`)

Branch naming convention: `task/<descriptive-name>`
- If the user provides just a name like `auth-fix`, prefix it: `task/auth-fix`
- If they already include a prefix like `feat/login`, use as-is

## Step 1 — Verify Git State

Before creating anything, verify:

```bash
# Must be in a git repo
git rev-parse --git-dir

# Check for uncommitted changes on current branch
git status --porcelain
```

**If there are uncommitted changes:** WARN the user. Ask if they want to:
- Stash changes first (`git stash`)
- Commit changes first
- Abort

**NEVER create a worktree with dirty state** — changes could bleed between worktrees.

## Step 2 — Determine Base Branch

```bash
# Find the default branch (main or master)
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If no remote, fall back to checking if `main` or `master` exists locally.

Use the second argument if provided, otherwise use the detected default branch.

## Step 3 — Create Branch + Worktree

The worktree directory goes next to the current repo as `../<repo-name>--<branch-name>`:

```bash
# Example: if repo is at ~/projects/my-app and branch is task/auth-fix
# Worktree goes to ~/projects/my-app--task-auth-fix

REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
BRANCH_NAME="$1"
WORKTREE_DIR="../${REPO_NAME}--${BRANCH_NAME//\//-}"

# Create the branch and worktree in one step
git worktree add -b "$BRANCH_NAME" "$WORKTREE_DIR" "$BASE_BRANCH"
```

## Step 4 — Verify

```bash
# List all worktrees to confirm
git worktree list
```

## Step 5 — Report

Output a summary:

```
Git Worktree Created
====================
Branch:    task/auth-fix
Base:      main
Directory: ~/projects/my-app--task-auth-fix
Main repo: ~/projects/my-app (untouched)

Next steps:
  cd ~/projects/my-app--task-auth-fix
  claude                          # start a new Claude session here

When done:
  cd ~/projects/my-app
  git merge task/auth-fix         # merge into main (or open a PR)
  git worktree remove ../my-app--task-auth-fix
  git branch -d task/auth-fix

If something went wrong:
  git worktree remove ../my-app--task-auth-fix --force
  git branch -D task/auth-fix     # main was never touched
```

## When the Task Is Done

When the user says they're done with work on a worktree branch, ALWAYS:

1. **Review the diff** — show `git diff main...HEAD` summary (files changed, insertions, deletions)
2. **Ask about RuleCatch** — "Do you want RuleCatch to check if any violations happened on this branch?"
   - If yes AND the RuleCatch MCP server is available: query it for violations on this branch's files
   - If yes but no MCP: suggest `npx @rulecatch/ai-pooler check` or checking the RuleCatch dashboard
   - If no: skip and proceed to merge/PR
3. **Ask about merge** — "Ready to merge into main, or do you want to open a PR?"

This ensures every branch gets a quality check before it touches main.

## Quick Reference — Worktree Management

These commands manage ALL worktrees from the main repo:

```bash
git worktree list                           # see all active worktrees
git worktree remove ../my-app--branch-name  # clean up finished task
git worktree prune                          # remove stale entries
```
