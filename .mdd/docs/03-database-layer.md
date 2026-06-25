---
id: 03-database-layer
title: Database Layer (StrictDB)
edition: Both
depends_on: []
source_files:
  - scripts/db-query.ts
  - scripts/queries/
models: []
test_files: []
last_synced: 2026-03-01
status: complete
phase: all
tags: [database, strictdb, mongodb, postgresql, orm, queries, connection-pooling, data-access]
path: Core Infrastructure / Database Layer
known_issues:
  - StrictDB's registerCollection queues registrations but no validation of schema shapes before connect
---

# 03 — Database Layer (StrictDB)

## Purpose

All database access uses StrictDB directly — a standalone npm package that started as this starter kit's custom database adapter. Install `strictdb` + your database driver, create a single instance at app startup, and share it.

## Architecture

```
StrictDB.create({ uri })  ←  Create once at app startup
       ↓
   StrictDB instance       ←  Shared across app
       ↓
   Auto-detected backend from URI scheme:
   mongodb:// | postgresql:// | mysql:// | mssql:// | file: | http://
```

## StrictDB Instance Methods

### Connection
| Method | Description |
|--------|-------------|
| `StrictDB.create({ uri, pool?, dbName? })` | Create and connect. Returns instance. |
| `db.close()` | Close all connections |
| `db.gracefulShutdown(exitCode)` | Close connections + exit. Idempotent. |

### Read Operations
| Method | Description |
|--------|-------------|
| `db.queryOne<T>(collection, filter)` | Single document lookup |
| `db.queryMany<T>(collection, filter, options?)` | Multiple documents with sort/limit/skip |
| `db.queryWithLookup<T>(collection, options)` | Join/lookup across collections |
| `db.count(collection, filter?)` | Count matching documents |

### Write Operations
| Method | Description |
|--------|-------------|
| `db.insertOne(collection, doc)` | Insert single document |
| `db.insertMany(collection, docs)` | Insert multiple documents |
| `db.updateOne(collection, filter, update, upsert?)` | Update single document |
| `db.updateMany(collection, filter, update)` | Update multiple documents |
| `db.deleteOne(collection, filter)` | Delete single document |
| `db.deleteMany(collection, filter)` | Delete multiple documents |
| `db.batch(operations)` | Batch multiple operations |

### AI-First Discovery
| Method | Description |
|--------|-------------|
| `db.describe(collection)` | Discover collection schema |
| `db.validate(collection, check)` | Dry-run validation before execution |
| `db.explain(collection, query)` | See native query under the hood |

### Schema & Indexes
| Method | Description |
|--------|-------------|
| `db.registerCollection(def)` | Register Zod schema for a collection |
| `db.registerIndex(def)` | Register index definition |
| `db.ensureIndexes(options?)` | Create all registered indexes |

## StrictDB-MCP — AI Integration

AI agents should use the `strictdb-mcp` MCP server for database operations. It exposes 14 tools with all guardrails enforced automatically:

```bash
claude mcp add strictdb -- npx -y strictdb-mcp@latest
```

## Test Query System

**ABSOLUTE RULE:** All ad-hoc/test/dev queries go through `scripts/db-query.ts`.

1. Create query file in `scripts/queries/<name>.ts`
2. Register in `scripts/db-query.ts` registry
3. Run: `pnpm db:query <name>`
4. List: `pnpm db:query:list`

NEVER create standalone scripts or inline queries in `src/`.

## Graceful Shutdown Pattern

Every Node.js entry point MUST wire up shutdown handlers:
```typescript
process.on('SIGTERM', () => db.gracefulShutdown(0));
process.on('SIGINT', () => db.gracefulShutdown(0));
process.on('uncaughtException', (err) => { console.error(err); db.gracefulShutdown(1); });
process.on('unhandledRejection', (reason) => { console.error(reason); db.gracefulShutdown(1); });
```

## Known Issues

- `registerCollection` accepts any shape before indexes are ensured (queued without validation)
