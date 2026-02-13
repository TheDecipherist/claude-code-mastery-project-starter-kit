---
description: Analyze and optimize Docker builds for production
argument-hint: [dockerfile-path]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Optimize Docker Build

Analyze and optimize the Docker setup for: **$ARGUMENTS**

If no Dockerfile path provided, search for Dockerfiles in the project root.

## Step 0 — Auto-Branch (if on main)

Before modifying any files, check the current branch:

```bash
git branch --show-current
```

**Default behavior** (`auto_branch = true` in `claude-mastery-project.conf`):
- If on `main` or `master`: automatically create a feature branch and switch to it:
  ```bash
  git checkout -b chore/docker-optimize
  ```
  Report: "Created branch `chore/docker-optimize` — main stays untouched."
- If already on a feature branch: proceed
- If not a git repo: skip this check

**To disable:** Set `auto_branch = false` in `claude-mastery-project.conf`. When disabled, warn and ask the user before proceeding on main.

## Step 1 — Find and Read All Docker Files

Read these files (if they exist):
- `Dockerfile` (or the path provided in $ARGUMENTS)
- `docker-compose.yml` / `docker-compose.yaml`
- `.dockerignore`
- `package.json` (for build scripts and dependencies)

## Step 2 — Audit Against Best Practices

Check every rule below. For each violation, report:
- What's wrong
- Why it matters (performance impact or security risk)
- The fix

### RULE 1: Multi-Stage Builds (MANDATORY)

Every production Dockerfile MUST use multi-stage builds. No exceptions.

```dockerfile
# CORRECT — multi-stage: build artifacts don't ship to production
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
CMD ["node", "dist/index.js"]

# WRONG — single stage ships devDependencies, source code, build tools
FROM node:20
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
CMD ["node", "dist/index.js"]
```

**Why:** Single-stage images are 3-10x larger. They ship TypeScript source, devDependencies, build tools — none of which are needed at runtime.

### RULE 2: Layer Caching — COPY package.json FIRST

```dockerfile
# CORRECT — package.json copied before source (cached unless deps change)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .

# WRONG — any source change busts the install cache
COPY . .
RUN pnpm install
```

**Why:** Docker caches layers top-down. If `package.json` hasn't changed, the `install` layer is cached. Copying all files first means every code change re-installs all dependencies.

### RULE 3: Use Alpine Base Images

```dockerfile
# CORRECT — alpine is ~50MB
FROM node:20-alpine

# WRONG — full image is ~350MB
FROM node:20
```

**Why:** Alpine is 7x smaller. Less attack surface, faster pulls, smaller registry storage.

### RULE 4: Non-Root User

```dockerfile
# CORRECT — run as non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# WRONG — running as root
CMD ["node", "dist/index.js"]
```

**Why:** Running as root inside a container means a container escape gives root on the host. Always drop privileges.

### RULE 5: .dockerignore Exists and Is Complete

Must include at minimum:
```
.env
.env.*
.git/
node_modules/
dist/
coverage/
test-results/
playwright-report/
.claude/
CLAUDE.local.md
*.log
```

**Why:** Without `.dockerignore`, `COPY . .` sends `.git/` (huge), `node_modules/` (reinstalled anyway), `.env` (secrets!), and test artifacts into the build context.

### RULE 6: Frozen Lockfile for Installs

```dockerfile
# CORRECT — deterministic installs
RUN pnpm install --frozen-lockfile
RUN npm ci

# WRONG — may resolve different versions
RUN pnpm install
RUN npm install
```

**Why:** `install` can resolve newer patch versions than what was tested. `--frozen-lockfile` / `ci` ensures exact versions from the lockfile.

### RULE 7: Explicit EXPOSE

```dockerfile
# CORRECT — documents the port
EXPOSE 3001
CMD ["node", "dist/index.js"]

# WRONG — no EXPOSE
CMD ["node", "dist/index.js"]
```

**Why:** `EXPOSE` documents which ports the container listens on. Required for Docker networking and orchestrators.

### RULE 8: No Secrets in Build Args (for runtime secrets)

```dockerfile
# CORRECT — runtime secrets via environment
ENV DATABASE_URL=""
# Set at runtime: docker run -e DATABASE_URL=...

# WRONG — baked into image layer
ARG DATABASE_URL
RUN echo $DATABASE_URL > /app/.env
```

**Exception:** `NEXT_PUBLIC_*` variables for Next.js MUST be build args (they're baked into the JS bundle at build time). This is expected and safe — they're public values.

### RULE 9: Health Check

```dockerfile
# CORRECT — Docker knows if the app is healthy
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1
```

**Why:** Without HEALTHCHECK, Docker considers the container healthy as long as the process is running — even if it's deadlocked or returning 500s.

### RULE 10: Minimize Layers

```dockerfile
# CORRECT — single RUN for related commands
RUN corepack enable && \
    corepack prepare pnpm@latest --activate && \
    pnpm install --frozen-lockfile

# WRONG — each RUN creates a layer
RUN corepack enable
RUN corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile
```

**Why:** Each `RUN` creates a cached layer. Fewer layers = smaller image and faster builds.

### RULE 11: Production-Only Dependencies in Runner

```dockerfile
# CORRECT — only production deps in final image
FROM node:20-alpine AS runner
COPY --from=builder /app/package.json ./
RUN pnpm install --prod --frozen-lockfile

# OR: prune in builder stage
FROM node:20-alpine AS builder
RUN pnpm install --frozen-lockfile
RUN pnpm build
RUN pnpm prune --prod
```

**Why:** devDependencies (TypeScript, Vitest, Playwright, tsx) are only needed for building. Shipping them adds 100-500MB to the final image.

### RULE 12: Pin Major Versions

```dockerfile
# CORRECT — predictable
FROM node:20-alpine

# WRONG — could be 20, 22, 24 tomorrow
FROM node:alpine
FROM node:latest
```

**Why:** `latest` or unversioned tags change without notice. Your build may suddenly break on a Node.js major version bump.

## Step 3 — Generate Optimized Dockerfile

If the current Dockerfile violates any rules above, generate a corrected version.

Use this template as a starting point:

```dockerfile
# ============================================
# Stage 1: Build
# ============================================
FROM node:20-alpine AS builder
WORKDIR /app

# Enable pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Install dependencies (cached unless package.json changes)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Build args for public env vars (Next.js only)
# ARG NEXT_PUBLIC_RYBBIT_SITE_ID
# ARG NEXT_PUBLIC_RYBBIT_URL

# Copy source and build
COPY . .
RUN pnpm build

# Prune dev dependencies
RUN pnpm prune --prod

# ============================================
# Stage 2: Production
# ============================================
FROM node:20-alpine AS runner
WORKDIR /app

# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only what's needed
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

# Runtime config
ENV NODE_ENV=production
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

USER appuser
CMD ["node", "dist/index.js"]
```

## Step 4 — Verify .dockerignore

If `.dockerignore` is missing or incomplete, create/update it with all required entries.

## Step 5 — RuleCatch Report

After all changes are complete, check RuleCatch:

- If the RuleCatch MCP server is available: query for violations in the modified Docker files
- Report any violations found
- If no MCP: suggest checking the RuleCatch dashboard

## Step 6 — Report

Output a summary:
- Image size estimate (before vs after)
- Number of violations found and fixed
- Layer count (before vs after)
- Security improvements made
