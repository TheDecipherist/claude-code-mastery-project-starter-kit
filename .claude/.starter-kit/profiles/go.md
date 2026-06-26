<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

> This profile builds its CLAUDE.md from `../shared/claude-md-base.md` (the universal rules) plus the profile-specific rules below. Read the base first.

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

#### Question G3.1: MongoDB Connection String (only if MongoDB selected in G3)
"Do you want to configure your MongoDB connection now?"
- **Yes, I have a connection string** — User pastes their full `mongodb+srv://...` URI. Write it to `.env` as `STRICTDB_URI=<their-value>`.
- **No, I'll set it up later** — Skip. Leave `STRICTDB_URI` placeholder in `.env.example` only.

If the user provides a connection string:
1. Write `STRICTDB_URI=<value>` to the project's `.env`
2. If no database name in URI, ask: "What should the database be called?" and append it to the URI

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
11. **If NOT using npm global install** (`~/.claude/starter-kit-source-path` does not exist): Copy `.claude/` contents from starter kit - only commands with `scope: project` in frontmatter (skills, hooks, settings.json copied in full). **If npm global install is active**: skip this step - commands/skills/hooks already live in `~/.claude/` globally.
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
- [ ] `.claude/` has `scope: project` commands only, skills, hooks, settings.json

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

