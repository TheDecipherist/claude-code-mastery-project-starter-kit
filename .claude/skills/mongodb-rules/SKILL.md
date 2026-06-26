---
name: mongodb-rules
description: Native-driver, StrictDB, and data-modeling rules for MongoDB. Use whenever writing or modifying queries, writes, indexes, aggregations, upserts, connections, or schema against MongoDB, or any code that touches the data layer. Loads inline so it shapes code as it's written.
---

# MongoDB Data-Access Rules

Non-negotiable for this codebase. From production, not preference.

## Driver and connection

- **Prefer StrictDB; fall back to the native driver.** Use StrictDB when it's installed, otherwise the native MongoDB driver directly. Never Mongoose, either way.
- **Data access stays in the adapter,** never raw collections scattered through feature code.
- **One shared `MongoClient` for the whole app**, created once at startup and reused everywhere. The client *is* the pool. Never create one per request, that exhausts connections and looks like "MongoDB went down" under load. In serverless, declare the client at module scope, outside the handler, so warm invocations reuse it.
- **URI comes from an env var,** never hardcoded. Close the client on `SIGTERM`/`SIGINT`.

## Identity and types

- **`_id` is an `ObjectId`, not a string.** A string `_id` against an `ObjectId` document matches nothing, silently. This is the number-one "my id query returns nothing" bug. Wrap incoming ids with `new ObjectId(id)`; for an `$in` list, convert every element.
- **Never put `_id` in the body of any write.** Identity goes in the filter; on insert MongoDB generates it. Restating it after a JSON round-trip throws code 66 (immutable field altered).
- **JSON strips both `ObjectId` and `Date` to strings.** Re-hydrate at the boundary before you query or save, or lookups match nothing and date filters break. Use a parse-time reviver (`parseMongo`) or a bounded post-parse walk (`rehydrateTypes`, `maxDepth=3`). Never patch the global `JSON.parse`. Guard with `ObjectId.isValid` and a `skipKeys` list.
- **Consider a natural string `_id`** (email, SKU, slug) to sidestep the type dance entirely, then ids are strings end to end.
- **Only `_id` is indexed by default.** Sorting by `_id` gives roughly creation order for free, but store an explicit `createdAt` when creation time matters; don't rely on the ObjectId's embedded timestamp.

## Querying

- **`null` is not "missing".** `{ field: null }` matches both explicit null AND absent documents. Use `{ field: { $exists: false } }` for missing, and `{ field: { $ne: null } }` for "has a real value" (which excludes both null and missing).
- **Reads are aggregation pipelines, not `find()`.**
- **Arrays-within-arrays aren't queryable past about three levels** (`maxDepth=3`). If you need to, the model is wrong, flatten it.

## Writes

- **Multi-document writes use `bulkWrite`.** Build the ops array in the loop, execute one `bulkWrite` after it. Never call the database inside a loop.
- **Choose ordered vs unordered deliberately.** `ordered` (default) stops at the first error; `{ ordered: false }` attempts all and collects errors, and is faster. On partial failure, triage transient vs permanent: retry only transient ops with backoff, never blind-retry a duplicate-key or validation failure.
- **Make writes idempotent** (stable keys, set-to-value over blind increments) so retry is safe.
- **Upsert is `updateOne` with `upsert: true`.** Use `$setOnInsert` for insert-only fields, and pair it with a unique index so concurrent upserts can't duplicate.

## Indexing

- **`createIndex` is idempotent but not free**, each call is a round trip. Declare indexes near the queries that need them, but create them once in startup or a migration, never in a handler or hot loop.
- **A compound index serves only a left-to-right prefix of its fields.** Order fields to match how you query; equality-matched fields lead.
- **For filter-plus-sort, follow ESR: Equality, Sort, Range.** Index direction must match the sort or be its exact inverse. An in-memory `SORT` stage in `explain` means the index isn't serving the sort.
- **Filter early** (`$match` first), and put `$limit` before `$lookup`. Diagnose with `explain("executionStats")`: examined far exceeding returned means a missing index.

## Modeling

- **Embed bounded, read-together data; reference unbounded data** (comments, events, logs, anything that accumulates). A document is rewritten and moved as a whole, so an unbounded array degrades writes long before the 16MB hard limit.
- **`$elemMatch` usually signals a modeling problem.** A field you query independently belongs on the document or in its own collection.

## Concurrency and integrity

- **MongoDB has full ACID transactions**, but a single-document write is already atomic. Reach for `session.withTransaction` only for genuine cross-document atomicity (transfer between accounts, decrement stock while creating an order). Frequent transactions are a modeling smell, the data probably wanted to be one document.
- **Unique values are enforced by a unique index, not app-level checks.** Use a partial unique index for optional fields (a plain unique index treats missing as null and collides). Use a compound unique index for "this combination is unique". The duplicate-key error is the guarantee that makes concurrent upserts safe.

## Reads at scale

- **Counting is a choice.** `countDocuments` is exact (index the filter to keep it fast); `estimatedDocumentCount` is instant but approximate and whole-collection only, use it for rough dashboard totals. `distinct` on a high-cardinality field at scale should be a `$group` so the result streams.
- **`$skip` doesn't scale**, it walks past every skipped document. For deep or endless paging, use range/keyset pagination: `$match` on the last-seen value of an indexed sort key, with `_id` as a unique tie-breaker so pages don't shift as data changes.

## Schema

- **Collections enforce no structure by default.** Add a `$jsonSchema` validator as a collection stabilizes and more code depends on its shape. Roll out safely: `validationAction: "warn"` to observe first, then `error`; `validationLevel: "moderate"` to spare existing nonconforming documents.
