---
description: Live monitor of everything your AI is doing — tokens, cost, violations, tool usage
argument-hint: [--json]
allowed-tools: Bash, AskUserQuestion
---

# What Is My AI Doing?

Launch the RuleCatch AI-Pooler live monitor to see everything your AI is doing in real time.

**Arguments:** $ARGUMENTS

## Step 1 — Check if RuleCatch is Installed

```bash
npx @rulecatch/ai-pooler@latest --version 2>/dev/null
```

If the command fails or returns nothing, tell the user:

```
RuleCatch is not installed.

This command requires the RuleCatch AI-Pooler to monitor AI activity.
RuleCatch is optional — the starter kit works fully without it.

If you'd like to set it up:

  1. Get an API key from https://rulecatch.ai
  2. Run: npx @rulecatch/ai-pooler init --api-key=dc_your_key --region=us
  3. Then run this command again.

Learn more: https://rulecatch.ai/docs
```

**Stop here** — do not continue to Step 2.

## Step 2 — Launch the Monitor

If the AI-Pooler is installed, tell the user:

```
The AI-Pooler monitor needs to run in a separate terminal window.
Open a new terminal and run:

  npx @rulecatch/ai-pooler@latest monitor -v

This shows you a live view of:
  • Every tool call Claude makes (Read, Write, Edit, Bash, etc.)
  • Token usage per turn
  • Cost per session
  • Rule violations as they happen
  • Which files are being accessed

Press Ctrl+C to stop the monitor.
```

## Step 3 — Remind

After providing the instructions, remind the user:

- The monitor runs **outside** Claude's context — zero token overhead
- It watches ALL Claude sessions, not just this one
- Violations are reported to the RuleCatch dashboard automatically
- You can query violations from within Claude using the RuleCatch MCP: "RuleCatch, what was violated today?"
