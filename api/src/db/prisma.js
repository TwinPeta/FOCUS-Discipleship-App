const config = require('../config');
const store = require('./store');
const M = require('./mapping');

/**
 * PostgreSQL persistence through Prisma (schema: prisma/schema.prisma, migrations: prisma/migrations).
 *
 * Routes keep using the synchronous in-memory helpers in store.js (a working set held in RAM).
 * This module makes that working set durable. Each collection is a real relational table with typed columns
 * and foreign keys (prisma/spec.js -> prisma/schema.prisma); src/db/mapping.js converts documents <-> rows:
 *   - `load()` hydrates memory from the tables on boot
 *   - `flush()` diffs memory against what was last written and upserts/deletes only the changes, parents
 *     before children, in one transaction. It runs shortly after every mutating request, on a timer, and on shutdown.
 * Because it diffs state, it also captures direct mutations (`user.x = y`), not only store.insert().
 * Limit: the API process is the single writer. Run ONE instance (the PM2 script already does).
 */
let client = null;
let snap = {}; // collection -> Map(id -> json string) as last persisted
let chain = Promise.resolve();
let timer = null;

const enabled = () => !!config.databaseUrl;

// Stable JSON (sorted keys) so a document loaded from a row compares equal to the same document in memory.
const stable = (d) => JSON.stringify(d, (_, v) => (v && typeof v === 'object' && !Array.isArray(v) ? Object.fromEntries(Object.keys(v).sort().map((k) => [k, v[k]])) : v));
const dg = (c) => M.delegate(c);

function prisma() {
  if (!client) {
    const { PrismaClient } = require('@prisma/client');
    client = new PrismaClient({ datasourceUrl: config.databaseUrl, log: ['warn', 'error'] });
    M.setDbNull(require('@prisma/client').Prisma.DbNull);
  }
  return client;
}
/** Test hook: inject a stand-in client. */
function useClient(c) { client = c; }

/** Boot: verify the connection and that migrations were applied. */
async function init() {
  const p = prisma();
  try {
    await p.user.count();
  } catch (e) {
    if (e.code === 'P2021') throw new Error('Database tables are missing. Run `npm run db:deploy` (prisma migrate deploy) first.');
    throw e;
  }
}

async function load() {
  const p = prisma();
  snap = {};
  let rows = 0;
  for (const c of M.order()) {
    const r = await p[dg(c)].findMany({ orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] });
    store.db[c] = r.map((x) => M.fromRow(c, x));
    snap[c] = new Map(store.db[c].map((d) => [d.id, stable(d)]));
    rows += r.length;
  }
  return rows;
}

const warned = new Set();
async function doFlush() {
  if (!client && !enabled()) return 0;
  const p = prisma();
  const exists = (c, id) => store.get(c, id) !== null;
  const names = M.order(); // parents first
  const upserts = [];
  const deletes = [];
  const next = {};
  for (const c of names) {
    const before = snap[c] || new Map();
    const after = new Map();
    for (const d of store.db[c]) {
      const j = stable(d);
      if (before.get(d.id) === j) { after.set(d.id, j); continue; }
      const row = M.resolveFks(c, M.toRow(c, d), exists);
      if (!row) { // orphan: required parent missing; not persisted
        if (!warned.has(d.id)) { warned.add(d.id); console.warn(`[db] skipped ${c}/${d.id}: missing parent record`); }
        continue;
      }
      const { id, ...rest } = row;
      upserts.push(p[dg(c)].upsert({ where: { id }, create: row, update: rest }));
      after.set(d.id, j);
    }
    const gone = [...before.keys()].filter((id) => !after.has(id));
    if (gone.length) deletes.unshift(p[dg(c)].deleteMany({ where: { id: { in: gone } } })); // children before parents
    next[c] = after;
  }
  const ops = [...deletes, ...upserts];
  if (!ops.length) return 0;
  await p.$transaction(ops);
  snap = next; // only advance once committed; on failure the next flush retries the same diff
  return ops.length;
}

/** Serialised flush: never two at once. Resolves when this flush (and any earlier one) is done. */
function flush() {
  chain = chain.then(doFlush).catch((e) => { console.error('[db] flush failed (will retry):', e.message); });
  return chain;
}

/** Debounced flush for use after mutating requests. */
function schedule(ms = 150) {
  if (!enabled() || timer) return;
  timer = setTimeout(() => { timer = null; flush(); }, ms);
  timer.unref();
}

/** Express middleware: persist shortly after any non-GET request completes. */
function persistAfterWrites(req, res, next) {
  if (enabled() && !['GET', 'HEAD', 'OPTIONS'].includes(req.method)) res.on('finish', () => schedule());
  next();
}

async function close() {
  if (timer) { clearTimeout(timer); timer = null; }
  await flush();
  if (client) { await client.$disconnect(); client = null; }
}

module.exports = { enabled, init, load, flush, schedule, persistAfterWrites, close, useClient };
