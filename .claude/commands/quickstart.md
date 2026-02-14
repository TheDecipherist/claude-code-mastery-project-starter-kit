---
description: Interactive first-run walkthrough for new users
allowed-tools: Bash(ls:*), Bash(cat:*), AskUserQuestion, Read
---

# Quickstart — First-Run Walkthrough

Guide the user through their first experience with the Claude Code Starter Kit. This is an interactive walkthrough — ask questions, check state, and give personalized next steps.

## Step 1 — Check Global Config

```bash
ls ~/.claude/CLAUDE.md 2>/dev/null && echo "GLOBAL_CONFIG=installed" || echo "GLOBAL_CONFIG=missing"
```

If `GLOBAL_CONFIG=missing`:

Tell the user:

```
Your global Claude config isn't installed yet. This is a one-time setup that adds
security rules and hooks across ALL your projects.

Run: /install-global

This smart-merges into your existing ~/.claude/ config — it never overwrites.
Come back to /quickstart after it's done.
```

**Stop here if global config is missing.** Don't proceed until they install it.

If `GLOBAL_CONFIG=installed`, continue to Step 2.

## Step 2 — Ask Project Details

Ask the user:

**Question 1:** "What do you want to name your project?"

Validate: lowercase letters, numbers, and hyphens only. No spaces, no uppercase. Show an example: `my-awesome-app`

**Question 2:** "Which profile do you want to use?"

Options:
- **clean** — All Claude AI tools (commands, hooks, skills, agents) with zero coding opinions. You pick your own language, framework, and structure. Best for: experienced developers who want Claude's tooling without opinionated scaffolding.
- **default** — Full opinionated stack: Next.js, TypeScript, MongoDB, Tailwind, Docker, CI, Rybbit analytics, Playwright tests. Best for: new projects that want everything pre-configured.

## Step 3 — Tell Them to Scaffold

Based on their answers, tell the user:

```
Great! Here's your next step:

  /new-project $NAME $PROFILE

This creates ~/projects/$NAME with everything wired up.
```

**Do NOT run `/new-project` for them.** Tell them to run it themselves — it's a separate command with its own interactive flow.

## Step 4 — Show Next Steps

After they understand the scaffolding command, show:

```
After scaffolding, here's your first 5 minutes:

  1. cd ~/projects/$NAME
  2. /setup                    Configure .env (database, GitHub, Docker, analytics)
  3. pnpm install              Install dependencies
  4. pnpm dev                  Start the dev server
  5. Make a change             Edit any file
  6. /review                   Run a code review on your changes
  7. /commit                   Smart commit with conventional format

Available commands (run /help for the full list):
  /diagram all       Generate architecture diagrams from your actual code
  /test-plan         Create a structured test plan for a feature
  /create-api users  Scaffold a full API endpoint with types, handler, route, tests
  /create-e2e login  Generate a Playwright E2E test with explicit assertions
  /progress          Check project status and prioritized next actions
```

## Step 5 — Offer Docs

Ask: "Want me to open the full documentation?"

If yes, tell them:
```
Full interactive guide: https://thedecipherist.github.io/claude-code-mastery-project-starter-kit/
Source guides: https://github.com/TheDecipherist/claude-code-mastery
```

If no, say: "You're all set! Run `/help` anytime to see all available commands."
