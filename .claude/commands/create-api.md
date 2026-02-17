---
description: Scaffold a new API endpoint — route, handler, types, tests — wired into the server
scope: project
argument-hint: <resource-name> [--no-mongo]
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion
---

# Create API Endpoint

Scaffold a production-ready API endpoint for: **$ARGUMENTS**

## Step 0 — Auto-Branch (if on main)

Before creating any files, check the current branch:

```bash
git branch --show-current
```

**Default behavior** (`auto_branch = true` in `claude-mastery-project.conf`):
- If on `main` or `master`: automatically create a feature branch and switch to it:
  ```bash
  git checkout -b feat/api-<resource-name>
  ```
  Report: "Created branch `feat/api-<resource>` — main stays untouched."
- If already on a feature branch: proceed
- If not a git repo: skip this check

**To disable:** Set `auto_branch = false` in `claude-mastery-project.conf`. When disabled, warn and ask the user before proceeding on main.

## Step 1 — Gather Context

Before scaffolding, read the current project:

1. **Read `src/server.ts`** (or `src/server.js`, `src/index.ts`) — understand the server setup
2. **Read `src/core/db/index.ts`** — confirm the db wrapper is available
3. **Scan `src/routes/`** — check for existing route patterns to follow
4. **Scan `src/handlers/`** — check for existing handler patterns
5. **Scan `src/types/`** — check for existing type patterns
6. **Read `.env.example`** — check for database config

If `--no-mongo` is in the arguments, skip MongoDB integration. Otherwise, use the db wrapper by default.

## Step 2 — Create Files

Generate these files for the resource:

### File 1: `src/types/<resource>.ts` — Types first (they're the spec)

```typescript
import type { Document, ObjectId } from 'mongodb';

/** Database document shape */
export interface <Resource>Doc extends Document {
  _id: ObjectId;
  // Add fields based on the resource
  createdAt: Date;
  updatedAt: Date;
}

/** API request body for creating a resource */
export interface Create<Resource>Body {
  // Fields the client sends (NO _id, NO timestamps)
}

/** API request body for updating a resource */
export interface Update<Resource>Body {
  // Partial fields the client can update
}

/** API response shape (what the client receives) */
export interface <Resource>Response {
  id: string;
  // Mapped from the doc — NEVER expose _id directly
  createdAt: string;
  updatedAt: string;
}
```

### File 2: `src/handlers/<resource>.ts` — Business logic

```typescript
import {
  queryOne,
  queryMany,
  insertOne,
  updateOne,
  deleteOne,
  count,
  registerIndex,
} from '../core/db/index.js';
import type { <Resource>Doc, Create<Resource>Body, Update<Resource>Body, <Resource>Response } from '../types/<resource>.js';
import { ObjectId } from 'mongodb';

// ---------------------------------------------------------------------------
// Indexes — registered at import time, created at startup via ensureIndexes()
// ---------------------------------------------------------------------------

registerIndex({ collection: '<resources>', fields: { createdAt: -1 } });
// Add more indexes based on query patterns

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const COLLECTION = '<resources>';

/** Map a database document to API response (never expose internals) */
function toResponse(doc: <Resource>Doc): <Resource>Response {
  return {
    id: doc._id.toHexString(),
    // Map other fields
    createdAt: doc.createdAt.toISOString(),
    updatedAt: doc.updatedAt.toISOString(),
  };
}

// ---------------------------------------------------------------------------
// CRUD operations
// ---------------------------------------------------------------------------

export async function create<Resource>(body: Create<Resource>Body): Promise<<Resource>Response> {
  const now = new Date();
  const doc: Omit<<Resource>Doc, '_id'> = {
    ...body,
    createdAt: now,
    updatedAt: now,
  };
  await insertOne(COLLECTION, doc);
  // Re-query to get the _id (insertOne uses bulkWrite, no insertedId)
  const created = await queryOne<<Resource>Doc>(COLLECTION, { createdAt: now });
  if (!created) throw new Error('Failed to create resource');
  return toResponse(created);
}

export async function get<Resource>ById(id: string): Promise<<Resource>Response | null> {
  if (!ObjectId.isValid(id)) return null;
  const doc = await queryOne<<Resource>Doc>(COLLECTION, { _id: new ObjectId(id) });
  return doc ? toResponse(doc) : null;
}

export async function list<Resource>s(options: {
  page?: number;
  limit?: number;
  sort?: Record<string, 1 | -1>;
} = {}): Promise<{ data: <Resource>Response[]; total: number; page: number; limit: number }> {
  const page = Math.max(1, options.page ?? 1);
  const limit = Math.min(100, Math.max(1, options.limit ?? 20));
  const sort = options.sort ?? { createdAt: -1 };

  const [docs, total] = await Promise.all([
    queryMany<<Resource>Doc>(COLLECTION, [
      { $sort: sort },
      { $skip: (page - 1) * limit },
      { $limit: limit },
    ]),
    count(COLLECTION),
  ]);

  return { data: docs.map(toResponse), total, page, limit };
}

export async function update<Resource>(
  id: string,
  body: Update<Resource>Body
): Promise<<Resource>Response | null> {
  if (!ObjectId.isValid(id)) return null;
  const filter = { _id: new ObjectId(id) };
  await updateOne<<Resource>Doc>(COLLECTION, filter, {
    $set: { ...body, updatedAt: new Date() },
  });
  const updated = await queryOne<<Resource>Doc>(COLLECTION, filter);
  return updated ? toResponse(updated) : null;
}

export async function delete<Resource>(id: string): Promise<boolean> {
  if (!ObjectId.isValid(id)) return false;
  await deleteOne<<Resource>Doc>(COLLECTION, { _id: new ObjectId(id) });
  return true;
}
```

### File 3: `src/routes/v1/<resource>.ts` — Routes (thin, no logic)

```typescript
import { Router } from 'express';
import type { Request, Response } from 'express';
import {
  create<Resource>,
  get<Resource>ById,
  list<Resource>s,
  update<Resource>,
  delete<Resource>,
} from '../../handlers/<resource>.js';

const router = Router();

// POST /api/v1/<resources>
router.post('/', async (req: Request, res: Response) => {
  try {
    const result = await create<Resource>(req.body);
    res.status(201).json(result);
  } catch (err) {
    console.error('Create <resource> failed:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/v1/<resources>
router.get('/', async (req: Request, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const result = await list<Resource>s({ page, limit });
    res.json(result);
  } catch (err) {
    console.error('List <resources> failed:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/v1/<resources>/:id
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const result = await get<Resource>ById(req.params.id);
    if (!result) {
      res.status(404).json({ error: '<Resource> not found' });
      return;
    }
    res.json(result);
  } catch (err) {
    console.error('Get <resource> failed:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PATCH /api/v1/<resources>/:id
router.patch('/:id', async (req: Request, res: Response) => {
  try {
    const result = await update<Resource>(req.params.id, req.body);
    if (!result) {
      res.status(404).json({ error: '<Resource> not found' });
      return;
    }
    res.json(result);
  } catch (err) {
    console.error('Update <resource> failed:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/v1/<resources>/:id
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const found = await delete<Resource>(req.params.id);
    if (!found) {
      res.status(404).json({ error: '<Resource> not found' });
      return;
    }
    res.status(204).send();
  } catch (err) {
    console.error('Delete <resource> failed:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
```

### File 4: Wire into server — Add to `src/server.ts`

Add the import and route registration to the existing server:

```typescript
// Add this import
import <resource>Routes from './routes/v1/<resource>.js';

// Add this route registration (with /api/v1/ prefix)
app.use('/api/v1/<resources>', <resource>Routes);
```

### File 5: `tests/unit/<resource>.test.ts` — Unit tests

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
// Test the handler functions directly, mock the db layer

describe('<Resource> Handlers', () => {
  describe('create<Resource>', () => {
    it('should create a new <resource> and return response', async () => {
      // Arrange — mock db calls
      // Act — call create<Resource>
      // Assert — verify response shape, timestamps set
    });
  });

  describe('get<Resource>ById', () => {
    it('should return <resource> when found', async () => {
      // Test happy path
    });

    it('should return null for invalid ObjectId', async () => {
      // Test invalid id returns null
    });

    it('should return null when not found', async () => {
      // Test missing doc returns null
    });
  });

  describe('list<Resource>s', () => {
    it('should return paginated results', async () => {
      // Test pagination defaults
    });

    it('should cap limit at 100', async () => {
      // Test max limit enforcement
    });
  });

  describe('update<Resource>', () => {
    it('should update and return updated doc', async () => {
      // Test updatedAt is refreshed
    });
  });

  describe('delete<Resource>', () => {
    it('should return true when deleted', async () => {
      // Test happy path
    });

    it('should return false for invalid ObjectId', async () => {
      // Test invalid id
    });
  });
});
```

## Step 3 — Best Practices Enforced

Every generated endpoint MUST follow these rules:

### Security
- All user input passes through the db wrapper's automatic NoSQL sanitization
- NEVER trust `req.body` types at runtime — validate or use Zod schemas
- NEVER expose `_id` directly — always map to `id: string`
- NEVER expose internal error details to the client
- ALWAYS return generic "Internal server error" for unexpected errors

### Performance
- Pagination on ALL list endpoints (default 20, max 100)
- Indexes registered for all query patterns (`registerIndex()`)
- Uses shared connection pool via db wrapper (NEVER creates new connections)
- `$limit` enforced before `$lookup` in any join queries

### Architecture
- Routes are THIN — no business logic, just parse and delegate
- Handlers contain ALL business logic
- Types defined FIRST — they're the contract
- One handler file per resource domain
- One route file per resource

### Node.js Best Practices
- Async error handling with try/catch on every route
- Proper HTTP status codes (201 created, 204 no content, 404 not found)
- JSON responses on all endpoints (including errors)
- No callback-style code — async/await only
- Uses the project's shared MongoDB pool (never creates its own)

## Step 4 — Verification Checklist

After generating, verify:

- [ ] Types file created at `src/types/<resource>.ts`
- [ ] Handler file created at `src/handlers/<resource>.ts`
- [ ] Route file created at `src/routes/v1/<resource>.ts`
- [ ] Routes wired into `src/server.ts` with `/api/v1/` prefix
- [ ] Test file created at `tests/unit/<resource>.test.ts`
- [ ] All CRUD operations: create, read (single + list), update, delete
- [ ] Pagination on list endpoint (default 20, max 100)
- [ ] Indexes registered with `registerIndex()`
- [ ] No `any` types
- [ ] No file exceeds 300 lines
- [ ] _id never exposed — mapped to id string
- [ ] All errors caught and logged
- [ ] Uses db wrapper imports (NEVER raw MongoClient)

## RuleCatch Report

After all files are created and verified, check RuleCatch:

- If the RuleCatch MCP server is available: query for violations in the new API files
- Report any violations found (type issues, missing assertions, security, etc.)
- If no MCP: remind the user — "Check your RuleCatch dashboard for any violations in the new endpoint files"
