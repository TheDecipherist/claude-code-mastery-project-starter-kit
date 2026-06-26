<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

> This profile builds its CLAUDE.md from `../shared/claude-md-base.md` (the universal rules) plus the profile-specific rules below. Read the base first.

## Step 1 — Ask the User (skip questions answered by arguments)

For any choices NOT provided via arguments, ask the user (use AskUserQuestion):

### Question 1: Project Type
"What type of project are you building?"
- **Web App** — Frontend with UI (SPA or SSR)
- **API** — Backend REST/GraphQL service
- **Full-Stack** — Frontend + backend in one repo
- **CLI Tool** — Command-line application

### Question 2: Framework (based on project type)

**If Web App or Full-Stack:**
"Which framework do you want to use?"
- **Vite + React** — Fastest HMR, lightweight, great for SPAs (Recommended)
- **Next.js (App Router)** — SSR, server components, built-in routing
- **Vue 3** — Composition API, progressive framework, reactive
- **Nuxt** — Vue with SSR, auto-imports, file-based routing
- **Svelte** — Compiled, minimal runtime, reactive by default
- **SvelteKit** — Svelte with SSR, file-based routing, form actions
- **Angular** — Enterprise, standalone components, signals
- **Astro** — Content-first, island architecture, great for marketing/docs sites

**If API:**
"Which framework do you want to use?"
- **Fastify** — Fastest Node.js HTTP framework, built-in validation (Recommended)
- **Express** — Most popular, largest ecosystem
- **Hono** — Ultra-lightweight, edge-ready

**If CLI Tool:**
- Use **Commander.js** + **TypeScript** (no framework question needed)

### Question 3: SSR Requirement (Web App / Full-Stack only, skip if Next.js or Astro already chosen)
"Do you need server-side rendering (SSR)?"
- **No (SPA)** — Client-side only, simpler deployment (Recommended for dashboards/apps)
- **Yes (SSR)** — SEO-critical pages, faster first paint (Recommended for public-facing sites)

If they chose Vite + React and want SSR, switch to **Next.js (App Router)** or add **vite-plugin-ssr**.

### Question 4: Package Manager
"Which package manager?"
- **pnpm** — Fast, disk-efficient (Recommended)
- **npm** — Default, universal
- **bun** — Fastest, newer ecosystem

### Question 5: Hosting / Deployment
"Where will this be deployed?" (skip if `dokploy`, `vercel`, or `static` in arguments)
- **Dokploy on Hostinger VPS** — Self-hosted Docker containers with Dokploy management (Recommended for full control)
- **Vercel** — Zero-config for Next.js / static sites
- **Static hosting** — GitHub Pages, Netlify, Cloudflare Pages
- **None / Decide later** — Skip deployment scaffolding

### Question 6: Extras (multi-select)
"What extras do you want to include?"
- **Tailwind CSS** — Utility-first CSS framework
- **Prisma** — Type-safe database ORM
- **Docker** — Containerized deployment (auto-included with Dokploy)
- **GitHub Actions CI** — Automated testing pipeline
- **Multi-region** — US + EU deployment (Dokploy only)

### Question 7: MongoDB Connection String (only if `mongo` database selected)
"Do you want to configure your MongoDB connection now?"
- **Yes, I have a connection string** — User pastes their full `mongodb+srv://...` or `mongodb://...` URI. Write it to `.env` as `STRICTDB_URI=<their-value>`.
- **No, I'll set it up later** — Skip. Leave `STRICTDB_URI` placeholder in `.env.example` only.

If the user provides a connection string:
1. Write `STRICTDB_URI=<value>` to the project's `.env`
2. If no database name in URI, ask: "What should the database be called?" and append it to the URI

## Step 2 — Create the Project

Based on answers, scaffold the project.

### Default Profile Batch Script

**If the resolved choices exactly match the default profile** (fullstack + next + mongo + tailwind + docker + pnpm), use the batch scaffold script for maximum speed:

```bash
# Resolve the kit source: npm global install takes priority over CWD
if [ -f ~/.claude/starter-kit-source-path ]; then
  KIT=$(cat ~/.claude/starter-kit-source-path)
else
  KIT="$(pwd)"
fi
bash "$KIT/scripts/scaffold-default.sh" "$PROJECT_PATH" "$PROJECT_NAME" "$KIT"
```

The script handles ALL of the following in one execution with progress indicators:
- Creates all directories (src/, project-docs/, tests/, scripts/, .github/)
- For clone users: copies project-scoped commands, all skills, and all hooks into the project's .claude/
- For npm users: skips local .claude/ copy (commands/skills/hooks already live globally in ~/.claude/)
- Writes settings.json (10-hook config) for clone users only
- Installs StrictDB (npm package) + query system
- Creates Next.js app structure (layout, page, API health route, instrumentation)
- Installs StrictDB (npm package) + query system
- Creates Next.js app structure (layout, page, API health route, instrumentation)
- Creates TypeScript, Next.js, Tailwind, PostCSS, Vitest, Playwright configs
- Creates package.json with all deps/scripts
- Creates Dockerfile (multi-stage standalone)
- Creates GitHub Actions CI workflow
- Creates CLAUDE.md (all rules), CLAUDE.local.md
- Creates project-docs templates, test templates, SEO files
- Creates .env, .env.example, .gitignore, .dockerignore, README.md
- Creates populated features.json manifest
- Runs pnpm install, initializes git, registers project

**Do NOT create files individually when using the default profile — the script handles everything.**

After the script completes, display the verification checklist (the script output includes a summary).

### Manual Scaffolding (non-default profiles)

For profiles other than `default` and `clean`, scaffold manually:

1. Create project directory
2. Initialize with chosen framework and package manager
3. Install TypeScript + Vitest (ALWAYS, non-negotiable)
4. Create ALL required files (see below)
5. Apply framework-specific rules
6. Apply SEO requirements (if web project)
7. Initialize git repository
8. Create initial commit: "Initial project scaffold"
9. Display verification checklist

## Required Files (EVERY Project)

- `.env` — Empty, for secrets (NEVER commit)
- `.env.example` — Template with placeholder values
- `.gitignore` — Must include: .env, .env.*, node_modules/, dist/, CLAUDE.local.md
- `.dockerignore` — Must include: .env, .git/, node_modules/
- `README.md` — Project overview (reference env vars, don't hardcode)
- `CLAUDE.md` — Must include: project overview, tech stack, build/test/dev commands, architecture, port assignments
- `tsconfig.json` — Strict mode enabled, `noUncheckedIndexedAccess: true`

## Required Directory Structure

```
project/
├── src/
├── tests/
├── project-docs/
│   ├── ARCHITECTURE.md
│   ├── INFRASTRUCTURE.md
│   └── DECISIONS.md
├── .claude/
│   ├── commands/
│   ├── skills/
└── scripts/
    ├── db-query.ts          # (StrictDB/MongoDB only) Test Query Master
    └── queries/             # (StrictDB/MongoDB only) Individual dev/test query files
```


> Database setup: if a SQL database was selected, read and apply `../shared/sql-setup.md`; if `mongo`, read and apply `../shared/mongo-setup.md`. Then continue below.

## TypeScript + Vitest + Playwright (ALWAYS)

Every project MUST have Vitest for unit tests and Playwright for E2E tests.

### vitest.config.ts
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node', // or 'jsdom' for web
    include: ['tests/unit/**/*.test.ts', 'tests/integration/**/*.test.ts'],
    exclude: ['tests/e2e/**/*'],
  },
});
```

### playwright.config.ts
```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html'], ['list']],
  use: {
    baseURL: 'http://localhost:4000', // TEST port, not dev port
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  webServer: [
    {
      command: 'pnpm dev:test:website',
      port: 4000,
      reuseExistingServer: !process.env.CI,
      timeout: 30_000,
    },
  ],
});
```

### package.json test scripts (REQUIRED in every project)
```json
{
  "scripts": {
    "dev:test:website": "PORT=4000 tsx watch src/index.ts",
    "dev:test:api": "PORT=4010 tsx watch src/index.ts",
    "test": "pnpm test:unit && pnpm test:e2e",
    "test:unit": "vitest run",
    "test:unit:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "pnpm test:kill-ports && playwright test",
    "test:e2e:ui": "pnpm test:kill-ports && playwright test --ui",
    "test:e2e:headed": "pnpm test:kill-ports && playwright test --headed",
    "test:e2e:report": "playwright show-report",
    "test:kill-ports": "lsof -ti:4000,4010,4020 | xargs kill -9 2>/dev/null || true"
  }
}
```

**CRITICAL: `test:kill-ports` runs BEFORE every E2E test command.** This prevents "port already in use" failures. Never skip this step.

### tsconfig.json (minimum)
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

## Node.js Entry Point Requirements

Add to EVERY Node.js entry point. If the project uses StrictDB, use `gracefulShutdown` to close pools before exit:

```typescript
// WITH StrictDB (projects using StrictDB)
import { gracefulShutdown } from 'strictdb';

process.on('SIGTERM', () => gracefulShutdown(0));
process.on('SIGINT', () => gracefulShutdown(0));
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  gracefulShutdown(1);
});
process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
  gracefulShutdown(1);
});
```

```typescript
// WITHOUT StrictDB (no database projects)
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});
```


> SEO: for any web (HTML-serving) project, read and apply `../shared/seo.md` before the framework-specific rules below.

## Framework-Specific Rules

### Vite + React
- Use Vite's built-in HMR (no config needed)
- Add `@vitejs/plugin-react` or `@vitejs/plugin-react-swc` (SWC is faster)
- Use path aliases: `"@/*": ["./src/*"]` in tsconfig
- Vitest shares Vite config — zero extra setup

### Next.js (App Router)
- Use App Router (NOT Pages Router)
- Create `src/app/` directory structure
- Use Server Components by default, `"use client"` only when needed
- Strict mode in next.config
- Use `metadata` export for SEO (not `<Head>`)

### Fastify
- Use `@fastify/type-provider-typebox` for schema validation
- Register routes as plugins for encapsulation
- Use `fastify-swagger` for auto-generated API docs
- All routes under `/api/v1/` prefix

### Vue 3

**CLI scaffold:** `npm create vue@latest PROJECT -- --typescript --router --pinia`

After scaffold:
- Copy `.claude/` — only commands with `scope: project` in frontmatter (skills, hooks, settings.json copied in full)
- Add `project-docs/`, CLAUDE.md, CLAUDE.local.md, `.env` files
- Vitest is included by default from `create vue`

**CLAUDE.md rules for Vue 3 projects:**
```markdown
### Vue 3 Rules
- Composition API ONLY — never use Options API in new code
- ALWAYS use `<script setup>` syntax (not `setup()` function)
- Type defineProps and defineEmits: `defineProps<{ title: string }>()`
- Use `ref()` for primitives, `reactive()` for objects
- Prefer `computed()` over methods for derived state
- Use `watchEffect()` over `watch()` when watching all dependencies
```

### Nuxt

**CLI scaffold:** `npx nuxi@latest init PROJECT --package-manager pnpm`

After scaffold:
- Copy `.claude/` — only commands with `scope: project` in frontmatter (skills, hooks, settings.json copied in full)
- Add `project-docs/`, CLAUDE.md, CLAUDE.local.md, `.env` files
- Vitest and Playwright added via `npx nuxi module add @nuxt/test-utils`

**CLAUDE.md rules for Nuxt projects:**
```markdown
### Nuxt Rules
- Use auto-imports — do NOT manually import Vue composables or Nuxt utils
- Use `useFetch()` / `useAsyncData()` for data fetching — NEVER raw `fetch` in components
- API routes go in `server/api/` — file-based routing, no manual route registration
- Use `definePageMeta()` for page-level metadata (layout, middleware)
- `useState()` for shared reactive state across components
```

### Svelte / SvelteKit

**CLI scaffold:** `npx sv create PROJECT` (select TypeScript skeleton)

After scaffold:
- Copy `.claude/` — only commands with `scope: project` in frontmatter (skills, hooks, settings.json copied in full)
- Add `project-docs/`, CLAUDE.md, CLAUDE.local.md, `.env` files
- `sv create` includes Vitest + Playwright if selected during setup

**CLAUDE.md rules for Svelte/SvelteKit projects:**
```markdown
### Svelte Rules
- Use Runes syntax: `$state()`, `$derived()`, `$effect()` — not legacy `$:` reactive statements
- Use `$props()` for component props
- SvelteKit: use `+page.ts` / `+page.server.ts` load functions for data fetching
- SvelteKit: use form actions (`+page.server.ts` `actions`) for mutations
- SvelteKit: use `$app/environment` for environment detection, NOT `process.env`
```

### Angular

**CLI scaffold:** `npx @angular/cli new PROJECT --style=scss --routing --ssr=false`

After scaffold:
- Copy `.claude/` — only commands with `scope: project` in frontmatter (skills, hooks, settings.json copied in full)
- Add `project-docs/`, CLAUDE.md, CLAUDE.local.md, `.env` files
- Angular includes Jasmine by default — optionally add Vitest with `@analogjs/vitest-angular`
- Add Playwright for E2E: `npm init playwright@latest`

**CLAUDE.md rules for Angular projects:**
```markdown
### Angular Rules
- Standalone components ONLY — never use NgModule for new components
- Use Angular Signals (`signal()`, `computed()`, `effect()`) for reactive state
- Use `inject()` for dependency injection — not constructor injection
- Use `@defer` for lazy loading heavy components
- Template syntax: use `@if`/`@for`/`@switch` (new control flow) — not `*ngIf`/`*ngFor`
```

### Astro
- Use content collections for structured content
- Islands architecture: interactive components only where needed
- Built-in image optimization with `<Image>` component

### Python
- Create `pyproject.toml` (not setup.py)
- Use `src/` layout
- Include `requirements.txt` AND `requirements-dev.txt`

### Docker
- Multi-stage builds ALWAYS
- Never run as root (create service-specific user)
- Include health checks
- COPY package.json first for layer caching
- For monorepos: build shared packages first, copy dist into deployed node_modules

### Docker Multi-Stage Template
```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Install package manager
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies (cached layer)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Build args for Next.js (baked at build time)
ARG NEXT_PUBLIC_RYBBIT_SITE_ID
ARG NEXT_PUBLIC_RYBBIT_URL
ENV NEXT_PUBLIC_RYBBIT_SITE_ID=$NEXT_PUBLIC_RYBBIT_SITE_ID
ENV NEXT_PUBLIC_RYBBIT_URL=$NEXT_PUBLIC_RYBBIT_URL

# Copy source and build
COPY . .
RUN pnpm build

# Stage 2: Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Non-root user
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser
USER appuser

# Copy built artifacts
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

EXPOSE 3000
CMD ["node", "dist/server.js"]
```

