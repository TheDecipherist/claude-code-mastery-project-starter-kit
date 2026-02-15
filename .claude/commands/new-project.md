---
description: Create a new project with all scaffolding rules applied
argument-hint: <path> [profile-or-options...]
allowed-tools: Bash, Write, Read, AskUserQuestion
---

# New Project Scaffold

Create a new project with all best practices from the Claude Code Mastery Guides.

**Arguments:** $ARGUMENTS

## Argument Parsing

### Step 0 — Read the config file

Before parsing arguments, read `claude-mastery-project.conf` (in the starter kit root or `~/.claude/claude-mastery-project.conf` as fallback).

Extract the `[global]` section for `root_dir` and `default_profile`.

- `root_dir` — Default parent directory for new projects
- `default_profile` — Profile to use when no profile is specified in arguments (e.g., `default_profile = clean`). If not set, ask the user as before.

### Step 0.0 — Global Claude Config (one-time setup)

Check if the user already has the global Claude config installed:

```bash
# Check if global CLAUDE.md exists
ls ~/.claude/CLAUDE.md 2>/dev/null
```

**If `~/.claude/CLAUDE.md` does NOT exist:**
- ASK: "You don't have a global CLAUDE.md yet. Want me to install the Claude Code Mastery global config to `~/.claude/`? This sets up security rules, hooks, and standards that apply to ALL your projects. (This is a one-time setup.)"
- If yes: copy `global-claude-md/CLAUDE.md` → `~/.claude/CLAUDE.md` and `global-claude-md/settings.json` → `~/.claude/settings.json`
- Also copy hooks: `mkdir -p ~/.claude/hooks && cp .claude/hooks/block-secrets.py ~/.claude/hooks/ && cp .claude/hooks/verify-no-secrets.sh ~/.claude/hooks/`

**If `~/.claude/CLAUDE.md` DOES exist:**
- ASK: "You already have a global CLAUDE.md. Want me to check if the starter kit version has anything new to merge in?"
- If yes: diff the two files and show what's different. Let the user decide what to merge.
- If no: skip and continue.

**This step typically only happens once.** After the first install, the global config persists across all projects.

### Step 0.1 — Resolve the project path

The **first argument** is the project name or path. Resolve it using `root_dir`:

1. **Explicit path** (starts with `./`, `../`, `~/`, or `/`) → use as-is
   - `/new-project ~/code/my-app` → creates at `~/code/my-app`
   - `/new-project ./my-app` → creates at `./my-app`

2. **Just a name** (no path separators) → prepend `root_dir` from `[global]`
   - Config has `root_dir = ~/projects`
   - `/new-project my-app` → creates at `~/projects/my-app`
   - `/new-project tims-api` → creates at `~/projects/tims-api`

3. **No argument at all** → ASK the user for the project name, then prepend `root_dir`

Everything after the project name/path is shorthand options or a profile name.

### Shorthand Arguments (after the path/name)

Parse remaining $ARGUMENTS for these keywords:

**Profiles:** `clean`, `default`, `api`, `static-site`, `quick`, `enterprise`, `go`, `vue`, `nuxt`, `svelte`, `sveltekit`, `angular`, `python-api`, `django`, `flask` (from `claude-mastery-project.conf`)
**Special:** `clean` — Claude infrastructure only, zero coding opinions (see Clean Mode below)
**Languages:** `go`, `golang` (triggers Go scaffolding — see Go Mode below) | `python`, `py` (triggers Python Mode below)
**Project types:** `webapp`, `api`, `fullstack`, `cli`
**Frameworks:** `vite`, `react`, `next`, `nextjs`, `astro`, `fastify`, `express`, `hono`, `vue`, `nuxt`, `svelte`, `sveltekit`, `angular`
**Go Frameworks:** `gin`, `chi`, `echo`, `fiber`, `stdlib`
**Python Frameworks:** `fastapi`, `django`, `flask`
**Options:** `seo`, `ssr`, `tailwind`, `prisma`, `docker`, `ci`, `multiregion`
**Hosting:** `dokploy`, `vercel`, `static`
**Database:** `mongo`, `postgres`, `mysql`, `mssql`, `sqlite`
**Analytics:** `rybbit`
**MCP servers:** `playwright`, `context7`, `rulecatch`
**NPM extras:** `ai-pooler` (installs @rulecatch/ai-pooler)
**Package managers:** `pnpm`, `npm`, `bun`

Examples:
- `/new-project my-app` — creates at ~/projects/my-app (from root_dir), asks questions
- `/new-project my-app clean` — Claude infrastructure only, no coding opinions
- `/new-project my-app default` — creates at ~/projects/my-app with default profile
- `/new-project my-app fullstack next seo tailwind pnpm` — ~/projects/my-app, skips all questions
- `/new-project ./custom-path/my-app api fastify` — explicit path, ignores root_dir
- `/new-project ~/code/my-app default` — explicit path, uses default profile
- `/new-project my-app fullstack next mongo playwright context7 rulecatch` — full stack
- `/new-project my-api go` — Go API with Gin, MongoDB, Docker
- `/new-project my-api go chi postgres` — Go with Chi, PostgreSQL
- `/new-project my-cli go cli` — Go CLI with Cobra
- `/new-project my-app vue` — Vue 3 SPA with Tailwind
- `/new-project my-app nuxt` — Nuxt full-stack with MongoDB, Docker
- `/new-project my-app svelte` — Svelte SPA with Tailwind
- `/new-project my-app sveltekit` — SvelteKit full-stack with MongoDB, Docker
- `/new-project my-app angular` — Angular SPA with Tailwind
- `/new-project my-api python-api` — FastAPI with PostgreSQL, Docker
- `/new-project my-app django` — Django full-stack with PostgreSQL, Docker
- `/new-project my-api flask` — Flask API with PostgreSQL, Docker
- `/new-project my-api python fastapi postgres docker` — Python API with overrides

Any keyword not provided = check `default_profile` in `[global]` first, then ask the user. If `default_profile` is set (e.g., `default_profile = clean`) and no profile was specified in the arguments, use that profile automatically.

---

## Project Registry — MANDATORY Final Step (ALL modes)

**After EVERY successful project scaffold (Clean, Go, Python, or Node.js), register the project in `~/.claude/starter-kit-projects.json`.**

This enables `/projects-created` and `/remove-project` to track all projects.

### How to register

1. Read `~/.claude/starter-kit-projects.json` (create if it doesn't exist)
2. Append a new entry to the `projects` array:

```json
{
  "name": "my-app",
  "path": "/home/user/projects/my-app",
  "profile": "default",
  "language": "node",
  "framework": "next",
  "database": "mongo",
  "createdAt": "2025-01-15T10:30:00Z"
}
```

3. Write the updated file back

**Field mapping:**
- `name` — project directory name (last segment of path)
- `path` — absolute path to the project directory
- `profile` — profile name used (e.g., `clean`, `default`, `go`, `python-api`), or `custom` if built from shorthand args
- `language` — `node`, `go`, or `python`
- `framework` — the chosen framework (e.g., `next`, `gin`, `fastapi`), or `none` for clean mode
- `database` — `mongo`, `postgres`, `mysql`, `mssql`, `sqlite`, or `none`
- `createdAt` — ISO 8601 timestamp of creation

**If the file doesn't exist yet**, create it with:

```json
{
  "projects": []
}
```

**This step happens AFTER git init and initial commit, as the very last action before displaying the verification checklist.**

---

## Clean Mode — `clean`

**If `clean` is detected in arguments, skip ALL of Steps 1-2 below and follow this section instead.**

Clean mode gives the user every piece of Claude Code infrastructure without imposing ANY opinions about how they should code, what language to use, what framework to pick, or how to structure their source code.

### What `clean` creates

```
project/
├── CLAUDE.md              # Security rules ONLY (see below)
├── CLAUDE.local.md        # Personal overrides template
├── .claude/
│   ├── settings.json      # Hooks configuration
│   ├── commands/
│   │   ├── review.md
│   │   ├── commit.md
│   │   ├── progress.md
│   │   ├── test-plan.md
│   │   ├── architecture.md
│   │   ├── new-project.md
│   │   ├── security-check.md
│   │   ├── optimize-docker.md
│   │   ├── create-e2e.md
│   │   └── worktree.md
│   ├── skills/
│   │   ├── code-review/SKILL.md
│   │   └── create-service/SKILL.md
│   ├── agents/
│   │   ├── code-reviewer.md
│   │   └── test-writer.md
│   └── hooks/
│       ├── block-secrets.py
│       ├── lint-on-save.sh
│       └── verify-no-secrets.sh
├── project-docs/
│   ├── ARCHITECTURE.md
│   ├── INFRASTRUCTURE.md
│   └── DECISIONS.md
├── tests/
│   ├── CHECKLIST.md
│   └── ISSUES_FOUND.md
├── .env                   # Empty (NEVER commit)
├── .env.example           # Template with NODE_ENV and PORT
├── .gitignore             # Standard ignores
├── .dockerignore          # Standard ignores
└── README.md              # Minimal project readme
```

### What `clean` does NOT create

- No `src/` directory — user decides their own structure
- No `package.json` — user picks their own language, runtime, and package manager
- No `tsconfig.json` — user may not even use TypeScript
- No `vitest.config.ts` or `playwright.config.ts` — user picks their own test tools
- No database wrapper or `scripts/db-query.ts` — user picks their own database
- No content builder — user decides if they need one
- No SEO templates — user decides their own approach
- No port assignments — user decides their own ports
- No framework-specific configs — user picks their own framework

### Clean CLAUDE.md content

The CLAUDE.md for `clean` mode contains ONLY universal, non-opinionated rules:

```markdown
# CLAUDE.md — Project Instructions

---

## Critical Rules

### 0. NEVER Publish Sensitive Data

- NEVER commit passwords, API keys, tokens, or secrets to git/npm/docker
- NEVER commit `.env` files — ALWAYS verify `.env` is in `.gitignore`
- Before ANY commit: verify no secrets are included
- NEVER output secrets in suggestions, logs, or responses

### 1. NEVER Hardcode Credentials

- ALWAYS use environment variables for secrets
- NEVER put API keys, passwords, or tokens directly in code
- NEVER hardcode connection strings — use environment variables from .env

### 2. ALWAYS Ask Before Deploying

- NEVER auto-deploy, even if the fix seems simple
- NEVER assume approval — wait for explicit "yes, deploy"
- ALWAYS ask before deploying to production

---

## When Something Seems Wrong

Before jumping to conclusions:

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
```

### Clean mode steps

1. Resolve project path (same as Step 0 / 0.1 above)
2. Create the project directory
3. Copy ALL `.claude/` contents from the starter kit (commands, skills, agents, hooks, settings.json)
4. Create project-docs/ with ARCHITECTURE.md, INFRASTRUCTURE.md, DECISIONS.md templates
5. Create tests/ with CHECKLIST.md and ISSUES_FOUND.md
6. Create the clean CLAUDE.md (security rules only, as shown above)
7. Create CLAUDE.local.md template
8. Create .env (empty), .env.example (NODE_ENV + PORT only)
9. Create .gitignore and .dockerignore with standard entries
10. Create a minimal README.md
11. Initialize git and create initial commit
12. Report what was created

### Clean verification checklist

- [ ] `.claude/` directory with all commands, skills, agents, hooks
- [ ] `.claude/settings.json` with hooks wired up
- [ ] `CLAUDE.md` has ONLY security rules (no TypeScript, no ports, no quality gates)
- [ ] `project-docs/` has all three templates
- [ ] `tests/` has CHECKLIST.md and ISSUES_FOUND.md
- [ ] `.env` exists (empty)
- [ ] `.env.example` exists
- [ ] `.gitignore` includes .env, node_modules/, dist/, CLAUDE.local.md
- [ ] `.dockerignore` exists
- [ ] NO `package.json`, `tsconfig.json`, or framework configs created
- [ ] NO `src/` directory created
- [ ] Git initialized with initial commit

**After creating a `clean` project, the user can add their own language, framework, and structure — Claude will follow the security rules and use the slash commands without imposing any coding patterns.**

---

## Go Mode — `go` / `golang`

**If `go`, `golang`, or a Go framework (`gin`, `chi`, `echo`, `fiber`, `stdlib`) is detected in arguments, OR the resolved profile has `language = go`, skip ALL of Steps 1-2 below and follow this section instead.**

Go Mode scaffolds a Go project with standard layout conventions (`cmd/`, `internal/`), a Makefile-based build system, golangci-lint, and multi-stage Docker with `scratch` base image.

### Go Questions (skip any answered by arguments or profile)

#### Question G1: Project Type
"What type of Go project are you building?"
- **API** — REST API server (Recommended)
- **Web App** — HTTP server with templates
- **CLI** — Command-line tool
- **Full-Stack** — Go API backend + separate frontend

#### Question G2: Framework (based on project type)

**If API or Web App or Full-Stack:**
"Which Go HTTP framework?"
- **Gin** — Most popular Go web framework, fast, great middleware (Recommended)
- **Chi** — Lightweight, idiomatic, stdlib-compatible router
- **Echo** — High performance, extensible, automatic TLS
- **Fiber** — Express-inspired, built on fasthttp
- **stdlib** — Standard library `net/http` only, zero dependencies

**If CLI:**
- Use **Cobra** + **Viper** (no framework question needed)

#### Question G3: Database
"Which database?"
- **MongoDB** — Document database (Recommended for APIs)
- **PostgreSQL** — Relational database (Recommended for SQL)
- **MySQL** — Relational, widely deployed
- **MSSQL** — Microsoft SQL Server
- **SQLite** — Embedded, file-based, zero config
- **None** — No database

#### Question G4: Hosting / Deployment
"Where will this be deployed?" (same as Node.js options)
- **Dokploy on Hostinger VPS** — Self-hosted Docker containers (Recommended)
- **Vercel** — Not ideal for Go, but possible via serverless
- **Static hosting** — Not applicable for Go APIs
- **None / Decide later** — Skip deployment scaffolding

#### Question G5: Extras (multi-select)
"What extras do you want to include?"
- **Docker** — Multi-stage build with scratch base (5-15MB images)
- **GitHub Actions CI** — Automated testing pipeline (go test, go vet, golangci-lint)
- **golangci-lint** — Comprehensive Go linter (recommended, on by default)

### Go Project Structure

```
project/
├── cmd/
│   └── server/
│       └── main.go              # Entry point
├── internal/
│   ├── handlers/
│   │   └── health.go            # Health check handler
│   ├── middleware/
│   │   └── logging.go           # Request logging middleware
│   ├── models/
│   │   └── models.go            # Data models
│   └── database/
│       └── mongo.go             # Database layer (if MongoDB)
├── tests/
│   └── handlers_test.go         # Handler tests
├── scripts/
│   └── deploy.sh                # Deployment script (if Dokploy)
├── project-docs/
│   ├── ARCHITECTURE.md
│   ├── INFRASTRUCTURE.md
│   └── DECISIONS.md
├── .claude/
│   ├── commands/
│   ├── skills/
│   ├── agents/
│   ├── hooks/
│   └── settings.json
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile                   # Multi-stage: golang:1.23-alpine → scratch
├── .golangci.yml
├── .env
├── .env.example
├── .gitignore
├── .dockerignore
├── CLAUDE.md
├── CLAUDE.local.md
└── README.md
```

### Go Template: `cmd/server/main.go` (Gin)

```go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "3001"
	}

	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		v1.GET("/ping", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "pong"})
		})
	}

	srv := &http.Server{
		Addr:         ":" + port,
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		log.Printf("Server starting on :%s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}
	log.Println("Server exited")
}
```

**For other frameworks, adapt accordingly:**
- **Chi:** Use `chi.NewRouter()` with `chi.Use(middleware.Logger)` and `r.Route("/api/v1", ...)`
- **Echo:** Use `echo.New()` with `e.Use(middleware.Logger())` and `e.Group("/api/v1")`
- **Fiber:** Use `fiber.New()` with `app.Use(logger.New())` and `app.Group("/api/v1")`
- **stdlib:** Use `http.NewServeMux()` with `mux.Handle("/api/v1/", ...)` and manual middleware

### Go Template: `Makefile`

```makefile
BINARY_NAME=server
BUILD_DIR=bin
GO=go

.PHONY: all build run dev test test-cover lint vet fmt check clean

all: check build

build:
	CGO_ENABLED=0 $(GO) build -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/server

run: build
	./$(BUILD_DIR)/$(BINARY_NAME)

dev:
	@command -v air > /dev/null 2>&1 || $(GO) install github.com/air-verse/air@latest
	air

test:
	$(GO) test ./... -v

test-cover:
	$(GO) test ./... -coverprofile=coverage.out
	$(GO) tool cover -html=coverage.out -o coverage.html

lint:
	@command -v golangci-lint > /dev/null 2>&1 || $(GO) install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest
	golangci-lint run

vet:
	$(GO) vet ./...

fmt:
	$(GO) fmt ./...
	goimports -w .

check: vet lint

clean:
	rm -rf $(BUILD_DIR) coverage.out coverage.html
```

### Go Template: `Dockerfile` (multi-stage with scratch)

```dockerfile
# Stage 1: Builder
FROM golang:1.23-alpine AS builder
WORKDIR /app

# Install git for go mod download (some deps need it)
RUN apk add --no-cache git

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build static binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

# Stage 2: Scratch (minimal image)
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /server /server

EXPOSE 3001
ENTRYPOINT ["/server"]
```

### Go Template: `.golangci.yml`

```yaml
run:
  timeout: 3m

linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - unused
    - gosimple
    - ineffassign
    - typecheck
    - gocritic
    - gofmt
    - goimports
    - misspell
    - nilerr
    - exhaustive

linters-settings:
  gocritic:
    enabled-tags:
      - diagnostic
      - style
      - performance
  errcheck:
    check-blank: true

issues:
  exclude-use-default: false
  max-issues-per-linter: 50
  max-same-issues: 10
```

### Go Template: `.gitignore`

```
# Binaries
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test
coverage.out
coverage.html

# Environment
.env
.env.*
.env.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Vendor (if not committed)
# vendor/

# Build artifacts
dist/
tmp/

# Claude local overrides
CLAUDE.local.md
```

### Go-Specific CLAUDE.md Rules

When creating a Go project, the CLAUDE.md MUST include these Go-specific rules:

```markdown
### Go Rules

#### Error Handling — NEVER Ignore Errors
- ALWAYS check returned errors — never use `_` to discard an error
- Use `fmt.Errorf("context: %w", err)` to wrap errors with context
- Return errors to callers — don't log and continue silently
- Use sentinel errors or custom error types for expected error conditions

#### Context Propagation — ALWAYS Pass context.Context
- Every function that does I/O (HTTP, DB, file) MUST accept `context.Context` as first param
- NEVER use `context.Background()` in handlers — use the request context `c.Request.Context()`
- Set timeouts on all external calls: `context.WithTimeout(ctx, 5*time.Second)`

#### Testing — Table-Driven Tests
- Use table-driven tests for functions with multiple input/output scenarios
- Test files MUST be in the same package (white-box) or `_test` package (black-box)
- Use `testify/assert` or stdlib `testing` — no other test frameworks
- Run tests with `make test` or `go test ./... -v`

#### Interfaces — Accept Interfaces, Return Structs
- Define interfaces at the consumer, not the implementer
- Keep interfaces small (1-3 methods)
- Use interfaces for dependency injection (database, HTTP clients, etc.)

#### No Global Mutable State
- NEVER use package-level `var` for mutable state
- Pass dependencies via struct fields or function parameters
- Configuration should be loaded once at startup and passed down

#### API Versioning
- ALL endpoints MUST use `/api/v1/` prefix — same rule as Node.js projects

#### Quality Gates
- No file > 300 lines (split into separate files in the same package)
- No function > 50 lines (extract helper functions)
- `go vet` and `golangci-lint` must pass before committing
- `go build ./...` must succeed with no errors

#### Graceful Shutdown — MANDATORY
- Every server MUST handle SIGINT and SIGTERM
- Close database connections before exiting
- Use `context.WithTimeout` for shutdown deadline
```

### Go Scaffolding Steps

1. Create project directory
2. Run `go mod init github.com/<username>/<project-name>` (get username from git config or ask)
3. Create Go directory structure: `cmd/server/`, `internal/handlers/`, `internal/middleware/`, `internal/models/`, `internal/database/` (if DB selected), `tests/`, `scripts/`
4. Write framework-specific `main.go` (using template above, adapted for chosen framework)
5. Write `internal/handlers/health.go` — health check handler
6. Write database layer `internal/database/` if database was selected
7. Create `Makefile` (using template above)
8. Create `Dockerfile` (multi-stage with scratch, using template above)
9. Create `.golangci.yml` (using template above)
10. Create Go-specific `CLAUDE.md` (with Go rules above + universal security rules)
11. Copy `.claude/` contents from starter kit (commands, skills, agents, hooks, settings.json)
12. Create `project-docs/` templates (ARCHITECTURE.md, INFRASTRUCTURE.md, DECISIONS.md)
13. Create `.env`, `.env.example`, `.gitignore` (Go-specific), `.dockerignore`
14. Create `CLAUDE.local.md` template
15. Create `README.md` with Go-specific instructions
16. Create `scripts/deploy.sh` if Dokploy hosting was selected
17. Run `go mod tidy` to resolve dependencies
18. Initialize git, create initial commit: "Initial Go project scaffold"
19. Display verification checklist

### Go Verification Checklist

After creation, verify and report:

**Core files:**
- [ ] `go.mod` exists with correct module path
- [ ] `go.sum` exists (after `go mod tidy`)
- [ ] `Makefile` exists with build, test, lint targets
- [ ] `.env` exists
- [ ] `.env.example` exists with PORT placeholder
- [ ] `.gitignore` includes Go-specific entries (bin/, *.exe, .env)
- [ ] `.dockerignore` exists
- [ ] `CLAUDE.md` has Go-specific rules (error handling, context, testing)
- [ ] `CLAUDE.local.md` exists

**Structure:**
- [ ] `cmd/server/main.go` exists with entry point
- [ ] `internal/handlers/health.go` exists
- [ ] `internal/middleware/` directory exists
- [ ] `internal/models/` directory exists
- [ ] `tests/` directory exists with at least one test
- [ ] `project-docs/` has ARCHITECTURE.md, INFRASTRUCTURE.md, DECISIONS.md
- [ ] `.claude/` has commands, skills, agents, hooks, settings.json

**Testing:**
- [ ] `go build ./...` succeeds
- [ ] `go vet ./...` passes
- [ ] `go test ./...` runs (even if no tests yet)

**Database (if selected):**
- [ ] `internal/database/` exists with connection layer
- [ ] Database URL in `.env.example`

**Docker (if selected):**
- [ ] `Dockerfile` exists with multi-stage build (golang:1.23-alpine → scratch)
- [ ] Final image is minimal (no compiler, no source code)

**Infrastructure:**
- [ ] `scripts/deploy.sh` exists (if Dokploy selected)
- [ ] `.golangci.yml` exists
- [ ] Git initialized with initial commit

**NOT present (Go projects should NOT have):**
- [ ] No `package.json` — this is a Go project
- [ ] No `tsconfig.json`
- [ ] No `node_modules/`
- [ ] No `vitest.config.ts` or `playwright.config.ts`

Report any missing items.

---

## Python Mode — `python` / `py` / `fastapi` / `django` / `flask`

**If `python`, `py`, or a Python framework (`fastapi`, `django`, `flask`) is detected in arguments, OR the resolved profile has `language = python`, skip ALL of Steps 1-2 below and follow this section instead.**

Python Mode scaffolds a Python project with modern tooling: type hints, async support, pytest, ruff linter, and virtual environment management.

### Python Questions (skip any answered by arguments or profile)

#### Question P1: Project Type
"What type of Python project are you building?"
- **API** — REST API server (Recommended)
- **Web App** — Server-rendered web application
- **CLI** — Command-line tool
- **Full-Stack** — Python API backend + separate frontend

#### Question P2: Framework (based on project type)

**If API or Full-Stack:**
"Which Python framework?"
- **FastAPI** — Modern, async, automatic OpenAPI docs, type-safe (Recommended)
- **Django** — Full-featured, batteries-included, ORM, admin panel
- **Flask** — Lightweight, flexible, large ecosystem

**If CLI:**
- Use **Typer** or **Click** (no framework question needed)

**If Web App:**
- **Django** — Full-featured with templates (Recommended)
- **Flask** — Lightweight with Jinja2 templates
- **FastAPI** — With Jinja2 templates

#### Question P3: Database
"Which database?"
- **PostgreSQL** — Recommended for Python APIs
- **MySQL** — Widely deployed
- **SQLite** — Embedded, zero config
- **MongoDB** — Document database
- **None** — No database

#### Question P4: Package Manager
"Which package manager?"
- **pip + venv** — Standard, universal (Recommended)
- **uv** — Fast, modern pip replacement
- **poetry** — Dependency management + packaging

#### Question P5: Hosting / Deployment
"Where will this be deployed?" (same as Node.js options)
- **Dokploy on Hostinger VPS** — Self-hosted Docker containers (Recommended)
- **Vercel** — Serverless Python
- **None / Decide later** — Skip deployment scaffolding

#### Question P6: Extras (multi-select)
"What extras do you want to include?"
- **Docker** — Multi-stage build with python:3.12-slim (Recommended)
- **GitHub Actions CI** — Automated testing pipeline (pytest, ruff)

### Python Project Structure

```
project/
├── src/
│   └── app/
│       ├── __init__.py
│       ├── main.py              # Entry point (FastAPI/Flask app)
│       ├── config.py            # Pydantic BaseSettings for env vars
│       ├── core/
│       │   └── db.py            # Database wrapper
│       ├── api/
│       │   └── v1/
│       │       ├── __init__.py
│       │       └── health.py    # Health check endpoint
│       ├── models/
│       │   └── __init__.py      # Pydantic/SQLAlchemy models
│       └── services/
│           └── __init__.py      # Business logic
├── tests/
│   ├── conftest.py              # pytest fixtures
│   ├── test_health.py           # Example test
│   └── e2e/                     # E2E tests (if web)
├── project-docs/
│   ├── ARCHITECTURE.md
│   ├── INFRASTRUCTURE.md
│   └── DECISIONS.md
├── .claude/
│   ├── commands/
│   ├── skills/
│   ├── agents/
│   ├── hooks/
│   └── settings.json
├── pyproject.toml               # Project metadata + tool config
├── requirements.txt             # Production dependencies
├── requirements-dev.txt         # Dev dependencies (pytest, ruff, etc.)
├── ruff.toml                    # Linter config
├── Makefile                     # dev, test, lint, format, run targets
├── Dockerfile                   # Multi-stage: python:3.12-slim
├── .env
├── .env.example
├── .gitignore                   # Python-specific (__pycache__, .venv, etc.)
├── .dockerignore
├── CLAUDE.md
├── CLAUDE.local.md
└── README.md
```

### Python Template: `src/app/main.py` (FastAPI)

```python
"""FastAPI application entry point."""
import signal
import sys
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    # Startup
    print(f"Starting server on port {settings.port}")
    yield
    # Shutdown
    print("Shutting down...")


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}


# API v1 routes
from app.api.v1 import health as health_router  # noqa: E402
app.include_router(health_router.router, prefix="/api/v1")


def handle_signal(signum: int, frame) -> None:
    """Handle termination signals gracefully."""
    print(f"Received signal {signum}, shutting down...")
    sys.exit(0)


signal.signal(signal.SIGINT, handle_signal)
signal.signal(signal.SIGTERM, handle_signal)
```

### Python Template: `src/app/config.py`

```python
"""Application configuration via environment variables."""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment."""
    app_name: str = "My API"
    port: int = 3001
    debug: bool = False
    database_url: str = ""

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
```

### Python Template: `tests/conftest.py`

```python
"""Shared test fixtures."""
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client():
    """Async HTTP client for testing."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
```

### Python Template: `tests/test_health.py`

```python
"""Health check endpoint tests."""
import pytest


@pytest.mark.anyio
async def test_health_returns_ok(client):
    """Health endpoint should return status ok."""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


@pytest.mark.anyio
async def test_api_v1_health(client):
    """API v1 health endpoint should be accessible."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
```

### Python Template: `pyproject.toml`

```toml
[project]
name = "PROJECT_NAME"
version = "0.1.0"
requires-python = ">=3.12"

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "A", "SIM", "TCH"]
ignore = ["E501"]
```

### Python Template: `Makefile`

```makefile
.PHONY: dev test lint format run install clean

install:
	python -m venv .venv
	.venv/bin/pip install -r requirements.txt -r requirements-dev.txt

dev:
	.venv/bin/uvicorn app.main:app --reload --host 0.0.0.0 --port 3001

run:
	.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 3001

test:
	.venv/bin/pytest -v

lint:
	.venv/bin/ruff check src/ tests/

format:
	.venv/bin/ruff format src/ tests/

clean:
	rm -rf __pycache__ .pytest_cache .ruff_cache htmlcov .coverage
	find . -type d -name __pycache__ -exec rm -rf {} +
```

### Python Template: `Dockerfile` (multi-stage)

```dockerfile
# Stage 1: Builder
FROM python:3.12-slim AS builder
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runner
FROM python:3.12-slim AS runner
WORKDIR /app

# Non-root user
RUN groupadd --system app && useradd --system --gid app app

COPY --from=builder /install /usr/local
COPY src/ ./src/

USER app
EXPOSE 3001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3001"]
```

### Python Template: `ruff.toml`

```toml
target-version = "py312"
line-length = 100

[lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "A", "SIM", "TCH"]
ignore = ["E501"]

[lint.isort]
known-first-party = ["app"]
```

### Python Template: `.gitignore`

```
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.venv/
venv/
env/

# Testing
.pytest_cache/
htmlcov/
.coverage

# Environment
.env
.env.*
.env.local

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
dist/
build/
*.egg-info/

# Claude local overrides
CLAUDE.local.md
```

### Python-Specific CLAUDE.md Rules

When creating a Python project, the CLAUDE.md MUST include these Python-specific rules:

```markdown
### Python Rules

#### Type Hints — ALWAYS
- EVERY function MUST have type hints for all parameters AND return type
- Use `str | None` (not `Optional[str]`) — Python 3.10+ union syntax
- Use `list[str]` (not `List[str]`) — built-in generics
- Pydantic models for all request/response shapes

#### Async/Await — Consistently
- FastAPI handlers MUST be `async def` when doing I/O
- Use `asyncpg` for PostgreSQL, `aiomysql` for MySQL
- NEVER mix sync and async database calls in the same project

#### Testing — pytest Only
- ALWAYS use pytest (never unittest)
- Use `httpx.AsyncClient` for testing FastAPI endpoints
- Use fixtures for shared setup (conftest.py)
- Table-driven tests with `@pytest.mark.parametrize`

#### Virtual Environment — MANDATORY
- ALWAYS use a virtual environment (.venv/)
- NEVER install packages globally
- requirements.txt for production, requirements-dev.txt for dev tools

#### API Versioning
- ALL endpoints MUST use `/api/v1/` prefix — same rule as Node.js and Go

#### Quality Gates
- No file > 300 lines (split into modules)
- No function > 50 lines (extract helper functions)
- `ruff check` must pass before committing
- `pytest` must pass before committing

#### Graceful Shutdown — MANDATORY
- Handle SIGINT and SIGTERM signals
- Close database connections before exiting
```

### Python Scaffolding Steps

1. Create project directory
2. Create Python directory structure: `src/app/`, `src/app/core/`, `src/app/api/v1/`, `src/app/models/`, `src/app/services/`, `tests/`
3. Write `src/app/main.py` (framework-specific entry point)
4. Write `src/app/config.py` (Pydantic BaseSettings)
5. Write `src/app/api/v1/health.py` (health check endpoint)
6. Write database layer `src/app/core/db.py` if database was selected
7. Write `tests/conftest.py` and `tests/test_health.py`
8. Create `pyproject.toml`, `requirements.txt`, `requirements-dev.txt`
9. Create `ruff.toml`
10. Create `Makefile` with dev, test, lint, format, run targets
11. Create `Dockerfile` (multi-stage with python:3.12-slim)
12. Create Python-specific CLAUDE.md (with Python rules + universal security rules)
13. Copy `.claude/` contents from starter kit (commands, skills, agents, hooks, settings.json)
14. Create `project-docs/` templates (ARCHITECTURE.md, INFRASTRUCTURE.md, DECISIONS.md)
15. Create `.env`, `.env.example`, `.gitignore` (Python-specific), `.dockerignore`
16. Create `CLAUDE.local.md` template
17. Create `README.md` with Python-specific instructions
18. Create virtual environment: `python -m venv .venv`
19. Install dependencies: `.venv/bin/pip install -r requirements.txt -r requirements-dev.txt`
20. Initialize git, create initial commit: "Initial Python project scaffold"
21. Display verification checklist

### Python Verification Checklist

After creation, verify and report:

**Core files:**
- [ ] `pyproject.toml` exists with project metadata
- [ ] `requirements.txt` exists
- [ ] `requirements-dev.txt` exists
- [ ] `ruff.toml` exists
- [ ] `Makefile` exists with dev, test, lint targets
- [ ] `.env` exists
- [ ] `.env.example` exists
- [ ] `.gitignore` includes Python-specific entries (__pycache__, .venv)
- [ ] `.dockerignore` exists
- [ ] `CLAUDE.md` has Python-specific rules
- [ ] `CLAUDE.local.md` exists

**Structure:**
- [ ] `src/app/main.py` exists with entry point
- [ ] `src/app/config.py` exists with settings
- [ ] `src/app/api/v1/health.py` exists
- [ ] `tests/conftest.py` exists
- [ ] `tests/test_health.py` exists
- [ ] `project-docs/` has ARCHITECTURE.md, INFRASTRUCTURE.md, DECISIONS.md
- [ ] `.claude/` has commands, skills, agents, hooks, settings.json

**Testing:**
- [ ] `.venv/` directory exists (virtual environment)
- [ ] `make test` runs pytest successfully
- [ ] `make lint` runs ruff successfully

**Database (if selected):**
- [ ] `src/app/core/db.py` exists with connection layer
- [ ] Database URL in `.env.example`

**Docker (if selected):**
- [ ] `Dockerfile` exists with multi-stage build (python:3.12-slim)

**NOT present (Python projects should NOT have):**
- [ ] No `package.json` — this is a Python project
- [ ] No `tsconfig.json`
- [ ] No `node_modules/`
- [ ] No `go.mod`

Report any missing items.

---

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

## Step 2 — Create the Project

Based on answers, scaffold the project:

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
│   └── agents/
└── scripts/
    ├── db-query.ts          # (MongoDB only) Test Query Master
    └── queries/             # (MongoDB only) Individual dev/test query files
```

## SQL Database Setup (projects with `postgres`, `mysql`, `mssql`, or `sqlite` database)

When the project uses a SQL database (PostgreSQL, MySQL, MSSQL, or SQLite), scaffold the SQL wrapper:

1. Copy `src/core/db/sql.ts` from the starter kit into the new project
2. Install the appropriate driver based on database choice:
   - PostgreSQL: `npm install pg @types/pg`
   - MySQL: `npm install mysql2`
   - MSSQL: `npm install mssql`
   - SQLite: `npm install better-sqlite3 @types/better-sqlite3`
3. Set `DATABASE_URL` in `.env.example` with placeholder
4. Add SQL wrapper rules to the project's CLAUDE.md

**The rule that MUST be in every SQL project's CLAUDE.md:**

> ALL SQL database access goes through `src/core/db/sql.ts`. No exceptions.
> NEVER create connection pools anywhere else.
> NEVER import database drivers directly outside the wrapper.
> ALWAYS use parameterized queries — NEVER string-interpolate values into SQL.

**DATABASE_URL examples for .env.example:**
```bash
# PostgreSQL
DATABASE_URL=postgresql://user:password@localhost:5432/mydb

# MySQL
DATABASE_URL=mysql://user:password@localhost:3306/mydb

# MSSQL
DATABASE_URL=mssql://user:password@localhost:1433/mydb

# SQLite
DATABASE_URL=file:./data/app.db
```

## MongoDB Test Query System (projects with `mongo` database)

When the project uses MongoDB, ALWAYS scaffold the db-query system:

1. Create `scripts/db-query.ts` — the master index/CLI runner
2. Create `scripts/queries/` directory for individual query files
3. Add the db-query rules to the project's `CLAUDE.md`

**The rule that MUST be in every MongoDB project's CLAUDE.md:**

> ALL ad-hoc / test / dev database queries go through `scripts/db-query.ts`.
> When asked to look something up in the database:
> 1. Create a query file in `scripts/queries/<name>.ts`
> 2. Register it in `scripts/db-query.ts`
> 3. NEVER create standalone scripts or inline queries in `src/`

This prevents Claude from scattering random query scripts all over the project.

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

Add to EVERY Node.js entry point. If the project uses MongoDB, use `gracefulShutdown` to close pools before exit:

```typescript
// WITH MongoDB (projects using src/core/db/)
import { gracefulShutdown } from '@/core/db/index.js';

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
// WITHOUT MongoDB (no database or non-Mongo projects)
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});
```

## Mandatory SEO (ALL Web Projects)

Every web project MUST include these SEO fundamentals. This is non-negotiable for any page that serves HTML.

### 1. HTML Meta Tags (in layout/head)

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title — Site Name</title>
  <meta name="description" content="Concise page description (150-160 chars)">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="https://example.com/current-page">

  <!-- Open Graph (Facebook, LinkedIn, Discord) -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Page description">
  <meta property="og:image" content="https://example.com/og-image.png">
  <meta property="og:url" content="https://example.com/current-page">
  <meta property="og:site_name" content="Site Name">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Page description">
  <meta name="twitter:image" content="https://example.com/og-image.png">
</head>
```

### 2. JSON-LD Structured Data (schema.org)

EVERY web project must include at minimum an Organization or WebSite schema:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Your Site Name",
  "url": "https://example.com",
  "description": "Site description",
  "publisher": {
    "@type": "Organization",
    "name": "Your Organization",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  }
}
</script>
```

For specific page types, add the appropriate schema:
- **Article pages:** `@type: "Article"` with author, datePublished, dateModified
- **Product pages:** `@type: "Product"` with price, availability, reviews
- **FAQ pages:** `@type: "FAQPage"` with question/answer pairs
- **How-to pages:** `@type: "HowTo"` with steps
- **Breadcrumbs:** `@type: "BreadcrumbList"` on all pages with navigation depth

### 3. Technical SEO Files

Create these in the project root (or public directory):

**robots.txt:**
```
User-agent: *
Allow: /
Sitemap: https://example.com/sitemap.xml
```

**sitemap.xml** (or generate dynamically):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2025-01-01</lastmod>
    <priority>1.0</priority>
  </url>
</urlset>
```

### 4. Performance SEO

- Images MUST use WebP format with `alt` attributes
- Include `<link rel="preconnect">` for external domains (fonts, analytics, CDNs)
- Set proper cache headers for static assets
- Ensure Largest Contentful Paint (LCP) < 2.5 seconds

### 5. Framework-Specific SEO

**Next.js:**
- Use `metadata` export in layout.tsx / page.tsx (App Router)
- Use `generateMetadata()` for dynamic pages
- JSON-LD via `<script>` in layout or use `next-seo` package
- next/image for automatic WebP conversion and lazy loading
- Automatic sitemap generation with `next-sitemap`

**Vite + React (SPA):**
- Use `react-helmet-async` for dynamic `<head>` management
- For SEO-critical SPAs, consider prerendering with `vite-plugin-ssr` or `prerender-spa-plugin`
- NOTE: SPAs have inherent SEO limitations — if SEO is critical, recommend SSR

**Astro:**
- Built-in `<head>` management in `.astro` layouts
- Automatic sitemap with `@astrojs/sitemap`
- Built-in image optimization

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
- Copy `.claude/` (commands, skills, agents, hooks, settings.json)
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
- Copy `.claude/` (commands, skills, agents, hooks, settings.json)
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
- Copy `.claude/` (commands, skills, agents, hooks, settings.json)
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
- Copy `.claude/` (commands, skills, agents, hooks, settings.json)
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

## Dokploy on Hostinger VPS (if selected)

When Dokploy is selected as the hosting target, scaffold a complete deployment pipeline:

### Deployment Architecture
```
Code → Docker Build → Local Test → Docker Hub → Dokploy (webhook) → Live
```

### Required Environment Variables (.env.example additions)

```bash
# Dokploy Deployment
DOKPLOY_URL=http://your-vps-ip:3000/api
DOKPLOY_API_KEY=your_dokploy_api_key
DOKPLOY_APP_ID=your_application_id
DOKPLOY_REFRESH_TOKEN=your_webhook_refresh_token

# Docker Hub
DOCKER_HUB_USER=your_docker_username
DOCKER_IMAGE_NAME=your_docker_username/your_app_name

# Region (if multi-region)
DEPLOY_REGION=us
```

### Deployment Script: scripts/deploy.sh

Create this deployment script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Load environment
source .env

IMAGE="$DOCKER_IMAGE_NAME:latest"
TAG="${1:-latest}"

echo "=== Building Docker image ==="
docker build -t "$IMAGE" .

echo "=== Testing locally ==="
docker run -d -p 3000:3000 --name deploy-test "$IMAGE"
sleep 5

if ! curl -sf http://localhost:3000 > /dev/null; then
  echo "ERROR: Local test FAILED. Aborting deployment."
  docker logs deploy-test
  docker stop deploy-test && docker rm deploy-test
  exit 1
fi

echo "Local test PASSED."
docker stop deploy-test && docker rm deploy-test

echo "=== Pushing to Docker Hub ==="
docker push "$IMAGE"

echo "=== Deploying via Dokploy ==="
RESPONSE=$(curl -s -X POST \
  -H "x-api-key: $DOKPLOY_API_KEY" \
  -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.deploy" \
  -d "{\"applicationId\":\"$DOKPLOY_APP_ID\"}")

echo "Dokploy response: $RESPONSE"
echo "=== Deployment complete ==="
```

### Dokploy API Reference (for CLAUDE.md)

Add these to the project's CLAUDE.md when Dokploy is selected:

```markdown
## Deployment Commands

### Deploy (build, test, push, deploy)
bash scripts/deploy.sh

### Dokploy API (direct)
# List all projects
curl -s -H "x-api-key: $DOKPLOY_API_KEY" "$DOKPLOY_URL/project.all"

# Deploy application
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY" -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.deploy" -d '{"applicationId":"APP_ID"}'

# Redeploy (rebuild)
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY" -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.redeploy" -d '{"applicationId":"APP_ID"}'

# Start / Stop
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY" -H "Content-Type: application/json" \
  "$DOKPLOY_URL/application.start" -d '{"applicationId":"APP_ID"}'

# Webhook deploy (no auth needed — use refresh token)
curl -X POST http://your-vps-ip:3000/api/deploy/REFRESH_TOKEN
```

### Multi-Region Support (if selected)

When `multiregion` is selected, scaffold for US + EU:

```bash
# .env.example additions for multi-region
DOKPLOY_URL_US=http://us-vps-ip:3000/api
DOKPLOY_API_KEY_US=your_us_api_key
DOKPLOY_APP_ID_US=your_us_app_id

DOKPLOY_URL_EU=http://eu-vps-ip:3000/api
DOKPLOY_API_KEY_EU=your_eu_api_key
DOKPLOY_APP_ID_EU=your_eu_app_id
```

**CRITICAL multi-region rules (add to CLAUDE.md):**
- US containers NEVER connect to EU databases, and vice versa
- Each container gets region-specific `MONGODB_URI` or `DATABASE_URL`
- `DEPLOY_REGION` env var must match the VPS region
- When pushing images: push `:latest` for US, push `:eu` tag for EU
- ALWAYS deploy to both regions — never leave them out of sync

### scripts/deploy-all.sh (multi-region)

```bash
#!/usr/bin/env bash
set -euo pipefail
source .env

IMAGE="$DOCKER_IMAGE_NAME"

# Build and test locally first
docker build -t "$IMAGE:latest" .
docker run -d -p 3000:3000 --name deploy-test "$IMAGE:latest"
sleep 5
curl -sf http://localhost:3000 > /dev/null || { echo "FAILED"; docker logs deploy-test; docker stop deploy-test; docker rm deploy-test; exit 1; }
docker stop deploy-test && docker rm deploy-test

# Push both tags
docker push "$IMAGE:latest"
docker tag "$IMAGE:latest" "$IMAGE:eu"
docker push "$IMAGE:eu"

# Deploy to both regions
echo "Deploying to US..."
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY_US" -H "Content-Type: application/json" \
  "$DOKPLOY_URL_US/application.deploy" -d "{\"applicationId\":\"$DOKPLOY_APP_ID_US\"}"

echo "Deploying to EU..."
curl -s -X POST -H "x-api-key: $DOKPLOY_API_KEY_EU" -H "Content-Type: application/json" \
  "$DOKPLOY_URL_EU/application.deploy" -d "{\"applicationId\":\"$DOKPLOY_APP_ID_EU\"}"

echo "=== Both regions deployed ==="
```

## Analytics: Rybbit (if selected)

When `rybbit` is selected as the analytics provider, scaffold tracking into the project:

### Required Environment Variables

```bash
# .env.example additions
NEXT_PUBLIC_RYBBIT_SITE_ID=your_rybbit_site_id
NEXT_PUBLIC_RYBBIT_URL=https://app.rybbit.io
```

### Next.js Integration (layout.tsx)

```tsx
<head>
  {process.env.NEXT_PUBLIC_RYBBIT_SITE_ID && (
    <script
      src={`${process.env.NEXT_PUBLIC_RYBBIT_URL || 'https://app.rybbit.io'}/api/script.js`}
      data-site-id={process.env.NEXT_PUBLIC_RYBBIT_SITE_ID}
      defer
    />
  )}
</head>
```

### Vite / Astro / Static HTML Integration

```html
<script
  src="https://app.rybbit.io/api/script.js"
  data-site-id="YOUR_SITE_ID"
  defer
></script>
```

### Docker Build Args (for Next.js on Dokploy)

When using both Rybbit + Dokploy + Next.js, the Rybbit env vars must be passed as build args:

```dockerfile
ARG NEXT_PUBLIC_RYBBIT_SITE_ID
ARG NEXT_PUBLIC_RYBBIT_URL
ENV NEXT_PUBLIC_RYBBIT_SITE_ID=$NEXT_PUBLIC_RYBBIT_SITE_ID
ENV NEXT_PUBLIC_RYBBIT_URL=$NEXT_PUBLIC_RYBBIT_URL
```

### Important
- Each website MUST have its own unique Rybbit site ID
- Create a new site in the Rybbit dashboard at https://app.rybbit.io
- NEVER reuse site IDs across different projects
- After deployment, verify the script is present in the page source

## AI-Pooler Setup (if @rulecatch/ai-pooler in npm list)

When the default profile or user selects ai-pooler:

```bash
# Install and initialize
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

## Profile System: claude-mastery-project.conf

If the user passes `default` (or any profile name), read `claude-mastery-project.conf` from the project root. This file defines reusable presets so users don't re-type preferences.

### claude-mastery-project.conf Format

```ini
# Claude Mastery Project Configuration
# Define profiles with preset options for /new-project

[default]
type = fullstack
framework = next
hosting = dokploy
package_manager = pnpm
database = mongo
options = seo, tailwind, docker, ci
mcp = playwright, context7, rulecatch

[api]
type = api
framework = fastify
hosting = dokploy
package_manager = pnpm
database = mongo
options = docker, ci
mcp = context7, rulecatch

[static-site]
type = webapp
framework = astro
hosting = static
package_manager = pnpm
options = seo, tailwind
mcp = context7

[quick]
type = webapp
framework = vite
hosting = vercel
package_manager = pnpm
options = tailwind
mcp = context7
```

### How Profiles Work

1. Read `claude-mastery-project.conf` from project root (or `~/.claude/claude-mastery-project.conf` for global defaults)
2. Parse the named profile section
3. Apply all settings from the profile
4. Any additional arguments OVERRIDE profile settings
5. Missing settings from profile = ask the user

Examples:
- `/new-project my-app default` — uses [default] profile for everything
- `/new-project my-app api` — uses [api] profile
- `/new-project my-app default vercel` — uses [default] but overrides hosting to Vercel
- `/new-project my-app` — no profile, asks all questions

### Create Default Config

When scaffolding the starter kit itself, create `claude-mastery-project.conf` with the profiles above as starting templates. Users customize to their preferences.

## Verification Checklist

After creation, verify and report:

**Core files:**
- [ ] .env exists (empty)
- [ ] .env.example exists (with placeholders)
- [ ] .gitignore includes all required entries
- [ ] .dockerignore exists
- [ ] CLAUDE.md has all required sections (overview, stack, commands, ports)
- [ ] package.json has ALL required scripts (dev, build, test, test:e2e, test:kill-ports)
- [ ] Error handlers in entry point (gracefulShutdown for MongoDB projects)
- [ ] TypeScript strict mode enabled

**Testing:**
- [ ] vitest.config.ts created and configured
- [ ] playwright.config.ts created with test ports (4000/4010/4020) and webServer
- [ ] test:kill-ports script kills test ports BEFORE E2E runs
- [ ] tests/e2e/ directory exists
- [ ] tests/unit/ directory exists
- [ ] Example E2E test has minimum 3 assertions (URL, element, data)
- [ ] `pnpm test` runs unit + E2E in sequence

**Web projects:**
- [ ] SEO meta tags in layout/head
- [ ] JSON-LD structured data included
- [ ] robots.txt created

**Infrastructure:**
- [ ] Dockerfile with multi-stage build (Docker projects)
- [ ] scripts/deploy.sh created (Dokploy projects)
- [ ] Multi-region deploy script (if multiregion selected)

**Database (MongoDB projects):**
- [ ] src/core/db/index.ts — MongoDB wrapper
- [ ] scripts/db-query.ts — Test Query Master
- [ ] scripts/queries/ directory
- [ ] db-query rules in CLAUDE.md

**Content (if web project with articles/posts):**
- [ ] scripts/build-content.ts
- [ ] scripts/content.config.json
- [ ] content/ directory

**Extras:**
- [ ] MCP servers installed (if selected)
- [ ] claude-mastery-project.conf created (if using profiles)
- [ ] No file > 300 lines
- [ ] All independent awaits use Promise.all

Report any missing items.
