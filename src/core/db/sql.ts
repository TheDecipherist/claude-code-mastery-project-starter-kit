/**
 * Centralized SQL Database Wrapper — PostgreSQL, MySQL, MSSQL, SQLite
 *
 * ALL SQL database access MUST go through this file.
 * NEVER create connection pools anywhere else.
 * NEVER import `pg`/`mysql2`/`mssql`/`better-sqlite3` directly in other files.
 *
 * Mirrors the MongoDB wrapper pattern (src/core/db/index.ts):
 * - Singleton pool per URI (prevents connection exhaustion)
 * - Parameterized queries ALWAYS (prevents SQL injection)
 * - Graceful shutdown with closePool()
 * - Next.js hot-reload persistence via globalThis
 *
 * Driver auto-detection from DATABASE_URL scheme:
 *   postgresql:// or postgres:// → pg
 *   mysql://                     → mysql2
 *   mssql://                     → mssql
 *   file: or sqlite:            → better-sqlite3
 *
 * Install the driver for your database:
 *   PostgreSQL: npm install pg @types/pg
 *   MySQL:      npm install mysql2
 *   MSSQL:      npm install mssql
 *   SQLite:     npm install better-sqlite3 @types/better-sqlite3
 */

// ─── Types ──────────────────────────────────────────────────────────────────

export interface PoolOptions {
  pool?: 'high' | 'standard' | 'low';
  label?: string;
}

export interface ResultSet {
  rowCount: number;
  rows?: unknown[];
}

interface PoolClient {
  query(sql: string, params?: unknown[]): Promise<{ rows: unknown[]; rowCount: number }>;
  release(): void;
}

interface Pool {
  query(sql: string, params?: unknown[]): Promise<{ rows: unknown[]; rowCount: number }>;
  connect(): Promise<PoolClient>;
  end(): Promise<void>;
}

// ─── Pool Presets ───────────────────────────────────────────────────────────

const POOL_PRESETS = {
  high: { max: 20, min: 2 },
  standard: { max: 10, min: 2 },
  low: { max: 5, min: 1 },
} as const;

// ─── Singleton Pool ─────────────────────────────────────────────────────────

const POOL_KEY = Symbol.for('__sql_pool__');
const LABEL_KEY = Symbol.for('__sql_label__');

function getGlobal(): { pool?: Pool; label?: string } {
  const g = globalThis as Record<symbol, unknown>;
  return {
    pool: g[POOL_KEY] as Pool | undefined,
    label: g[LABEL_KEY] as string | undefined,
  };
}

function setGlobal(pool: Pool, label: string): void {
  const g = globalThis as Record<symbol, unknown>;
  g[POOL_KEY] = pool;
  g[LABEL_KEY] = label;
}

function clearGlobal(): void {
  const g = globalThis as Record<symbol, unknown>;
  delete g[POOL_KEY];
  delete g[LABEL_KEY];
}

// ─── Connection ─────────────────────────────────────────────────────────────

/**
 * Connect to the SQL database. Auto-detects driver from DATABASE_URL scheme.
 *
 * @param uri - Connection string (defaults to process.env.DATABASE_URL)
 * @param opts - Pool size preset and label
 *
 * @example
 * await connect(); // uses DATABASE_URL from .env
 * await connect(undefined, { pool: 'high', label: 'API' });
 */
export async function connect(
  uri?: string,
  opts: PoolOptions = {},
): Promise<void> {
  const existing = getGlobal();
  if (existing.pool) return; // Already connected

  const connectionString = uri ?? process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error('DATABASE_URL not set and no URI provided');
  }

  const preset = POOL_PRESETS[opts.pool ?? 'standard'];
  const label = opts.label ?? 'SQL';
  const driver = detectDriver(connectionString);

  let pool: Pool;

  switch (driver) {
    case 'pg': {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const { Pool: PgPool } = await import('pg');
      pool = new PgPool({
        connectionString,
        max: preset.max,
        min: preset.min,
        idleTimeoutMillis: 30_000,
        connectionTimeoutMillis: 5_000,
      }) as unknown as Pool;
      break;
    }
    case 'mysql2': {
      const mysql = await import('mysql2/promise');
      const mysqlPool = mysql.createPool({
        uri: connectionString,
        connectionLimit: preset.max,
        waitForConnections: true,
        queueLimit: 0,
      });
      // Adapt mysql2 pool to our Pool interface
      pool = {
        async query(sql: string, params?: unknown[]) {
          const [rows] = await mysqlPool.execute(sql, params);
          const resultRows = Array.isArray(rows) ? rows : [];
          return { rows: resultRows as unknown[], rowCount: resultRows.length };
        },
        async connect() {
          const conn = await mysqlPool.getConnection();
          return {
            async query(sql: string, params?: unknown[]) {
              const [rows] = await conn.execute(sql, params);
              const resultRows = Array.isArray(rows) ? rows : [];
              return { rows: resultRows as unknown[], rowCount: resultRows.length };
            },
            release() { conn.release(); },
          };
        },
        async end() { await mysqlPool.end(); },
      };
      break;
    }
    case 'mssql': {
      const mssql = await import('mssql');
      const mssqlPool = await mssql.connect({
        connectionString,
        pool: { max: preset.max, min: preset.min },
      } as mssql.config);
      pool = {
        async query(sql: string, params?: unknown[]) {
          const request = mssqlPool.request();
          params?.forEach((p, i) => request.input(`p${i + 1}`, p));
          // MSSQL uses @p1, @p2 instead of $1, $2
          const adapted = sql.replace(/\$(\d+)/g, (_, n) => `@p${n}`);
          const result = await request.query(adapted);
          return { rows: result.recordset ?? [], rowCount: result.rowsAffected[0] ?? 0 };
        },
        async connect() {
          return {
            async query(sql: string, params?: unknown[]) {
              const request = mssqlPool.request();
              params?.forEach((p, i) => request.input(`p${i + 1}`, p));
              const adapted = sql.replace(/\$(\d+)/g, (_, n) => `@p${n}`);
              const result = await request.query(adapted);
              return { rows: result.recordset ?? [], rowCount: result.rowsAffected[0] ?? 0 };
            },
            release() { /* MSSQL pools manage connections internally */ },
          };
        },
        async end() { await mssqlPool.close(); },
      };
      break;
    }
    case 'sqlite': {
      const Database = (await import('better-sqlite3')).default;
      const dbPath = connectionString.replace(/^(file:|sqlite:)\/\//, '');
      const db = new Database(dbPath);
      db.pragma('journal_mode = WAL');
      pool = {
        async query(sql: string, params?: unknown[]) {
          // Convert $1, $2 placeholders to ? for SQLite
          const adapted = sql.replace(/\$\d+/g, '?');
          if (adapted.trimStart().toUpperCase().startsWith('SELECT') ||
              adapted.trimStart().toUpperCase().startsWith('WITH')) {
            const rows = db.prepare(adapted).all(...(params ?? []));
            return { rows: rows as unknown[], rowCount: rows.length };
          }
          const result = db.prepare(adapted).run(...(params ?? []));
          return { rows: [], rowCount: result.changes };
        },
        async connect() {
          return {
            async query(sql: string, params?: unknown[]) {
              const adapted = sql.replace(/\$\d+/g, '?');
              if (adapted.trimStart().toUpperCase().startsWith('SELECT') ||
                  adapted.trimStart().toUpperCase().startsWith('WITH')) {
                const rows = db.prepare(adapted).all(...(params ?? []));
                return { rows: rows as unknown[], rowCount: rows.length };
              }
              const result = db.prepare(adapted).run(...(params ?? []));
              return { rows: [], rowCount: result.changes };
            },
            release() { /* SQLite is single-connection */ },
          };
        },
        async end() { db.close(); },
      };
      break;
    }
    default:
      throw new Error(`Unsupported database driver: ${driver}. DATABASE_URL must start with postgresql://, postgres://, mysql://, mssql://, file:, or sqlite:`);
  }

  setGlobal(pool, label);
  console.log(`[${label}] SQL pool connected (${opts.pool ?? 'standard'} preset, max=${preset.max})`);
}

// ─── Pool Access ────────────────────────────────────────────────────────────

/** Get the active connection pool. Throws if not connected. */
export function getPool(): Pool {
  const { pool } = getGlobal();
  if (!pool) throw new Error('SQL pool not connected. Call connect() first.');
  return pool;
}

/** Close the connection pool. */
export async function closePool(): Promise<void> {
  const { pool, label } = getGlobal();
  if (!pool) return;
  await pool.end();
  clearGlobal();
  console.log(`[${label}] SQL pool closed`);
}

// ─── Graceful Shutdown ──────────────────────────────────────────────────────

let shutdownCalled = false;

/** Idempotent shutdown — safe to call from multiple signal handlers. */
export function gracefulShutdown(exitCode = 0): void {
  if (shutdownCalled) return;
  shutdownCalled = true;
  closePool()
    .catch((err) => console.error('Error closing SQL pool:', err))
    .finally(() => process.exit(exitCode));
}

// ─── Read Operations ────────────────────────────────────────────────────────

/**
 * Query a single row. Returns null if not found.
 * ALWAYS use parameterized queries — NEVER interpolate values.
 *
 * @example
 * const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
 */
export async function queryOne<T>(sql: string, params?: unknown[]): Promise<T | null> {
  const pool = getPool();
  const result = await pool.query(sql, params);
  return (result.rows[0] as T) ?? null;
}

/**
 * Query multiple rows.
 *
 * @example
 * const users = await queryMany<User>('SELECT * FROM users WHERE role = $1 LIMIT $2', ['admin', 50]);
 */
export async function queryMany<T>(sql: string, params?: unknown[]): Promise<T[]> {
  const pool = getPool();
  const result = await pool.query(sql, params);
  return result.rows as T[];
}

/**
 * Count rows in a table with optional WHERE clause.
 *
 * @example
 * const total = await count('users', { role: 'admin' });
 */
export async function count(table: string, where?: Record<string, unknown>): Promise<number> {
  const pool = getPool();
  if (!where || Object.keys(where).length === 0) {
    const result = await pool.query(`SELECT COUNT(*) as count FROM "${table}"`);
    return Number((result.rows[0] as { count: string | number }).count);
  }
  const { clause, values } = buildWhere(where);
  const result = await pool.query(`SELECT COUNT(*) as count FROM "${table}" WHERE ${clause}`, values);
  return Number((result.rows[0] as { count: string | number }).count);
}

// ─── Write Operations ───────────────────────────────────────────────────────

/**
 * Execute a raw SQL statement.
 *
 * @example
 * await execute('UPDATE users SET active = $1 WHERE last_login < $2', [false, cutoffDate]);
 */
export async function execute(sql: string, params?: unknown[]): Promise<ResultSet> {
  const pool = getPool();
  const result = await pool.query(sql, params);
  return { rowCount: result.rowCount, rows: result.rows };
}

/**
 * Insert a single row into a table.
 *
 * @example
 * await insertOne('users', { email: 'a@b.com', name: 'Alice', created_at: new Date() });
 */
export async function insertOne(table: string, data: Record<string, unknown>): Promise<ResultSet> {
  const keys = Object.keys(data);
  const values = Object.values(data);
  const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
  const columns = keys.map((k) => `"${k}"`).join(', ');
  return execute(
    `INSERT INTO "${table}" (${columns}) VALUES (${placeholders})`,
    values,
  );
}

/**
 * Insert multiple rows in a single statement.
 *
 * @example
 * await insertMany('events', [{ type: 'click', ts: new Date() }, { type: 'view', ts: new Date() }]);
 */
export async function insertMany(table: string, rows: Record<string, unknown>[]): Promise<void> {
  if (rows.length === 0) return;
  const keys = Object.keys(rows[0]!);
  const columns = keys.map((k) => `"${k}"`).join(', ');
  const allValues: unknown[] = [];
  const rowPlaceholders: string[] = [];

  rows.forEach((row, rowIdx) => {
    const placeholders = keys.map((_, colIdx) => `$${rowIdx * keys.length + colIdx + 1}`);
    rowPlaceholders.push(`(${placeholders.join(', ')})`);
    keys.forEach((k) => allValues.push(row[k]));
  });

  await execute(
    `INSERT INTO "${table}" (${columns}) VALUES ${rowPlaceholders.join(', ')}`,
    allValues,
  );
}

/**
 * Update a single row matching the WHERE clause.
 *
 * @example
 * await updateOne('users', { id: 1 }, { name: 'Bob', updated_at: new Date() });
 */
export async function updateOne(
  table: string,
  where: Record<string, unknown>,
  set: Record<string, unknown>,
): Promise<ResultSet> {
  const setKeys = Object.keys(set);
  const whereKeys = Object.keys(where);
  const allValues = [...Object.values(set), ...Object.values(where)];

  const setClauses = setKeys.map((k, i) => `"${k}" = $${i + 1}`).join(', ');
  const whereClauses = whereKeys.map((k, i) => `"${k}" = $${setKeys.length + i + 1}`).join(' AND ');

  return execute(
    `UPDATE "${table}" SET ${setClauses} WHERE ${whereClauses}`,
    allValues,
  );
}

/**
 * Delete a single row matching the WHERE clause.
 *
 * @example
 * await deleteOne('tokens', { token: 'abc123' });
 */
export async function deleteOne(table: string, where: Record<string, unknown>): Promise<ResultSet> {
  const { clause, values } = buildWhere(where);
  return execute(`DELETE FROM "${table}" WHERE ${clause}`, values);
}

// ─── Transactions ───────────────────────────────────────────────────────────

/**
 * Execute a function within a database transaction.
 * Automatically commits on success, rolls back on error.
 *
 * @example
 * const result = await withTransaction(async (client) => {
 *   await client.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [100, fromId]);
 *   await client.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [100, toId]);
 *   return { success: true };
 * });
 */
export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>,
): Promise<T> {
  const pool = getPool();
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// ─── SQL Injection Prevention ───────────────────────────────────────────────

/**
 * Build a parameterized WHERE clause from a key-value object.
 * NEVER string-interpolate user input into SQL — use this instead.
 *
 * @example
 * const { clause, values } = buildWhere({ email: 'a@b.com', active: true });
 * // clause: '"email" = $1 AND "active" = $2'
 * // values: ['a@b.com', true]
 */
export function buildWhere(
  where: Record<string, unknown>,
  startIdx = 1,
): { clause: string; values: unknown[] } {
  const keys = Object.keys(where);
  const values = Object.values(where);
  const clause = keys.map((k, i) => `"${k}" = $${startIdx + i}`).join(' AND ');
  return { clause, values };
}

// ─── Driver Detection ───────────────────────────────────────────────────────

type DriverType = 'pg' | 'mysql2' | 'mssql' | 'sqlite';

function detectDriver(uri: string): DriverType {
  if (uri.startsWith('postgresql://') || uri.startsWith('postgres://')) return 'pg';
  if (uri.startsWith('mysql://')) return 'mysql2';
  if (uri.startsWith('mssql://')) return 'mssql';
  if (uri.startsWith('file:') || uri.startsWith('sqlite:')) return 'sqlite';
  throw new Error(
    `Cannot detect SQL driver from URI. Expected scheme: postgresql://, postgres://, mysql://, mssql://, file:, or sqlite:. Got: ${uri.substring(0, 20)}...`,
  );
}
