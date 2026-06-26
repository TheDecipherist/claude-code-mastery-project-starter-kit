<!-- Part of /new-project scaffolding. Read via .claude/commands/new-project.md when the selection requires it; not a standalone command. -->

> This profile builds its CLAUDE.md from `../shared/claude-md-base.md` (the universal rules) plus the profile-specific rules below. Read the base first.

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

#### Question P3.1: MongoDB Connection String (only if MongoDB selected in P3)
"Do you want to configure your MongoDB connection now?"
- **Yes, I have a connection string** — User pastes their full `mongodb+srv://...` or `mongodb://...` URI. Write it to `.env` as `STRICTDB_URI=<their-value>`.
- **No, I'll set it up later** — Skip. Leave `STRICTDB_URI` placeholder in `.env.example` only.

If the user provides a connection string:
1. Write `STRICTDB_URI=<value>` to the project's `.env`
2. If no database name in URI, ask: "What should the database be called?" and append it to the URI

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
│       │   └── db.py            # Database connection layer
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
13. Copy `.claude/` contents from starter kit — only commands with `scope: project` in frontmatter (skills, hooks, settings.json copied in full)
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
- [ ] `.claude/` has `scope: project` commands only, skills, hooks, settings.json

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

