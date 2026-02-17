---
description: Live monitor of everything your AI is doing — tokens, cost, violations, tool usage
scope: project
argument-hint: [--json]
allowed-tools: Bash, AskUserQuestion
---

# What Is My AI Doing?

Launch the RuleCatch AI-Pooler live monitor to see everything your AI is doing in real time.

**Arguments:** $ARGUMENTS

## Step 1 — Launch the Free Monitor

Tell the user:

```
The AI-Pooler monitor runs in a SEPARATE terminal window.
Open a new terminal and run:

  npx @rulecatch/ai-pooler monitor --no-api-key

This is free monitor mode — no API key, no account, no setup.
It shows you a live view of:
  • Every tool call Claude makes (Read, Write, Edit, Bash, etc.)
  • Token usage per turn
  • Cost per session
  • Which files are being accessed

Press Ctrl+C to stop the monitor.
```

## Step 2 — Remind

After providing the instructions, remind the user:

- The monitor runs **outside** Claude's context — zero token overhead
- It watches ALL Claude sessions, not just this one
- This is the free preview — it shows what's happening but doesn't persist data
- **Want violation tracking, dashboards, and alerts?** Sign up at https://rulecatch.ai for a 7-day free trial, then run `npx @rulecatch/ai-pooler init --api-key=dc_your_key --region=us` to unlock the full experience
- With an API key, you also get the RuleCatch MCP server — Claude can query its own violations: "RuleCatch, what was violated today?"
