---
description: Create a named project profile interactively
scope: starter-kit
allowed-tools: Read, Edit, AskUserQuestion
---

# Add Project Setup — Interactive Profile Creator

Create a named, reusable profile in `claude-mastery-project.conf` through an interactive wizard. The profile can then be used with `/new-project my-app <profile-name>` or set as default with `/set-project-profile-default <profile-name>`.

**Arguments:** $ARGUMENTS

## Steps

### 1. Read the config file

Read `claude-mastery-project.conf` from the project root. If not found, check `~/.claude/claude-mastery-project.conf`.

Extract all existing `[section]` names to prevent duplicates.

### 2. Get profile name

If $ARGUMENTS provides a name, use it. Otherwise ask:

**"What should this profile be called?"**

Validate:
- Lowercase letters, numbers, and hyphens only
- Cannot be `global` or `clean` (reserved)
- Cannot match an existing section name (warn and ask to overwrite or pick another)
- Examples: `my-api`, `dashboard`, `landing-page`, `go-microservice`

### 3. Ask questions (sequential, via AskUserQuestion)

Skip any question if the answer was provided in $ARGUMENTS as shorthand.

#### Q1: Language
"What language will this project use?"
- **Node.js / TypeScript** — JavaScript ecosystem (Recommended)
- **Go** — Systems language, compiled binaries
- **Python** — Data science, APIs, scripting

#### Q2: Project Type
"What type of project?"
- **Web App** — Frontend with UI (SPA or SSR)
- **API** — Backend REST/GraphQL service
- **Full-Stack** — Frontend + backend in one repo
- **CLI** — Command-line tool

#### Q3: Framework (filtered by language + type)

**Node.js + Web App / Full-Stack:**
- **Vite + React** — Fastest HMR, lightweight (Recommended)
- **Next.js** — SSR, server components, built-in routing
- **Vue 3** — Composition API, progressive framework
- **Nuxt** — Vue with SSR, auto-imports, file-based routing

**Node.js + Web App (also):**
- **Svelte** — Compiled, minimal runtime
- **SvelteKit** — Svelte with SSR, file-based routing
- **Angular** — Enterprise, batteries-included
- **Astro** — Content-first, island architecture

**Node.js + API:**
- **Fastify** — Fastest Node.js HTTP framework (Recommended)
- **Express** — Most popular, largest ecosystem
- **Hono** — Ultra-lightweight, edge-ready

**Go + API / Web App:**
- **Gin** — Most popular Go framework (Recommended)
- **Chi** — Lightweight, idiomatic
- **Echo** — High performance, auto TLS
- **Fiber** — Express-inspired, fasthttp
- **stdlib** — Standard library only

**Python + API / Full-Stack:**
- **FastAPI** — Modern, async, auto-docs (Recommended)
- **Django** — Full-featured, batteries-included
- **Flask** — Lightweight, flexible

#### Q4: Database
"Which database?"
- **MongoDB** — Document database
- **PostgreSQL** — Relational (Recommended for SQL)
- **MySQL** — Relational, widely deployed
- **MSSQL** — Microsoft SQL Server
- **SQLite** — Embedded, file-based
- **None** — No database

#### Q5: Hosting
"Where will this be deployed?"
- **Dokploy on Hostinger VPS** — Self-hosted Docker containers (Recommended)
- **Vercel** — Zero-config for Next.js / static
- **Static hosting** — GitHub Pages, Netlify, Cloudflare
- **None / Decide later**

#### Q6: Package Manager (auto-detected from language, overridable)
- Node.js default: **pnpm**
- Go: **gomod** (automatic, don't ask)
- Python: **pip** (ask if they prefer **uv** or **poetry**)

#### Q7: Analytics
"Include analytics?"
- **Rybbit** — Privacy-first analytics
- **None**

#### Q8: Options (multi-select)
"What extras? (select all that apply)"
- **SEO** — Meta tags, structured data, sitemap
- **SSR** — Server-side rendering
- **Tailwind CSS** — Utility-first CSS
- **Docker** — Containerized deployment
- **GitHub Actions CI** — Automated testing pipeline
- **Multi-region** — US + EU deployment (Dokploy only)

#### Q9: MCP Servers (multi-select)
"Which MCP servers? (select all that apply)"
- **Playwright** — Browser automation for E2E testing
- **Context7** — Live documentation lookup
- **RuleCatch** — AI session analytics & rule monitoring

#### Q10: Set as default?
"Set this as the default profile for `/new-project`?"
- **Yes** — Future `/new-project` commands use this profile
- **No** — Keep current default

### 4. Write the profile

Add a new `[profile-name]` section to `claude-mastery-project.conf` with all the collected values:

```ini
[profile-name]
language = node
type = api
framework = fastify
hosting = dokploy
package_manager = pnpm
database = postgres
analytics = none
options = docker, ci
mcp = context7, rulecatch
```

If Q10 was "Yes", also set `default_profile = profile-name` in `[global]`.

### 5. Confirm

Read the file back and show the new profile section. Tell the user:

> Done. Profile `<name>` created. Use it with:
>
>   /new-project my-app <name>
>
> Or set it as default with:
>
>   /set-project-profile-default <name>
