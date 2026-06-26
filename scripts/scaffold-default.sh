#!/usr/bin/env bash
# scaffold-default.sh — Fast batch scaffold for default profile projects
# Default profile: fullstack Next.js + StrictDB + Tailwind + Docker + SEO + CI
#
# Usage: bash scripts/scaffold-default.sh <project-path> <project-name> <starter-kit-root>
#
# Creates a complete default-profile project with progress indicators.
# This replaces ~40+ individual tool calls with a single script execution.

set -euo pipefail

# ── Arguments ──────────────────────────────────────────────────────────────────
PROJECT_PATH="$1"
PROJECT_NAME="$2"
STARTER_KIT="$3"
REGISTRY="${HOME}/.claude/starter-kit-projects.json"

# ── Global install detection ───────────────────────────────────────────────────
if [ -f "${HOME}/.claude/starter-kit-source-path" ]; then
  GLOBAL_INSTALLED=true
  CLAUDE_DIR="$STARTER_KIT"
else
  GLOBAL_INSTALLED=false
  CLAUDE_DIR="$STARTER_KIT/.claude"
fi

# ── Validation ─────────────────────────────────────────────────────────────────
if [ -d "$PROJECT_PATH" ]; then
  echo "ERROR: Directory already exists: $PROJECT_PATH"
  echo "Remove it first or choose a different name."
  exit 1
fi

if [ ! -d "$CLAUDE_DIR/commands" ]; then
  echo "ERROR: Starter kit not found at: $STARTER_KIT"
  exit 1
fi

# ── Progress Tracking ──────────────────────────────────────────────────────────
TOTAL_STEPS=15
CURRENT=0
START_NS=$(date +%s%N)

progress() {
  CURRENT=$((CURRENT + 1))
  local pct=$((CURRENT * 100 / TOTAL_STEPS))
  local now_ns=$(date +%s%N)
  local elapsed_ms=$(( (now_ns - START_NS) / 1000000 ))

  # Progress bar (20 chars)
  local filled=$((pct / 5))
  local empty=$((20 - filled))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="\xe2\x96\x88"; done
  for ((i=0; i<empty; i++)); do bar+="\xe2\x96\x91"; done

  # Estimated time remaining
  local eta=""
  if [ "$CURRENT" -eq "$TOTAL_STEPS" ]; then
    eta="Done!"
  elif [ "$elapsed_ms" -gt 0 ] && [ "$CURRENT" -gt 0 ]; then
    local ms_per_step=$((elapsed_ms / CURRENT))
    local remaining_ms=$(( (TOTAL_STEPS - CURRENT) * ms_per_step ))
    if [ "$remaining_ms" -ge 1000 ]; then
      local remaining_s=$((remaining_ms / 1000))
      local remaining_frac=$(( (remaining_ms % 1000) / 100 ))
      eta="~${remaining_s}.${remaining_frac}s remaining"
    else
      eta="~${remaining_ms}ms remaining"
    fi
  else
    eta="estimating..."
  fi

  printf "[%d/%d] %3d%%  $(echo -e "$bar")  %-40s %s\n" \
    "$CURRENT" "$TOTAL_STEPS" "$pct" "$1" "$eta"
}

# ── Header ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEW PROJECT: $PROJECT_NAME (default profile)"
echo "  Next.js + StrictDB + Tailwind + Docker + SEO + CI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 1: Create directory structure ─────────────────────────────────────────
progress "Creating directory structure..."
if [ "$GLOBAL_INSTALLED" = "false" ]; then
  mkdir -p "$PROJECT_PATH"/.claude/{commands,skills,agents,hooks}
fi
mkdir -p "$PROJECT_PATH"/project-docs
mkdir -p "$PROJECT_PATH"/src/app/api/v1/health
mkdir -p "$PROJECT_PATH"/src/handlers
mkdir -p "$PROJECT_PATH"/src/adapters
mkdir -p "$PROJECT_PATH"/src/types
mkdir -p "$PROJECT_PATH"/tests/{unit,integration,e2e}
mkdir -p "$PROJECT_PATH"/scripts/queries
mkdir -p "$PROJECT_PATH"/content
mkdir -p "$PROJECT_PATH"/.github/workflows
mkdir -p "$PROJECT_PATH"/public

# ── Steps 2-4: Copy Claude infrastructure (clone users only) ──────────────────
# npm users already have commands/skills/hooks installed globally in ~/.claude/
if [ "$GLOBAL_INSTALLED" = "false" ]; then
  progress "Copying 16 project commands..."
  for cmd in architecture commit create-api create-e2e diagram help \
             optimize-docker progress refactor review security-check \
             setup show-user-guide test-plan what-is-my-ai-doing worktree; do
    cp "$CLAUDE_DIR/commands/${cmd}.md" "$PROJECT_PATH/.claude/commands/"
  done

  progress "Copying skills, agents, 10 hooks..."
  cp -r "$CLAUDE_DIR/skills/code-review" "$PROJECT_PATH/.claude/skills/"
  cp -r "$CLAUDE_DIR/skills/create-service" "$PROJECT_PATH/.claude/skills/"
  cp "$CLAUDE_DIR/agents/code-reviewer.md" "$PROJECT_PATH/.claude/agents/"
  cp "$CLAUDE_DIR/agents/test-writer.md" "$PROJECT_PATH/.claude/agents/"
  for hook in block-dangerous-bash.py check-file-length.py lint-on-save.sh \
              verify-no-secrets.sh check-rybbit.sh check-branch.sh \
              check-ports.sh check-e2e.sh check-rulecatch.sh check-env-sync.sh; do
    cp "$CLAUDE_DIR/hooks/${hook}" "$PROJECT_PATH/.claude/hooks/"
  done
  chmod +x "$PROJECT_PATH/.claude/hooks/"*.sh 2>/dev/null
  chmod +x "$PROJECT_PATH/.claude/hooks/"*.py 2>/dev/null

  progress "Writing settings.json (10 hooks)..."
  cat > "$PROJECT_PATH/.claude/settings.json" << 'SETTINGS_EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/block-dangerous-bash.py"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/check-rybbit.sh"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/check-branch.sh"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/check-ports.sh"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/check-e2e.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 .claude/hooks/check-file-length.py"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/lint-on-save.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/verify-no-secrets.sh"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/check-rulecatch.sh"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/check-env-sync.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
else
  progress "Skipping local .claude/ copy (commands/skills/hooks live globally)"
  progress "Skipping local .claude/ copy (commands/skills/hooks live globally)"
  progress "Skipping local .claude/ copy (commands/skills/hooks live globally)"
fi

# ── Step 4b: Create features.json (populated manifest) ────────────────────────
CREATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
cat > "$PROJECT_PATH/.claude/features.json" << FEATURES_EOF
{
  "schemaVersion": 1,
  "installedBy": "claude-code-mastery-starter-kit",
  "language": "node",
  "features": {
    "mongo": {
      "version": "1.0.0",
      "installedAt": "${CREATED_AT}",
      "updatedAt": null,
      "files": [
        "scripts/db-query.ts",
        "scripts/queries/example-find-user.ts",
        "scripts/queries/example-count-docs.ts"
      ]
    },
    "vitest": {
      "version": "1.0.0",
      "installedAt": "${CREATED_AT}",
      "updatedAt": null,
      "files": [
        "vitest.config.ts"
      ]
    },
    "playwright": {
      "version": "1.0.0",
      "installedAt": "${CREATED_AT}",
      "updatedAt": null,
      "files": [
        "playwright.config.ts"
      ]
    },
    "docker": {
      "version": "1.0.0",
      "installedAt": "${CREATED_AT}",
      "updatedAt": null,
      "files": [
        "Dockerfile"
      ]
    }
  }
}
FEATURES_EOF

# ── Step 5: Copy query system ─────────────────────────────────────────────────
progress "Copying StrictDB query system..."
cp "$STARTER_KIT/scripts/db-query.ts" "$PROJECT_PATH/scripts/db-query.ts"
cp "$STARTER_KIT/scripts/queries/example-find-user.ts" "$PROJECT_PATH/scripts/queries/"
cp "$STARTER_KIT/scripts/queries/example-count-docs.ts" "$PROJECT_PATH/scripts/queries/"

# ── Step 6: Create Next.js app files ──────────────────────────────────────────
progress "Creating Next.js app structure..."

# src/app/layout.tsx — SEO + Rybbit analytics
cat > "$PROJECT_PATH/src/app/layout.tsx" << 'LAYOUT_EOF'
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'My App',
    template: '%s — My App',
  },
  description: 'Built with Claude Code Mastery Starter Kit',
  robots: { index: true, follow: true },
  openGraph: {
    type: 'website',
    title: 'My App',
    description: 'Built with Claude Code Mastery Starter Kit',
    siteName: 'My App',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'My App',
    description: 'Built with Claude Code Mastery Starter Kit',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        {process.env.NEXT_PUBLIC_RYBBIT_SITE_ID && (
          <script
            src={`${process.env.NEXT_PUBLIC_RYBBIT_URL || 'https://app.rybbit.io'}/api/script.js`}
            data-site-id={process.env.NEXT_PUBLIC_RYBBIT_SITE_ID}
            defer
          />
        )}
      </head>
      <body>{children}</body>
    </html>
  );
}
LAYOUT_EOF

# src/app/page.tsx
cat > "$PROJECT_PATH/src/app/page.tsx" << 'PAGE_EOF'
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold mb-4">Welcome</h1>
      <p className="text-lg text-gray-600">
        Your project is ready. Start building.
      </p>
    </main>
  );
}
PAGE_EOF

# src/app/globals.css
cat > "$PROJECT_PATH/src/app/globals.css" << 'CSS_EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
CSS_EOF

# src/app/api/v1/health/route.ts
cat > "$PROJECT_PATH/src/app/api/v1/health/route.ts" << 'HEALTH_EOF'
import { NextResponse } from 'next/server';

export async function GET() {
  return NextResponse.json({ status: 'ok', timestamp: new Date().toISOString() });
}
HEALTH_EOF

# src/instrumentation.ts — process signal handlers for Next.js
cat > "$PROJECT_PATH/src/instrumentation.ts" << 'INSTRUMENT_EOF'
export async function register() {
  if (process.env.NEXT_RUNTIME === 'nodejs') {
    const { StrictDB } = await import('strictdb');

    // Get or create the shared StrictDB instance
    const db = await StrictDB.create({ uri: process.env.STRICTDB_URI! });

    process.on('SIGTERM', () => db.gracefulShutdown(0));
    process.on('SIGINT', () => db.gracefulShutdown(0));
    process.on('uncaughtException', (err) => {
      console.error('Uncaught Exception:', err);
      db.gracefulShutdown(1);
    });
    process.on('unhandledRejection', (reason) => {
      console.error('Unhandled Rejection:', reason);
      db.gracefulShutdown(1);
    });
  }
}
INSTRUMENT_EOF

# ── Step 7: Create config files (tsconfig, next, tailwind, postcss) ───────────
progress "Creating TypeScript + Next.js + Tailwind configs..."

cat > "$PROJECT_PATH/tsconfig.json" << 'TSCONFIG_EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
TSCONFIG_EOF

cat > "$PROJECT_PATH/next.config.ts" << 'NEXTCONFIG_EOF'
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  output: 'standalone',
  images: {
    formats: ['image/webp'],
  },
};

export default nextConfig;
NEXTCONFIG_EOF

cat > "$PROJECT_PATH/tailwind.config.ts" << 'TAILWIND_EOF'
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};

export default config;
TAILWIND_EOF

cat > "$PROJECT_PATH/postcss.config.mjs" << 'POSTCSS_EOF'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};

export default config;
POSTCSS_EOF

# ── Step 8: Create Vitest + Playwright configs ────────────────────────────────
progress "Creating Vitest + Playwright configs..."

cat > "$PROJECT_PATH/vitest.config.ts" << 'VITEST_EOF'
import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['tests/unit/**/*.test.ts', 'tests/integration/**/*.test.ts'],
    exclude: ['tests/e2e/**/*'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
VITEST_EOF

cat > "$PROJECT_PATH/playwright.config.ts" << 'PLAYWRIGHT_EOF'
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html'], ['list']],
  use: {
    baseURL: 'http://localhost:4000',
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
PLAYWRIGHT_EOF

# E2E example test
cat > "$PROJECT_PATH/tests/e2e/home.spec.ts" << 'E2E_EOF'
import { test, expect } from '@playwright/test';

test.describe('Home Page', () => {
  test('loads successfully with correct content', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveURL('/');
    await expect(page.locator('h1')).toBeVisible();
    await expect(page.locator('h1')).toContainText('Welcome');
  });

  test('has correct page title and metadata', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/My App/);
    const viewport = page.viewportSize();
    expect(viewport).toBeTruthy();
  });
});

test.describe('Health API', () => {
  test('returns ok status', async ({ request }) => {
    const response = await request.get('/api/v1/health');
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.status).toBe('ok');
    expect(body.timestamp).toBeTruthy();
  });
});
E2E_EOF

# Unit test example
cat > "$PROJECT_PATH/tests/unit/example.test.ts" << 'UNIT_EOF'
import { describe, it, expect } from 'vitest';

describe('Example test', () => {
  it('basic math works', () => {
    expect(1 + 1).toBe(2);
  });

  it('string operations work', () => {
    const greeting = 'Hello, World!';
    expect(greeting).toContain('Hello');
    expect(greeting).toHaveLength(13);
  });
});
UNIT_EOF

# ── Step 9: Create package.json ───────────────────────────────────────────────
progress "Creating package.json..."

cat > "$PROJECT_PATH/package.json" << PKGJSON_EOF
{
  "name": "$PROJECT_NAME",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "next dev -p 3000",
    "dev:website": "next dev -p 3000",
    "dev:api": "next dev -p 3001",
    "dev:dashboard": "next dev -p 3002",
    "dev:test:website": "PORT=4000 next dev -p 4000",
    "dev:test:api": "PORT=4010 next dev -p 4010",
    "build": "next build",
    "start": "next start",
    "typecheck": "tsc --noEmit",
    "test": "pnpm test:unit && pnpm test:e2e",
    "test:unit": "vitest run",
    "test:unit:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "pnpm test:kill-ports && playwright test",
    "test:e2e:ui": "pnpm test:kill-ports && playwright test --ui",
    "test:e2e:headed": "pnpm test:kill-ports && playwright test --headed",
    "test:e2e:chromium": "pnpm test:kill-ports && playwright test --project=chromium",
    "test:e2e:report": "playwright show-report",
    "test:kill-ports": "lsof -ti:4000,4010,4020 | xargs kill -9 2>/dev/null || true",
    "db:query": "tsx scripts/db-query.ts",
    "db:query:list": "tsx scripts/db-query.ts --list",
    "clean": "rm -rf .next coverage test-results playwright-report"
  },
  "dependencies": {
    "strictdb": "^0.1.0",
    "mongodb": "^6.5.0",
    "next": "^15.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@playwright/test": "^1.42.0",
    "@types/node": "^20.0.0",
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0",
    "tailwindcss": "^3.4.0",
    "tsx": "^4.7.0",
    "typescript": "^5.0.0",
    "vitest": "^2.0.0"
  }
}
PKGJSON_EOF

# ── Step 10: Create Dockerfile (multi-stage Next.js standalone) ────────────────
progress "Creating Dockerfile..."

cat > "$PROJECT_PATH/Dockerfile" << 'DOCKER_EOF'
# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@latest --activate

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build args for Next.js public env vars (baked at build time)
ARG NEXT_PUBLIC_RYBBIT_SITE_ID
ARG NEXT_PUBLIC_RYBBIT_URL
ENV NEXT_PUBLIC_RYBBIT_SITE_ID=$NEXT_PUBLIC_RYBBIT_SITE_ID
ENV NEXT_PUBLIC_RYBBIT_URL=$NEXT_PUBLIC_RYBBIT_URL

RUN pnpm build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser

COPY --from=builder --chown=appuser:appgroup /app/.next/standalone ./
COPY --from=builder --chown=appuser:appgroup /app/.next/static ./.next/static
COPY --from=builder --chown=appuser:appgroup /app/public ./public

USER appuser
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
DOCKER_EOF

# ── Step 11: Create CI workflow ────────────────────────────────────────────────
progress "Creating GitHub Actions CI..."

cat > "$PROJECT_PATH/.github/workflows/ci.yml" << 'CI_EOF'
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v2
        with:
          version: latest

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      - name: Type check
        run: pnpm typecheck

      - name: Unit tests
        run: pnpm test:unit

      - name: Install Playwright browsers
        run: pnpm exec playwright install --with-deps chromium

      - name: E2E tests
        run: pnpm test:e2e

      - name: Upload test results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: |
            playwright-report/
            test-results/
CI_EOF

# ── Step 12: Create CLAUDE.md (comprehensive, all rules) ──────────────────────
progress "Creating CLAUDE.md (all rules)..."

cat > "$PROJECT_PATH/CLAUDE.md" << 'CLAUDEMD_EOF'
# CLAUDE.md — Project Instructions

---

## Quick Reference — Scripts

| Command | What it does |
|---------|-------------|
| `pnpm dev` | Start dev server on port 3000 |
| `pnpm build` | Build for production |
| `pnpm start` | Run production build |
| `pnpm typecheck` | TypeScript type-check only |
| **Testing** | |
| `pnpm test` | Run ALL tests (unit + E2E) |
| `pnpm test:unit` | Unit/integration tests (Vitest) |
| `pnpm test:unit:watch` | Unit tests in watch mode |
| `pnpm test:coverage` | Unit tests with coverage |
| `pnpm test:e2e` | E2E tests (kills test ports first) |
| `pnpm test:e2e:ui` | E2E with Playwright UI |
| `pnpm test:e2e:headed` | E2E with visible browser |
| `pnpm test:kill-ports` | Kill test ports (4000, 4010, 4020) |
| **Database** | |
| `pnpm db:query <name>` | Run a dev/test database query |
| `pnpm db:query:list` | List all registered queries |

---

## Critical Rules

### 0. NEVER Publish Sensitive Data

- NEVER commit passwords, API keys, tokens, or secrets to git/npm/docker
- NEVER commit `.env` files — ALWAYS verify `.env` is in `.gitignore`
- Before ANY commit: verify no secrets are included
- NEVER output secrets in suggestions, logs, or responses

### 1. TypeScript Always

- ALWAYS use TypeScript for new files (strict mode)
- NEVER use `any` unless absolutely necessary and documented why
- When editing JavaScript files, convert to TypeScript first
- Types are specs — they tell you what functions accept and return

### 2. API Versioning

```
CORRECT: /api/v1/users
WRONG:   /api/users
```

Every API endpoint MUST use `/api/v1/` prefix. No exceptions.

### 3. Database Access — StrictDB

**ALL database access uses StrictDB directly. No exceptions.**

- Install `strictdb` + your driver, use `StrictDB.create()` at app startup
- NEVER import native database drivers (`mongodb`, `pg`, etc.) directly
- Share a single StrictDB instance across the application
- All query inputs are automatically sanitized against injection

**Test queries go through `scripts/db-query.ts`:**
1. Create a query file in `scripts/queries/<name>.ts`
2. Register it in `scripts/db-query.ts`
3. NEVER create standalone scripts or inline queries in `src/`

### 4. Testing — Explicit Success Criteria

- ALWAYS define explicit success criteria for E2E tests
- "Page loads" is NOT a success criterion
- Every E2E test MUST verify: URL, visible elements, data displayed
- Minimum 3 assertions per test

```typescript
// CORRECT
await expect(page).toHaveURL('/dashboard');
await expect(page.locator('h1')).toContainText('Welcome');
await expect(page.locator('[data-testid="user"]')).toContainText('test@example.com');

// WRONG — no assertions
await page.goto('/dashboard');
```

### 5. NEVER Hardcode Credentials

- ALWAYS use environment variables for secrets
- NEVER put API keys, passwords, or tokens directly in code
- NEVER hardcode connection strings — use environment variables from .env

### 6. ALWAYS Ask Before Deploying

- NEVER auto-deploy, even if the fix seems simple
- NEVER assume approval — wait for explicit "yes, deploy"

### 7. Quality Gates

- No file > 300 lines (split if larger)
- No function > 50 lines (extract helpers)
- All tests must pass before committing
- TypeScript must compile with no errors

### 8. Parallelize Independent Awaits

```typescript
// CORRECT — independent operations in parallel
const [users, products] = await Promise.all([getUsers(), getProducts()]);

// WRONG — sequential when independent
const users = await getUsers();
const products = await getProducts();
```

### 9. Git Workflow — NEVER Work Directly on Main

**Auto-branch hook is ON by default.** ALWAYS branch BEFORE editing any files:

```bash
git branch --show-current
# If on main → create a feature branch IMMEDIATELY:
git checkout -b feat/<task-name>
```

### 10. Docker Push Gate

When enabled, ANY `docker push` is BLOCKED until the image passes local verification.

---

## Service Ports (FIXED)

| Service | Dev Port | Test Port |
|---------|----------|-----------|
| Website | 3000 | 4000 |
| API | 3001 | 4010 |
| Dashboard | 3002 | 4020 |

---

## When Something Seems Wrong

- Missing UI element? → Check feature gates BEFORE assuming bug
- Empty data? → Check if services are running BEFORE assuming broken
- 404 error? → Check service separation BEFORE adding endpoint
- Auth failing? → Check which auth system BEFORE debugging
- Test failing? → Read the error message fully BEFORE changing code

---

## Project Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| `project-docs/ARCHITECTURE.md` | System overview & data flow | Before architectural changes |
| `project-docs/INFRASTRUCTURE.md` | Deployment details | Before environment changes |
| `project-docs/DECISIONS.md` | Architectural decisions | Before proposing alternatives |

**ALWAYS read relevant docs before making cross-service changes.**

---

## Workflow Preferences

- Quality over speed — if unsure, ask before executing
- Plan first, code second — use plan mode for non-trivial tasks
- One task, one chat — `/clear` between unrelated tasks
- When testing: queue observations, fix in batch (not one at a time)

---

## Naming — NEVER Rename Mid-Project

If you must rename packages, modules, or key variables:

1. Create a checklist of ALL files and references first
2. Use IDE semantic rename (not search-and-replace)
3. Full project search for old name after renaming
4. Check: .md files, .txt files, .env files, comments, strings, paths
5. Start a FRESH Claude session after renaming
CLAUDEMD_EOF

cat > "$PROJECT_PATH/CLAUDE.local.md" << 'LOCALMD_EOF'
# CLAUDE.local.md — Personal Overrides

> **This file is gitignored.** It's for YOUR personal preferences — things that shouldn't be shared with the team.
>
> **When to use this vs CLAUDE.md:**
> - `CLAUDE.md` = team rules (checked into git, everyone follows them)
> - `CLAUDE.local.md` = personal preferences (gitignored, only affects you)

---

## My Identity

- GitHub: YourUsername
- SSH: `git@github.com:YourUsername/<repo>.git`

## Communication Style

<!-- Uncomment the style that fits you: -->
<!-- - Respond concisely — I prefer terse explanations -->
<!-- - Be thorough — explain your reasoning in detail -->
<!-- - Show me the code first, explain after -->

## Commit Preferences

- When creating commits, use conventional commit format (feat:, fix:, docs:, etc.)

## Local Environment

- Node version: 20.x
- Package manager: pnpm
- OS: (your OS here)
LOCALMD_EOF

# ── Step 13: Create project templates + config files ──────────────────────────
progress "Creating project docs + config files..."

cat > "$PROJECT_PATH/project-docs/ARCHITECTURE.md" << 'ARCH_EOF'
# Architecture

> System overview and data flow for the project.

## Overview

<!-- Describe the high-level architecture here -->

## Components

<!-- List major components and their responsibilities -->

## Data Flow

<!-- Describe how data moves through the system -->

## Dependencies

<!-- List external services and dependencies -->
ARCH_EOF

cat > "$PROJECT_PATH/project-docs/INFRASTRUCTURE.md" << 'INFRA_EOF'
# Infrastructure

> Deployment and environment details.

## Environments

<!-- List environments: development, staging, production -->

## Deployment

<!-- Describe the deployment process -->

## Environment Variables

<!-- List required environment variables and their purpose -->

## Monitoring

<!-- Describe monitoring and alerting setup -->
INFRA_EOF

cat > "$PROJECT_PATH/project-docs/DECISIONS.md" << 'DEC_EOF'
# Architectural Decisions

> Record of key technical decisions and their rationale.

## Template

### Decision: [Title]
- **Date:** YYYY-MM-DD
- **Status:** Accepted / Superseded / Deprecated
- **Context:** What prompted the decision
- **Decision:** What was decided
- **Consequences:** What are the trade-offs
- **Alternatives considered:** What else was evaluated

---

<!-- Add decisions below -->
DEC_EOF

cat > "$PROJECT_PATH/tests/CHECKLIST.md" << 'CHECK_EOF'
# Test Checklist

> Track what needs testing and what's been verified.

## Test Coverage

| Area | Unit Tests | Integration Tests | E2E Tests | Status |
|------|-----------|-------------------|-----------|--------|
| <!-- feature --> | <!-- yes/no --> | <!-- yes/no --> | <!-- yes/no --> | <!-- pending/done --> |

## Manual Test Cases

- [ ] <!-- Describe manual test case -->

## Regression Tests

- [ ] <!-- Describe regression test case -->
CHECK_EOF

cat > "$PROJECT_PATH/tests/ISSUES_FOUND.md" << 'ISSUES_EOF'
# Issues Found During Testing

> Track bugs and issues discovered during testing sessions.

## Template

### Issue: [Title]
- **Found:** YYYY-MM-DD
- **Severity:** Critical / High / Medium / Low
- **Status:** Open / Fixed / Won't Fix
- **Description:** What happened
- **Steps to reproduce:** How to trigger the issue
- **Expected behavior:** What should happen
- **Actual behavior:** What actually happened
- **Fix:** How it was resolved (if fixed)

---

<!-- Add issues below -->
ISSUES_EOF

# robots.txt + sitemap.xml
cat > "$PROJECT_PATH/public/robots.txt" << 'ROBOTS_EOF'
User-agent: *
Allow: /
Sitemap: https://example.com/sitemap.xml
ROBOTS_EOF

cat > "$PROJECT_PATH/public/sitemap.xml" << 'SITEMAP_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <priority>1.0</priority>
  </url>
</urlset>
SITEMAP_EOF

# JSON-LD structured data component
cat > "$PROJECT_PATH/src/app/json-ld.tsx" << 'JSONLD_EOF'
export function JsonLd() {
  const structuredData = {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: 'My App',
    url: process.env.NEXT_PUBLIC_SITE_URL || 'https://example.com',
    description: 'Built with Claude Code Mastery Starter Kit',
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
    />
  );
}
JSONLD_EOF

# ── Step 14: Create .env + .gitignore + .dockerignore + README ────────────────
progress "Creating .env, .gitignore, .dockerignore, README..."

touch "$PROJECT_PATH/.env"

cat > "$PROJECT_PATH/.env.example" << 'ENVEX_EOF'
# Application
NODE_ENV=development
PORT=3000

# StrictDB
STRICTDB_URI=mongodb+srv://user:password@cluster.mongodb.net/mydb?retryWrites=true&w=majority

# Rybbit Analytics
NEXT_PUBLIC_RYBBIT_SITE_ID=your_rybbit_site_id
NEXT_PUBLIC_RYBBIT_URL=https://app.rybbit.io

# Docker Hub
DOCKER_HUB_USER=your_docker_username
DOCKER_IMAGE_NAME=your_docker_username/your_app_name

# Dokploy Deployment
DOKPLOY_URL=http://your-vps-ip:3000/api
DOKPLOY_API_KEY=your_dokploy_api_key
DOKPLOY_APP_ID=your_application_id
DOKPLOY_REFRESH_TOKEN=your_webhook_refresh_token

# RuleCatch (optional)
RULECATCH_API_KEY=dc_your_api_key_here
RULECATCH_REGION=us
ENVEX_EOF

cat > "$PROJECT_PATH/.gitignore" << 'GI_EOF'
# Environment
.env
.env.*
.env.local

# Dependencies
node_modules/

# Build output
.next/
dist/
out/

# Test artifacts
coverage/
test-results/
playwright-report/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Claude local overrides
CLAUDE.local.md

# Temporary AI research files
_ai_temp/
GI_EOF

cat > "$PROJECT_PATH/.dockerignore" << 'DI_EOF'
.env
.env.*
.git/
node_modules/
.next/
dist/
coverage/
test-results/
playwright-report/
*.md
!README.md
_ai_temp/
DI_EOF

cat > "$PROJECT_PATH/README.md" << README_EOF
# $PROJECT_NAME

> Scaffolded with [Claude Code Mastery Starter Kit](https://github.com/TheDecipherist/claude-code-mastery-project-starter-kit) (default profile)

## Tech Stack

- **Framework:** Next.js (App Router)
- **Language:** TypeScript (strict mode)
- **Database:** StrictDB (unified driver)
- **Styling:** Tailwind CSS
- **Testing:** Vitest (unit) + Playwright (E2E)
- **Deployment:** Docker (multi-stage, standalone)

## Getting Started

\`\`\`bash
pnpm install
pnpm dev
\`\`\`

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Available Commands

Run \`/help\` in Claude Code to see all 16 available commands.

## Scripts

| Command | Description |
|---------|-------------|
| \`pnpm dev\` | Start dev server |
| \`pnpm build\` | Build for production |
| \`pnpm test\` | Run all tests |
| \`pnpm test:unit\` | Unit tests |
| \`pnpm test:e2e\` | E2E tests |
| \`pnpm db:query <name>\` | Run a database query |
| \`pnpm db:query:list\` | List available queries |

## Project Documentation

| Document | Purpose |
|----------|---------|
| \`project-docs/ARCHITECTURE.md\` | System overview & data flow |
| \`project-docs/INFRASTRUCTURE.md\` | Deployment details |
| \`project-docs/DECISIONS.md\` | Architectural decisions |
README_EOF

# ── Step 15: Git init + pnpm install + register project ───────────────────────
progress "Git init + pnpm install + registering project..."

git -C "$PROJECT_PATH" init -q
git -C "$PROJECT_PATH" add -A
git -C "$PROJECT_PATH" commit -q -m "Initial project scaffold (default profile)"

# Install dependencies
cd "$PROJECT_PATH" && pnpm install --silent 2>/dev/null || true

# Register in project registry
python3 << PYEOF
import json, os
from datetime import datetime, timezone

registry = "$REGISTRY"
if os.path.exists(registry):
    with open(registry) as f:
        data = json.load(f)
else:
    os.makedirs(os.path.dirname(registry), exist_ok=True)
    data = {"projects": []}

data["projects"].append({
    "name": "$PROJECT_NAME",
    "path": os.path.realpath("$PROJECT_PATH"),
    "profile": "default",
    "language": "node",
    "framework": "next",
    "database": "mongo",
    "createdAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
})

with open(registry, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

# ── Summary ────────────────────────────────────────────────────────────────────
END_NS=$(date +%s%N)
TOTAL_MS=$(( (END_NS - START_NS) / 1000000 ))
FILE_COUNT=$(find "$PROJECT_PATH" -type f -not -path '*/.git/*' -not -path '*/node_modules/*' | wc -l)

# Format elapsed time
if [ "$TOTAL_MS" -ge 1000 ]; then
  TOTAL_S=$((TOTAL_MS / 1000))
  TOTAL_FRAC=$(( (TOTAL_MS % 1000) / 100 ))
  TIME_STR="${TOTAL_S}.${TOTAL_FRAC}s"
else
  TIME_STR="${TOTAL_MS}ms"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Completed in ${TIME_STR}"
echo "  Created at: $PROJECT_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ${FILE_COUNT} files  |  16 commands  |  2 skills  |  2 agents  |  9 hooks"
echo ""
echo "  Stack: Next.js + StrictDB + Tailwind + Docker"
echo "  Testing: Vitest (unit) + Playwright (E2E)"
echo "  CI: GitHub Actions"
echo ""
echo "  Next steps:"
echo "    cd $PROJECT_PATH"
echo "    pnpm dev          # Start dev server"
echo "    claude             # Start Claude Code — run /help to see commands"
echo ""
echo "  Configure environment:"
echo "    cp .env.example .env"
echo "    # Edit .env with your StrictDB URI, Rybbit ID, etc."
echo "    # Or run /setup in Claude for interactive configuration"
echo ""
