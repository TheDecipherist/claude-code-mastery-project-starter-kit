# Project Review Checks: Data Layer and Architecture

Apply these to every diff. These are this codebase's hard rules. A violation here is CRITICAL unless noted. They exist because generic reviewers don't know them.

## Data access

- [ ] **No Mongoose.** Flag any Mongoose import, model, or schema. This codebase never uses Mongoose.
- [ ] **The adapter is the boundary.** Flag raw collection access in feature code. Data access goes through the adapter, which uses StrictDB if installed, otherwise the native driver.
- [ ] **No `_id` in a write body.** Flag any update or upsert payload that contains `_id`. It belongs in the filter, never the update.
- [ ] **Type-safe `_id`.** Flag any query comparing a string against an `ObjectId` `_id`. This silently returns nothing. Confirm the type is rehydrated before the query.
- [ ] **Upsert type rehydration.** Flag upserts that run on JSON-parsed data without `rehydrateTypes`. A string-vs-`ObjectId` `_id` throws code 66.

## Reads and writes

- [ ] **Reads are aggregation pipelines, not `find()`.** Flag `find()` in feature code; it should be a pipeline.
- [ ] **Multi-document writes use `bulkWrite`.** Flag any loop that issues one write per iteration.
- [ ] **No `createIndex` in a request path.** Flag `createIndex` anywhere in a handler or hot loop. Indexes are declared once at startup or in a migration.
- [ ] **No deep nested-array queries.** Flag queries that reach into arrays-within-arrays past `maxDepth=3`. The model needs flattening.
- [ ] **`$elemMatch` is a smell.** Flag `$elemMatch` usage and note that the field probably belongs on the document or in a separate collection.

## Architecture

- [ ] **API versioning.** Routes live under `/api/v1/`. Flag unversioned routes.
- [ ] **No business logic in route handlers.** Handlers wire request to service and back. Flag domain logic inline in a handler.
- [ ] **Service separation respected.** Flag a service reaching across a boundary into another service's internals instead of going through its interface.