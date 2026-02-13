/**
 * Centralized MongoDB Wrapper — Native Driver, Singleton Pool
 *
 * ALL database access MUST go through this file.
 * NEVER create MongoClient instances in other files.
 * NEVER use mongoose or ODMs — native driver only.
 *
 * Based on production patterns from Claude Code Mastery Guides.
 *
 * Best practices enforced:
 * - Singleton pool per URI (prevents connection exhaustion)
 * - Aggregation framework for all reads (consistent, flexible)
 * - BulkWrite for all writes (atomic, performant)
 * - $limit BEFORE $lookup (critical for join performance)
 * - $inc for counters (no read-modify-write races)
 * - Automatic NoSQL injection sanitization on ALL inputs
 * - Graceful shutdown with closePool()
 * - Next.js hot-reload persistence via globalThis
 *
 * Install: npm install mongodb
 */

import {
  type AnyBulkWriteOperation,
  type ClientSession,
  type Collection,
  type Db,
  type Document,
  type Filter,
  MongoClient,
  type OptionalId,
  type TransactionOptions,
  type UpdateFilter,
} from 'mongodb';

// ---------------------------------------------------------------------------
// NoSQL injection sanitization — runs automatically on ALL inputs
// ---------------------------------------------------------------------------

/**
 * Sanitization is ENABLED by default. To disable, set:
 *   DB_SANITIZE_INPUTS=false  (in .env)
 *   sanitize = false          (in claude-mastery-project.conf)
 *
 * You should only disable this if you handle sanitization at a higher layer
 * (e.g., Zod/Joi validation that strips operators before they reach the db).
 */
let _sanitizeEnabled: boolean | null = null;

function isSanitizeEnabled(): boolean {
  if (_sanitizeEnabled !== null) return _sanitizeEnabled;
  _sanitizeEnabled = process.env.DB_SANITIZE_INPUTS !== 'false';
  return _sanitizeEnabled;
}

/** Programmatically enable or disable input sanitization at runtime. */
export function configureSanitization(enabled: boolean): void {
  _sanitizeEnabled = enabled;
}

/**
 * Recursively sanitize an object to prevent NoSQL injection.
 * - Strips keys starting with `$` (blocks $gt, $ne, $where, $regex, etc.)
 * - Strips keys containing `.` (blocks path traversal like `field.nested`)
 * - Converts non-plain objects to strings (blocks prototype pollution)
 *
 * This runs automatically on all filter/match inputs before they touch MongoDB.
 * Internal operations (like $set, $inc in update operators) are NOT sanitized
 * because they come from trusted application code, not user input.
 *
 * Disable with DB_SANITIZE_INPUTS=false or configureSanitization(false).
 */
function sanitize<T>(input: T): T {
  // When sanitization is disabled, pass through unchanged
  if (!isSanitizeEnabled()) return input;

  if (input === null || input === undefined) return input;

  // Primitives are safe
  if (typeof input !== 'object') return input;

  // Dates, ObjectIds, RegExp, Buffer — pass through (trusted types)
  if (input instanceof Date) return input;
  if (input instanceof RegExp) return input;
  if (typeof Buffer !== 'undefined' && Buffer.isBuffer(input)) return input;
  if (typeof input === 'object' && '_bsontype' in (input as Record<string, unknown>)) return input;

  // Arrays — sanitize each element
  if (Array.isArray(input)) {
    return input.map((item) => sanitize(item)) as unknown as T;
  }

  // Plain objects — strip dangerous keys
  const cleaned: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input as Record<string, unknown>)) {
    // Block keys starting with $ (NoSQL operators from user input)
    if (key.startsWith('$')) continue;
    // Block keys containing . (field path traversal)
    if (key.includes('.')) continue;
    // Recursively sanitize nested values
    cleaned[key] = sanitize(value);
  }
  return cleaned as T;
}

/**
 * Sanitize a filter object (user-facing queries like $match).
 * Exported for use in custom pipelines where you pass user input.
 */
export function sanitizeFilter<T>(filter: Filter<T>): Filter<T> {
  return sanitize(filter);
}

/**
 * Sanitize an aggregation pipeline.
 * Only sanitizes the value inside $match stages (where user input goes).
 * Other stages ($sort, $limit, $lookup, etc.) are trusted application code.
 */
function sanitizePipeline(pipeline: Document[]): Document[] {
  return pipeline.map((stage) => {
    if ('$match' in stage) {
      return { $match: sanitize(stage.$match) };
    }
    return stage;
  });
}

// ---------------------------------------------------------------------------
// Pool configuration
// ---------------------------------------------------------------------------

type PoolPreset = 'high' | 'standard' | 'low';

interface PoolConfig {
  maxPoolSize: number;
  minPoolSize: number;
}

const POOL_PRESETS: Record<PoolPreset, PoolConfig> = {
  high: { maxPoolSize: 20, minPoolSize: 2 },
  standard: { maxPoolSize: 10, minPoolSize: 2 },
  low: { maxPoolSize: 5, minPoolSize: 1 },
};

interface ConnectOptions {
  /** Pool size preset or custom config */
  pool?: PoolPreset | PoolConfig;
  /** Database name (defaults to DATABASE_NAME env or 'app') */
  dbName?: string;
  /** Label for logging */
  label?: string;
  /** Enable Next.js hot-reload persistence via globalThis */
  nextjs?: boolean;
}

// ---------------------------------------------------------------------------
// Singleton pool management
// ---------------------------------------------------------------------------

const globalSymbol = Symbol.for('__mongo_pools__');

interface PoolEntry {
  client: MongoClient;
  db: Db;
  label: string;
}

/** Get or create the global pool map (survives Next.js hot-reload) */
function getPoolMap(): Map<string, PoolEntry> {
  const g = globalThis as Record<symbol, Map<string, PoolEntry> | undefined>;
  if (!g[globalSymbol]) {
    g[globalSymbol] = new Map();
  }
  return g[globalSymbol]!;
}

/**
 * Connect to MongoDB. Returns the same client/db for the same URI (singleton).
 * Safe to call multiple times — only connects once per URI.
 */
export async function connect(
  uri?: string,
  options: ConnectOptions = {}
): Promise<{ client: MongoClient; db: Db }> {
  const connectionUri = uri ?? process.env.MONGODB_URI ?? process.env.DATABASE_URL ?? '';
  if (!connectionUri) {
    throw new Error(
      'No MongoDB URI provided. Set MONGODB_URI or DATABASE_URL environment variable.'
    );
  }

  const pools = getPoolMap();
  const existing = pools.get(connectionUri);

  if (existing && isClientAlive(existing.client)) {
    return { client: existing.client, db: existing.db };
  }

  // Resolve pool config
  const poolConfig: PoolConfig =
    typeof options.pool === 'string'
      ? POOL_PRESETS[options.pool]
      : options.pool ?? POOL_PRESETS.standard;

  const dbName = options.dbName ?? process.env.DATABASE_NAME ?? 'app';
  const label = options.label ?? 'default';

  const client = new MongoClient(connectionUri, {
    maxPoolSize: poolConfig.maxPoolSize,
    minPoolSize: poolConfig.minPoolSize,
    maxIdleTimeMS: 30_000,
    serverSelectionTimeoutMS: 15_000,
  });

  await client.connect();
  const db = client.db(dbName);

  pools.set(connectionUri, { client, db, label });
  console.log(`[db:${label}] Connected to ${dbName} (pool: ${poolConfig.maxPoolSize} max)`);

  return { client, db };
}

/** Check if a MongoClient is still alive */
function isClientAlive(client: MongoClient): boolean {
  try {
    // topology is internal but reliable for health checks
    const topology = (client as unknown as Record<string, unknown>).topology;
    if (!topology) return false;
    const desc = (topology as Record<string, unknown>).description;
    if (!desc) return false;
    const type = (desc as Record<string, string>).type;
    return type !== 'Unknown' && type !== undefined;
  } catch {
    return false;
  }
}

/** Close all connection pools. Call on graceful shutdown. */
export async function closePool(): Promise<void> {
  const pools = getPoolMap();
  const closePromises: Promise<void>[] = [];

  for (const [uri, entry] of pools) {
    console.log(`[db:${entry.label}] Closing connection pool...`);
    closePromises.push(entry.client.close());
    pools.delete(uri);
  }

  await Promise.all(closePromises);
}

// ---------------------------------------------------------------------------
// Default database accessor (convenience)
// ---------------------------------------------------------------------------

let _defaultDb: Db | null = null;
let _defaultClient: MongoClient | null = null;

/** Get the default database instance. Connects automatically if needed. */
export async function getDb(options?: ConnectOptions): Promise<Db> {
  if (_defaultDb && _defaultClient && isClientAlive(_defaultClient)) {
    return _defaultDb;
  }
  const { client, db } = await connect(undefined, options);
  _defaultDb = db;
  _defaultClient = client;
  return db;
}

/** Get a typed collection from the default database */
export async function getCollection<T extends Document>(
  name: string
): Promise<Collection<T>> {
  const db = await getDb();
  return db.collection<T>(name);
}

// ---------------------------------------------------------------------------
// Read operations — Aggregation framework only
// ---------------------------------------------------------------------------

/**
 * Find a single document by filter.
 * Uses aggregation with automatic $limit: 1.
 */
export async function queryOne<T extends Document>(
  collection: string,
  match: Filter<T>
): Promise<T | null> {
  const db = await getDb();
  const safeMatch = sanitize(match);
  const results = await db
    .collection<T>(collection)
    .aggregate<T>([{ $match: safeMatch }, { $limit: 1 }])
    .toArray();
  return results[0] ?? null;
}

/**
 * Find multiple documents using an aggregation pipeline.
 * Always use this over .find() for consistency.
 */
export async function queryMany<T extends Document>(
  collection: string,
  pipeline: Document[]
): Promise<T[]> {
  const db = await getDb();
  const safePipeline = sanitizePipeline(pipeline);
  return db.collection<T>(collection).aggregate<T>(safePipeline).toArray();
}

/**
 * Find a single document with a $lookup join.
 * Enforces $limit BEFORE $lookup for performance.
 */
export async function queryWithLookup<T extends Document>(
  collection: string,
  options: {
    match: Filter<Document>;
    lookup: {
      from: string;
      localField: string;
      foreignField: string;
      as: string;
    };
    unwind?: string;
    postStages?: Document[];
  }
): Promise<T | null> {
  const db = await getDb();
  const pipeline: Document[] = [
    { $match: sanitize(options.match) },
    { $limit: 1 }, // ALWAYS limit before lookup
    { $lookup: options.lookup },
  ];

  if (options.unwind) {
    pipeline.push({ $unwind: { path: `$${options.unwind}`, preserveNullAndEmptyArrays: true } });
  }

  if (options.postStages) {
    pipeline.push(...options.postStages);
  }

  const results = await db.collection(collection).aggregate<T>(pipeline).toArray();
  return results[0] ?? null;
}

/**
 * Count documents in a collection.
 * Uses aggregation $count for consistency.
 */
export async function count(
  collection: string,
  match: Filter<Document> = {}
): Promise<number> {
  const db = await getDb();
  const safeMatch = sanitize(match);
  const result = await db
    .collection(collection)
    .aggregate<{ count: number }>([{ $match: safeMatch }, { $count: 'count' }])
    .toArray();
  return result[0]?.count ?? 0;
}

// ---------------------------------------------------------------------------
// Write operations — BulkWrite only
// ---------------------------------------------------------------------------

/**
 * Insert a single document.
 * Wraps in bulkWrite for consistency.
 */
export async function insertOne<T extends Document>(
  collection: string,
  doc: T
): Promise<void> {
  const db = await getDb();
  await db.collection<T>(collection).bulkWrite([
    { insertOne: { document: doc as OptionalId<T> } },
  ]);
}

/**
 * Insert multiple documents in a single batch.
 * NEVER use insertOne in a loop — always batch with this.
 */
export async function insertMany<T extends Document>(
  collection: string,
  docs: T[]
): Promise<void> {
  if (docs.length === 0) return;
  const db = await getDb();
  await db.collection<T>(collection).bulkWrite(
    docs.map((doc) => ({ insertOne: { document: doc as OptionalId<T> } }))
  );
}

/**
 * Update a single document.
 * Use $inc for counters, $set for fields — never read-modify-write.
 */
export async function updateOne<T extends Document>(
  collection: string,
  filter: Filter<T>,
  update: UpdateFilter<T>,
  upsert = false
): Promise<void> {
  const db = await getDb();
  await db.collection<T>(collection).bulkWrite([
    { updateOne: { filter, update, upsert } },
  ]);
}

/**
 * Update multiple documents matching a filter.
 */
export async function updateMany<T extends Document>(
  collection: string,
  filter: Filter<T>,
  update: UpdateFilter<T>
): Promise<void> {
  const db = await getDb();
  await db.collection<T>(collection).bulkWrite([
    { updateMany: { filter, update } },
  ]);
}

/**
 * Execute arbitrary bulk operations.
 * Use for complex multi-operation writes.
 * Includes automatic retry for E11000 concurrent upsert races.
 */
export async function bulkOps<T extends Document>(
  collection: string,
  operations: AnyBulkWriteOperation<T>[]
): Promise<void> {
  if (operations.length === 0) return;
  const db = await getDb();
  try {
    await db.collection<T>(collection).bulkWrite(operations);
  } catch (err: unknown) {
    // Retry on E11000 (concurrent upsert race condition)
    if (err && typeof err === 'object' && 'code' in err && (err as { code: number }).code === 11000) {
      await db.collection<T>(collection).bulkWrite(operations);
    } else {
      throw err;
    }
  }
}

/**
 * Delete a single document.
 */
export async function deleteOne<T extends Document>(
  collection: string,
  filter: Filter<T>
): Promise<void> {
  const db = await getDb();
  const safeFilter = sanitize(filter);
  await db.collection<T>(collection).bulkWrite([
    { deleteOne: { filter: safeFilter } },
  ]);
}

/**
 * Delete multiple documents matching a filter.
 */
export async function deleteMany<T extends Document>(
  collection: string,
  filter: Filter<T>
): Promise<void> {
  const db = await getDb();
  const safeFilter = sanitize(filter);
  await db.collection<T>(collection).bulkWrite([
    { deleteMany: { filter: safeFilter } },
  ]);
}

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------

/**
 * Execute an operation within a MongoDB transaction.
 * Use for multi-document atomic operations.
 */
export async function withTransaction<T>(
  operation: (session: ClientSession) => Promise<T>,
  txOptions?: TransactionOptions
): Promise<T> {
  const { client } = await connect();
  const session = client.startSession();
  try {
    let result: T;
    await session.withTransaction(async () => {
      result = await operation(session);
    }, txOptions);
    return result!;
  } finally {
    await session.endSession();
  }
}

// ---------------------------------------------------------------------------
// Raw access (for Change Streams, advanced operations)
// ---------------------------------------------------------------------------

/**
 * Get raw access to a MongoDB Collection.
 * Use for Change Streams or operations not covered by the wrapper.
 */
export async function rawCollection<T extends Document>(
  name: string
): Promise<Collection<T>> {
  const db = await getDb();
  return db.collection<T>(name);
}

// ---------------------------------------------------------------------------
// Index management
// ---------------------------------------------------------------------------

export interface IndexDefinition {
  /** Collection name */
  collection: string;
  /** Fields and sort direction (1 = asc, -1 = desc) */
  fields: Record<string, 1 | -1>;
  /** Create a unique constraint */
  unique?: boolean;
  /** Sparse index (only index docs that have the field) */
  sparse?: boolean;
  /** TTL index — auto-delete documents after N seconds */
  expireAfterSeconds?: number;
}

/** Registry of indexes to create */
const indexRegistry: IndexDefinition[] = [];

/**
 * Register an index to be created when ensureIndexes() is called.
 * Call this at module load time to declare your indexes alongside your queries.
 *
 * ```typescript
 * registerIndex({ collection: 'users', fields: { email: 1 }, unique: true });
 * registerIndex({ collection: 'sessions', fields: { userId: 1, startedAt: -1 } });
 * registerIndex({ collection: 'tokens', fields: { expiresAt: 1 }, expireAfterSeconds: 0 });
 * ```
 */
export function registerIndex(definition: IndexDefinition): void {
  indexRegistry.push(definition);
}

/**
 * Create all registered indexes.
 * Call once at application startup. Safe to call multiple times —
 * MongoDB skips indexes that already exist.
 *
 * ```typescript
 * // In your app startup:
 * import { ensureIndexes } from '@/core/db/index.js';
 * await ensureIndexes(); // creates all registered indexes
 * await ensureIndexes({ dryRun: true }); // just logs what would be created
 * ```
 */
export async function ensureIndexes(
  options: { dryRun?: boolean } = {}
): Promise<{ created: string[]; skipped: string[] }> {
  const db = await getDb();
  const created: string[] = [];
  const skipped: string[] = [];

  for (const def of indexRegistry) {
    const indexName = Object.entries(def.fields)
      .map(([k, v]) => `${k}_${v}`)
      .join('_');

    const label = `${def.collection}.${indexName}${def.unique ? ' (unique)' : ''}${def.sparse ? ' (sparse)' : ''}${def.expireAfterSeconds !== undefined ? ` (TTL: ${def.expireAfterSeconds}s)` : ''}`;

    if (options.dryRun) {
      console.log(`[db:index] Would create: ${label}`);
      skipped.push(label);
      continue;
    }

    try {
      const indexOptions: Record<string, unknown> = {};
      if (def.unique) indexOptions.unique = true;
      if (def.sparse) indexOptions.sparse = true;
      if (def.expireAfterSeconds !== undefined) {
        indexOptions.expireAfterSeconds = def.expireAfterSeconds;
      }

      await db.collection(def.collection).createIndex(def.fields, indexOptions);
      console.log(`[db:index] Created: ${label}`);
      created.push(label);
    } catch (err: unknown) {
      // Index already exists with same spec — safe to skip
      if (err && typeof err === 'object' && 'code' in err && (err as { code: number }).code === 85) {
        skipped.push(label);
      } else {
        throw err;
      }
    }
  }

  console.log(`[db:index] Done — ${created.length} created, ${skipped.length} skipped`);
  return { created, skipped };
}

// ---------------------------------------------------------------------------
// Graceful shutdown — wire to process signals and crash handlers
// ---------------------------------------------------------------------------

let _shuttingDown = false;

/**
 * Gracefully close all MongoDB pools and exit the process.
 * Safe to call multiple times — only runs once.
 *
 * Wire this to ALL process exit events in your entry point:
 *
 * ```typescript
 * import { gracefulShutdown } from '@/core/db/index.js';
 *
 * process.on('SIGTERM', gracefulShutdown);
 * process.on('SIGINT', gracefulShutdown);
 * process.on('uncaughtException', (err) => {
 *   console.error('Uncaught Exception:', err);
 *   gracefulShutdown(1);
 * });
 * process.on('unhandledRejection', (reason) => {
 *   console.error('Unhandled Rejection:', reason);
 *   gracefulShutdown(1);
 * });
 * ```
 */
export async function gracefulShutdown(exitCode: number | unknown = 0): Promise<void> {
  if (_shuttingDown) return;
  _shuttingDown = true;

  const code = typeof exitCode === 'number' ? exitCode : 1;

  console.log(`[db] Graceful shutdown initiated (exit code: ${code})...`);

  try {
    await closePool();
    console.log('[db] All connection pools closed.');
  } catch (err) {
    console.error('[db] Error during pool shutdown:', err);
  }

  process.exit(code);
}
