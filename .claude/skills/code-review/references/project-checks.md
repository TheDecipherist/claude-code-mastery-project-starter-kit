# Project Review Checks: Architecture and Data Layer

Apply these to every diff. They are this codebase's hard rules. A violation is CRITICAL unless noted. They exist because generic reviewers don't know them.

## Layering (server → handlers → adapters)

- [ ] **Routes under `/api/v1/`.** Flag unversioned routes.
- [ ] **`server.ts` is thin.** Flag business logic in `server.ts` or in a route definition; it belongs in `handlers/`.
- [ ] **Business logic in `handlers/`,** one domain per file.
- [ ] **Handlers don't touch external systems directly.** Flag a handler importing a DB driver or calling an external API inline; that goes through an adapter in `adapters/`.
- [ ] **Service (package) separation.** Flag a package reaching into another package's internals instead of going through its interface.

## Data access (lives in the adapter layer)

- [ ] **No Mongoose.** Flag any Mongoose import, model, or schema.
- [ ] **Data access goes through the adapter.** Flag raw collection access outside `adapters/`. Inside the adapter, StrictDB is preferred when installed and the native driver is fine when it isn't, the driver choice is not a violation; Mongoose and raw access in feature code are.
- [ ] **One shared `MongoClient`.** Flag `new MongoClient` inside a request handler or per-call path; the client is created once and reused. In serverless, it must be at module scope, not inside the handler.
- [ ] **No `_id` in a write body.** Flag any update or upsert payload containing `_id`; it belongs in the filter.
- [ ] **Type-safe `_id`.** Flag a query comparing a string against an `ObjectId` `_id`; it silently returns nothing. For `$in`, every element must be converted.
- [ ] **Rehydrate types at the boundary.** Flag saving or querying with a JSON-parsed body whose `ObjectId` and `Date` fields weren't revived; a string-vs-`ObjectId` `_id` throws code 66 and date strings break range/sort.
- [ ] **Reads are aggregation pipelines, not `find()`.** Flag `find()` in feature code.
- [ ] **Multi-document writes use `bulkWrite`,** built once. Flag a database call inside a loop; build the ops array and execute one `bulkWrite` after the loop.
- [ ] **No `createIndex` in a request path.** Flag `createIndex` in a handler or hot loop; indexes are declared once at startup or in a migration.
- [ ] **No deep nested-array queries** past `maxDepth=3`. The model needs flattening.
- [ ] **`$elemMatch` is a smell.** Flag it and note the field probably belongs on the document or in a separate collection.

## Data correctness and scale

- [ ] **`null` vs missing.** Flag a `{ field: null }` match where the intent was "has no value"; it also matches missing. Suggest `$exists` for presence or `$ne: null` for a real value.
- [ ] **No `$skip` for deep pagination.** Flag `$skip` with a large or page-number offset; suggest range pagination on an indexed key with an `_id` tie-breaker.
- [ ] **Right count for the job.** Flag a `countDocuments` used for a rough whole-collection total where `estimatedDocumentCount` belongs, and a `distinct` on a high-cardinality field at scale that should be a `$group`.
- [ ] **No unbounded embedding.** Flag an array that grows without bound (comments, events, logs) being embedded; it should be a referenced collection.
- [ ] **Uniqueness via index, not app check.** Flag an application-level "does this already exist" guard standing in for a unique index, and a plain unique index on an optional field that should be partial.
- [ ] **Transactions are for cross-document atomicity.** Flag a transaction wrapping writes to a single entity (a modeling smell), and a blind whole-batch retry after a partial `bulkWrite` failure.

## Structure

- [ ] **No file exceeds 300 lines.** Flag any file over the limit and point at the natural split (one concern per file).
