---
name: Create Service
description: Scaffold a new microservice that follows project architecture patterns
triggers:
  - create service
  - new service
  - scaffold service
  - add service
---

# Create Service Skill

Generate a new service that follows our architecture patterns.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       YOUR SERVICE                           │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────┐  │
│  │              SERVER (server.ts)                        │  │
│  │  - Express/Fastify entry point                        │  │
│  │  - Defines routes                                     │  │
│  │  - NEVER contains business logic                      │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                 │
│                            ▼                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                HANDLERS (handlers/)                    │  │
│  │  - Business logic lives here                          │  │
│  │  - One file per domain                                │  │
│  └───────────────────────────────────────────────────────┘  │
│                            │                                 │
│                            ▼                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                ADAPTERS (adapters/)                    │  │
│  │  - External service wrappers                          │  │
│  │  - Database, APIs, etc.                               │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
packages/{name}/
├── src/
│   ├── server.ts        # Entry point — routes only
│   ├── handlers/        # Business logic
│   │   └── index.ts
│   ├── adapters/        # External service wrappers
│   │   └── index.ts
│   └── types.ts         # TypeScript types
├── tests/
│   └── handlers.test.ts
├── package.json
├── tsconfig.json
└── CLAUDE.md            # Service-specific instructions
```

## Template: package.json

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
    "express": "^4.21.0"
  },
  "devDependencies": {
    "tsx": "^4.0.0",
    "typescript": "^5.7.0",
    "vitest": "^3.0.0",
    "@types/express": "^5.0.0"
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

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: '{name}' });
});

// Routes — delegate to handlers (NEVER put logic here)
app.post('/api/v1/:action', handlers.handleAction);

// Unhandled rejection handler
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});

// Uncaught exception handler
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

app.listen(PORT, () => {
  console.log(`{name} running on port ${PORT}`);
});
```

## Template: src/types.ts

```typescript
export interface ServiceConfig {
  port: number;
  name: string;
  environment: 'development' | 'staging' | 'production';
}

// Add your domain types here
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

## After Creating — Checklist

- [ ] Directory structure matches template
- [ ] package.json has correct scripts
- [ ] TypeScript strict mode enabled
- [ ] Entry point has unhandledRejection AND uncaughtException handlers
- [ ] All routes use /api/v1/ prefix
- [ ] Business logic in handlers/ (not server.ts)
- [ ] No file exceeds 300 lines
- [ ] Port assigned in root CLAUDE.md port table
- [ ] Service added to project-docs/ARCHITECTURE.md
- [ ] Basic test file created
- [ ] .dockerignore created (if using Docker)
