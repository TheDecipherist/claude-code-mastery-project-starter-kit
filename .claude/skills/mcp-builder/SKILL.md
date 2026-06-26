---
name: mcp-builder
description: Build a high-quality MCP server that exposes a service or API to an LLM through well-designed tools. Use when asked to create, scaffold, or add an MCP server, wrap an API as MCP tools, or expose a service to Claude/agents. Writes files, so it runs only when invoked explicitly.
when_to_use: |
  - User asks to build, scaffold, or add an MCP server
  - User wants to wrap an API, service, or database as MCP tools
  - User says "MCP server", "expose this as tools", "make this callable by an agent"
  - Do NOT auto-run; this writes files
disable-model-invocation: true
allowed-tools: "Read, Write, Edit, Bash"
---

# Build an MCP Server

An MCP server is judged by one thing: whether an LLM can use its tools to finish real tasks. Tool count, endpoint coverage, and cleverness are means, not the goal. Build for the agent that will call it.

## Default stack

- **TypeScript, on the MCP SDK.** Strong typing and good model familiarity. Drop to Python (FastMCP) only when the service it wraps is Python-native.
- **Transport: streamable HTTP with stateless JSON for remote servers; stdio for local.** Stateless scales and debugs far more easily than session streaming.
- **Resolve the SDK version at build time**, don't hardcode from memory. The current SDK README is the source of truth.

## The four phases

**1. Understand the target.** Read the service's API or schema first. Identify the handful of tasks a user actually wants done through it, not every endpoint. A wrapper that mirrors 60 REST routes one-to-one is worse than 8 tools shaped around real workflows.

**2. Design the tools.** This is where quality is won or lost.

- **Discoverable names**: `verb_noun`, scoped by service, for example `github_create_issue`, `orders_find_by_customer`. The name should tell the model when to reach for it.
- **Descriptions written for the model**, stating what the tool does and when to use it, not just what it returns.
- **Explicit input and output schemas.** Constrain inputs; return structured, parseable output, not prose the model has to scrape.
- **Annotations**: mark each tool `readOnlyHint`, `destructiveHint`, or `idempotentHint` so the client can reason about safety.
- **Actionable errors.** "Invalid date" is useless; "expected ISO 8601, got 03/04/2026, did you mean 2026-03-04" lets the model self-correct.
- **Balance coverage against workflow tools.** Comprehensive low-level tools give the agent room to compose; a few high-level workflow tools cut steps for the common path. Most good servers ship both.

**3. Implement.** Shared infrastructure first (client, auth, pagination, error handling), then the tools on top. If the server touches a database, it follows the same kit rules as everything else: one shared client, data access through the adapter, StrictDB if installed otherwise the native driver, never Mongoose.

**4. Test with evaluations.** Write 10 realistic, multi-step questions a user would ask, then verify an LLM can answer each using only the tools. Solve each yourself first so you know the right answer. Failing evals point at a missing tool, a vague description, or output the model can't parse, fix those, not the eval.

## Project shape

    src/
      server.ts        transport + registration, thin
      client.ts        the upstream API/service client (the one place it's touched)
      tools/           one file per tool or tight tool group
      schemas/         input/output schemas (zod)
    evals/
      evals.json       the 10 questions and verified answers

Keep `server.ts` thin, the same discipline as `api-conventions`: it wires transport and registers tools, nothing more. Tool logic lives in `tools/`, upstream calls in `client.ts`. No file over 300 lines.

## What to avoid

- Dumping every endpoint as a tool with no workflow shaping.
- Tool names only the author understands.
- Returning raw upstream JSON the model has to guess the shape of.
- Skipping evals, an MCP server you haven't watched an LLM drive is untested.
