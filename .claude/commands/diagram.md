---
description: Generate or update project diagrams by scanning actual code — architecture, API, database, infrastructure
argument-hint: <type> [--update]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Generate Diagram

Scan the actual project and generate/update diagrams based on what exists in code.

**Type:** $ARGUMENTS

Available types:
- `architecture` — System overview: services, connections, data flow → updates `project-docs/ARCHITECTURE.md`
- `api` — API routes map: all endpoints grouped by resource → updates `project-docs/ARCHITECTURE.md`
- `database` — Database schema: collections, indexes, relationships → updates `project-docs/ARCHITECTURE.md`
- `infrastructure` — Deployment topology: servers, containers, regions → updates `project-docs/INFRASTRUCTURE.md`
- `all` — Generate all diagram types

If `--update` is passed, replace existing diagrams in-place. Otherwise, show the diagram and ask before writing.

## Diagram Format

**ALL diagrams use ASCII box-drawing characters.** No Mermaid, no SVG, no external tools. ASCII works in every terminal, every markdown renderer, every code review.

```
Box characters: ┌ ┐ └ ┘ │ ─ ├ ┤ ┬ ┴ ┼
Arrows: → ← ↑ ↓ ──> <── ───>
```

---

## Type: `architecture`

Scan the project and generate a system overview diagram.

### What to scan:

1. **`src/` directory structure** — identify services, handlers, adapters
   ```bash
   find src/ -name "*.ts" -o -name "*.tsx" 2>/dev/null | head -50
   ```

2. **Entry points** — find all server/app files
   ```bash
   grep -rl "app.listen\|createServer\|express()\|fastify()\|Hono()" src/ 2>/dev/null
   ```

3. **Route definitions** — find where endpoints are defined
   ```bash
   grep -rn "app\.\(get\|post\|put\|delete\|patch\)\|router\.\(get\|post\|put\|delete\|patch\)" src/ 2>/dev/null
   ```

4. **Database usage** — find which services access the database
   ```bash
   grep -rl "queryOne\|queryMany\|insertOne\|updateOne\|bulkOps\|MongoClient\|PrismaClient" src/ 2>/dev/null
   ```

5. **External service calls** — find adapters and API calls
   ```bash
   grep -rl "fetch(\|axios\|got(" src/ 2>/dev/null
   ```

6. **Package.json** — check for framework indicators
   - `next` → Next.js app
   - `express` → Express API
   - `fastify` → Fastify API
   - `hono` → Hono API

### Generate the diagram:

```
┌─────────────────────────────────────────────────────────────┐
│                        YOUR SYSTEM                           │
│                                                              │
│   ┌───────────┐    HTTP     ┌───────────┐                  │
│   │  Client   │────────────>│ Website   │                  │
│   │  Browser  │             │  :3000    │                  │
│   └───────────┘             └───────────┘                  │
│         │                                                    │
│         │  API calls        ┌───────────┐                  │
│         └──────────────────>│   API     │                  │
│                             │  :3001    │                  │
│                             └─────┬─────┘                  │
│                                   │                         │
│                          read/write│                         │
│                                   ▼                         │
│                            ┌───────────┐                   │
│                            │ MongoDB   │                   │
│                            │ (wrapper) │                   │
│                            └───────────┘                   │
│                                                              │
│   ┌───────────┐   reads    ┌───────────┐                  │
│   │ Dashboard │────────────>│   API     │                  │
│   │  :3002    │             │  :3001    │                  │
│   └───────────┘             └───────────┘                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Adapt this to what ACTUALLY exists.** Don't include services that don't exist. Don't guess — only diagram what you found in code.

### Where to write:

Replace the `## System Overview` diagram section in `project-docs/ARCHITECTURE.md`.
Also update `## Service Responsibilities` table and `## Data Flow` section based on findings.

---

## Type: `api`

Scan all route definitions and generate an API routes map.

### What to scan:

```bash
# Express/Fastify routes
grep -rn "app\.\(get\|post\|put\|delete\|patch\)\|router\.\(get\|post\|put\|delete\|patch\)" src/ 2>/dev/null

# Next.js API routes (file-based)
find src/app/api -name "route.ts" -o -name "route.tsx" 2>/dev/null
find src/pages/api -name "*.ts" -o -name "*.tsx" 2>/dev/null
```

### Generate the diagram:

```
API Routes Map
==============

  /api/v1/
  ├── auth/
  │   ├── POST   /login          → handlers/auth.ts:handleLogin
  │   ├── POST   /signup         → handlers/auth.ts:handleSignup
  │   └── POST   /logout         → handlers/auth.ts:handleLogout
  ├── users/
  │   ├── GET    /               → handlers/users.ts:listUsers
  │   ├── GET    /:id            → handlers/users.ts:getUser
  │   ├── PUT    /:id            → handlers/users.ts:updateUser
  │   └── DELETE /:id            → handlers/users.ts:deleteUser
  └── health/
      └── GET    /               → server.ts (inline)
```

### Where to write:

Add/update an `## API Routes` section in `project-docs/ARCHITECTURE.md`.

---

## Type: `database`

Scan database queries, models, and index registrations to map the schema.

### What to scan:

```bash
# Collections used in queries
grep -rn "queryOne\|queryMany\|insertOne\|updateOne\|bulkOps\|deleteOne\|count(" src/ 2>/dev/null

# Index registrations
grep -rn "registerIndex\|createIndex\|ensureIndex" src/ scripts/ 2>/dev/null

# Type definitions that map to collections
grep -rn "interface.*{" src/types/ 2>/dev/null
```

### Generate the diagram:

```
Database Schema
===============

  ┌─────────────────────────┐      ┌─────────────────────────┐
  │ users                   │      │ sessions                │
  ├─────────────────────────┤      ├─────────────────────────┤
  │ _id         ObjectId    │──┐   │ _id         ObjectId    │
  │ email       string  [U] │  │   │ userId      ObjectId    │──┐
  │ name        string      │  │   │ token       string  [U] │  │
  │ apiKey      string [U,S]│  │   │ expiresAt   Date   [TTL]│  │
  │ createdAt   Date        │  │   │ createdAt   Date        │  │
  └─────────────────────────┘  │   └─────────────────────────┘  │
                               │                                 │
                               └─── userId references users._id ─┘

  Indexes:
    users.email       — unique
    users.apiKey      — unique, sparse
    sessions.userId   — compound (userId, startedAt DESC)
    sessions.expiresAt — TTL (auto-delete)

  [U] = unique  [S] = sparse  [TTL] = auto-expiring
```

### Where to write:

Add/update a `## Database Schema` section in `project-docs/ARCHITECTURE.md`.

---

## Type: `infrastructure`

Scan deployment config to generate infrastructure topology.

### What to scan:

1. **`.env` / `.env.example`** — region variables, ports, hosts
2. **`Dockerfile`** — what's containerized
3. **`docker-compose.yml`** — service orchestration
4. **`claude-mastery-project.conf`** — multi-region config
5. **`package.json`** — deployment scripts

```bash
# Check for multi-region
grep -n "_US\|_EU\|REGION" .env.example .env 2>/dev/null

# Check for Docker
ls Dockerfile docker-compose.yml 2>/dev/null

# Check for deployment config
grep -n "DOKPLOY\|HOSTINGER\|VERCEL\|VPS" .env.example .env 2>/dev/null
```

### Generate the diagram:

**Single region:**
```
Infrastructure
==============

  ┌──────────────── Production ────────────────┐
  │                                             │
  │   ┌─────────────┐     ┌─────────────┐     │
  │   │   Docker     │     │  MongoDB    │     │
  │   │   :3001      │────>│  Atlas      │     │
  │   │   (API)      │     │             │     │
  │   └─────────────┘     └─────────────┘     │
  │         │                                   │
  │   Dokploy on Hostinger VPS                  │
  │   IP: (from .env)                           │
  │                                             │
  └─────────────────────────────────────────────┘
```

**Multi-region:**
```
Infrastructure — Multi-Region
==============================

  ┌────────── US Region ──────────┐    ┌────────── EU Region ──────────┐
  │                                │    │                                │
  │  ┌──────────┐  ┌──────────┐  │    │  ┌──────────┐  ┌──────────┐  │
  │  │ Docker   │  │ MongoDB  │  │    │  │ Docker   │  │ MongoDB  │  │
  │  │ :latest  │─>│ Atlas US │  │    │  │ :eu      │─>│ Atlas EU │  │
  │  └──────────┘  └──────────┘  │    │  └──────────┘  └──────────┘  │
  │                                │    │                                │
  │  VPS: (US IP)                  │    │  VPS: (EU IP)                  │
  │  Dokploy US                    │    │  Dokploy EU                    │
  │                                │    │                                │
  └────────────────────────────────┘    └────────────────────────────────┘

  US containers → US database ONLY
  EU containers → EU database ONLY
  NEVER cross-connect regions
```

### Where to write:

Replace the `## Environment Overview` diagram in `project-docs/INFRASTRUCTURE.md`.

---

## Type: `all`

Run all four types in sequence: architecture → api → database → infrastructure.

---

## After Generating

1. Show the generated diagram(s) to the user
2. If `--update` was passed: write directly to the docs
3. If not: ask "Write this to project-docs/ARCHITECTURE.md?" before writing
4. Add a changelog entry with today's date:
   ```
   | (today) | Updated [type] diagram from code scan |
   ```
5. Report what was generated:
   ```
   Diagrams Generated
   ==================
   ✓ Architecture — 3 services found (Website, API, Dashboard)
   ✓ API Routes — 12 endpoints across 4 resources
   ✓ Database — 5 collections, 8 indexes
   ✓ Infrastructure — multi-region (US + EU)

   Written to:
     project-docs/ARCHITECTURE.md (architecture, api, database)
     project-docs/INFRASTRUCTURE.md (infrastructure)
   ```
