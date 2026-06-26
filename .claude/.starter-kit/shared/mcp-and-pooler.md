<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

## AI-Pooler Setup (if @rulecatch/ai-pooler in npm list)

When the default profile or user selects ai-pooler:

```bash
# Free monitor mode — works immediately, no API key needed
# Run in a separate terminal to see live AI activity
npx @rulecatch/ai-pooler monitor --no-api-key

# Full setup with API key (for violation tracking, dashboards, and alerts)
npx @rulecatch/ai-pooler init --api-key=dc_your_key --region=us
```

Add to `.env.example`:
```bash
RULECATCH_API_KEY=dc_your_api_key_here
RULECATCH_REGION=us
```

## MCP Server Setup (if selected)

When MCP servers are selected, add them to the project setup:

```bash
# Context7 — Live documentation (eliminates outdated API answers)
claude mcp add context7 -- npx -y @upstash/context7-mcp@latest

# Playwright — E2E testing
claude mcp add playwright -- npx -y @anthropic-ai/playwright-mcp

# RuleCatch — AI development analytics & rule monitoring
npx @rulecatch/mcp-server init
```

Add selected MCP servers to the project's CLAUDE.md under a "## MCP Servers" section.

