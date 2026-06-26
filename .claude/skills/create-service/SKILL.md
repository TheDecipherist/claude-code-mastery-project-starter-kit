---
name: create-service
description: Scaffold a new microservice that follows the project's server/handlers/adapters architecture. Use when asked to create, scaffold, or add a new service or package. Writes files and may create a git branch, so it runs only when invoked explicitly.
when_to_use: |
  - User asks to create, scaffold, or add a new service or microservice
  - User says "new service", "scaffold service", "create service", "add service"
  - Do NOT auto-run; this writes files and touches git
disable-model-invocation: true
allowed-tools: "Read, Write, Edit, Bash"
---

# Create Service

Scaffold a new service that follows the project architecture. This writes files and may create a branch, so it only runs when you type `/create-service`.

## Architecture

Three layers, one direction. `server.ts` is thin, `handlers/` hold logic, `adapters/` wrap everything external.

```
server.ts      routes only, NEVER business logic
   │
   ▼
handlers/      business logic, one file per domain
   │
   ▼
adapters/      external wrappers (database via StrictDB, APIs, queues)
```

This matches the `api-conventions` skill. Keep them in sync: if the layering changes, change both.

## Directory structure

```
packages/{name}/
├── src/
│   ├── server.ts          # entry point — routes only
│   ├── handlers/          # business logic
│   │   └── index.ts
│   ├── adapters/          # external wrappers
│   │   ├── index.ts
│   │   └── db.ts          # StrictDB data adapter (the only place the driver lives)
│   └── types.ts           # TypeScript types
├── tests/
│   └── handlers.test.ts
├── package.json
├── tsconfig.json
└── CLAUDE.md              # service-specific instructions
```

## package.json — resolve versions at scaffold time

**Do not hardcode dependency versions.** Before writing `package.json`, resolve the current stable version of each dependency (`npm view <pkg> version`, or context7) and pin those. Hardcoded versions rot the day they ship, and a stale pin is how you get an Express 4 runtime against Express 5 types.

Dependencies to resolve and include:

- runtime: `express` (current major is 5)
- dev: `tsx`, `typescript`, `vitest`, `@types/express`

Make the `@types/express` major match the `express` major. Verify, don't assume.

```json
{
  "name": "@project/{name}",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/server.ts",
    "start": "node dist/server.js",
    "test": "vitest run"
  },
  "dependencies": {
    "express": "<resolved>"
  },
  "devDependencies": {
    "tsx": "<resolved>",
    "typescript": "<resolved>",
    "vitest": "<resolved>",
    "@types/express": "<resolved, major matching express>"
  }
}
```

## Template: src/server.ts

```typescript
import express from 'express';
import { handlers } from './handlers/index.js';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: '{name}' });
});

// Routes delegate to handlers. NEVER put logic here.
// Replace this catch-all with real REST routes per domain.
app.post('/api/v1/:action', handlers.handleAction);

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

app.listen(PORT, () => {
  console.log(`{name} running on port ${PORT}`);
});
```

## Template: src/adapters/db.ts

The data adapter is the only place the driver is touched. Use StrictDB if it's installed, otherwise the native MongoDB driver. Never Mongoose. Handlers import this, never the driver.

```typescript
// Wire to your StrictDB package/API. This is the data boundary for the service.
// Rules enforced here (see the mongodb-rules skill):
//   - StrictDB if installed, else the native driver; never Mongoose
//   - reads are aggregation pipelines, not find()
//   - multi-document writes use bulkWrite
//   - never put _id in a write body; rehydrate types before upserts
import { StrictDB } from 'strictdb'; // if StrictDB isn't installed, import { MongoClient } from 'mongodb' and use that instead

const db = new StrictDB({ uri: process.env.MONGODB_URI! });

export const dbAdapter = {
  // Example read — express as an aggregation pipeline in real methods.
  async getById(collection: string, id: unknown) {
    // ensure `id` is an ObjectId, not a string, before querying
    return db.collection(collection).aggregate([{ $match: { _id: id } }]).next();
  },

  // Example write — use bulkWrite for multi-document operations.
  async upsertMany(collection: string, ops: unknown[]) {
    return db.collection(collection).bulkWrite(ops);
  },
};
```

## Template: src/types.ts

```typescript
export interface ServiceConfig {
  port: number;
  name: string;
  environment: 'development' | 'staging' | 'production';
}

// Add your domain types here.
```

## Template: tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

## Auto-branch (if on main)

Before scaffolding, check the branch:

```bash
git branch --show-current
```

Default (`auto_branch = true` in `claude-mastery-project.conf`):

- On `main`/`master`: create and switch to a feature branch, then report it.
  ```bash
  git checkout -b feat/<service-name>
  ```
  "Created branch `feat/<service-name>`, main stays untouched."
- On a feature branch already: proceed.
- Not a git repo: skip.
- **If `claude-mastery-project.conf` is missing:** treat `auto_branch` as unset and ask before creating a branch on main, rather than assuming.

To disable: set `auto_branch = false`. When disabled, warn and ask before proceeding on main.

## After creating — checklist

- [ ] Directory matches the template, including `adapters/db.ts`
- [ ] `package.json` versions were resolved at scaffold time, not copied
- [ ] `@types/express` major matches `express` major
- [ ] TypeScript strict mode on
- [ ] Entry point has both `unhandledRejection` and `uncaughtException` handlers
- [ ] All routes under `/api/v1/`
- [ ] Business logic in `handlers/`, not `server.ts`
- [ ] Database access through the adapter in `adapters/` (StrictDB if installed, else native driver), no Mongoose, no raw driver in handlers
- [ ] No file exceeds 300 lines
- [ ] Port assigned in the root CLAUDE.md port table
- [ ] Service added to `project-docs/ARCHITECTURE.md`
- [ ] Basic test file created
- [ ] `.dockerignore` created (if using Docker)

## RuleCatch

After scaffolding, check RuleCatch:

- If the RuleCatch MCP server is available, query it for violations in the new service files and report them.
- If not connected, suggest checking the RuleCatch dashboard.
