---
name: api-conventions
description: Service structure conventions for this codebase: routing, layering, and where code lives. Use whenever writing or modifying a service's server entry, route definitions, handlers, or adapters. Loads inline so it shapes structure as code is written.
---

# Service Architecture Conventions

Every service is three layers, one direction: `server.ts` → `handlers/` → `adapters/`. Apply while writing, not after.

## Versioning

- All routes live under `/api/v1/`. New endpoints are versioned from the first line. No unversioned routes "for now."

## server.ts is thin

- `server.ts` defines routes and delegates. Nothing else.
- No business logic in `server.ts` or in a route definition. A route wires the request to a handler and returns its result.

## handlers/ hold the logic

- Business logic lives in `handlers/`, one file per domain.
- A handler owns its domain's rules and orchestration. It calls adapters for anything external. It does not reach outside the process itself.

## adapters/ wrap everything external

- Database, external APIs, queues, anything outside the process goes through an adapter in `adapters/`. Handlers never touch them directly.
- **The database adapter uses StrictDB when it's installed, otherwise the native driver. Never Mongoose.** A handler that imports a driver or calls an external API inline is wrong, that belongs in an adapter. The data adapter is the one place driver code lives, which is also where the `mongodb-rules` apply.

## Service (package) separation

- A service owns its domain and is reached through its interface. A package does not reach into another package's internals or its data. Call the owning service.
- Code two services both need is hoisted to a shared layer, never imported sideways from a sibling.

The test: routes in `server.ts` read request-in, handler-call, response-out. Logic sits in `handlers/`. Anything that leaves the process goes through `adapters/`, and the data adapter uses StrictDB if installed, the native driver otherwise.
