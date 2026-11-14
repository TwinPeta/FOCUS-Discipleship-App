const spec = require('../../prisma/spec');

/**
 * Document <-> relational row conversion, driven by prisma/spec.js.
 * Lossless: any field without a column (or with an unexpected runtime type) is kept in `extra`.
 */
let DB_NULL = null; // Prisma.DbNull for nullable Json columns (injected by prisma.js)
const setDbNull = (v) => { DB_NULL = v; };

const parse = (t) => ({ type: t.replace('?', ''), nullable: t.endsWith('?') });
const isIso = (v) => typeof v === 'string' && v.length >= 10 && !Number.isNaN(Date.parse(v));

const CHECK = {
  s: (v) => typeof v === 'string',
  i: (v) => Number.isInteger(v) && Math.abs(v) < 2 ** 31,
  b: (v) => typeof v === 'boolean',
  d: isIso,
  D: (v) => typeof v === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(v)),
  e: (v) => typeof v === 'number' && Number.isFinite(v),
  j: () => true,
  ss: (v) => Array.isArray(v) && v.every((x) => typeof x === 'string'),
};
const ENC = { d: (v) => new Date(v), D: (v) => new Date(`${v}T00:00:00Z`), e: (v) => new Date(v) };
const DEC = { d: (v) => v.toISOString(), D: (v) => v.toISOString().slice(0, 10), e: (v) => v.getTime() };
const ZERO = { s: '', i: 0, b: false, d: new Date(0), D: new Date(0), e: new Date(0), j: [], ss: [] }; // for required columns whose field is absent

/** collection -> delegate name on the Prisma client (model User -> prisma.user) */
const model = (c) => {
  const s = c.endsWith('ies') ? `${c.slice(0, -3)}y` : c.endsWith('s') && !c.endsWith('ss') ? c.slice(0, -1) : c;
  return s[0].toUpperCase() + s.slice(1);
};
const delegate = (c) => model(c)[0].toLowerCase() + model(c).slice(1);

const columns = (c) => Object.entries(spec[c].cols).map(([name, t]) => ({ name, ...parse(t) }));

function toRow(c, doc) {
  const known = new Set(['id', 'createdAt', ...Object.keys(spec[c].cols)]);
  const row = { id: doc.id, createdAt: isIso(doc.createdAt) ? new Date(doc.createdAt) : new Date() };
  const extra = {};
  if (doc.createdAt === undefined) extra['__absent:createdAt'] = 1;
  for (const k of Object.keys(doc)) if (!known.has(k)) extra[k] = doc[k];
  if (doc.createdAt !== undefined && !isIso(doc.createdAt)) extra.createdAt = doc.createdAt;

  for (const col of columns(c)) {
    const v = doc[col.name];
    if (v === undefined || v === null) {
      if (v === null) extra[`__null:${col.name}`] = 1; // remember an explicit null so a round trip is exact
      row[col.name] = col.nullable ? (col.type === 'j' ? DB_NULL : null) : ZERO[col.type];
      if (!col.nullable && v === undefined) extra[`__absent:${col.name}`] = 1;
    } else if (CHECK[col.type](v)) {
      row[col.name] = ENC[col.type] ? ENC[col.type](v) : v;
    } else {
      extra[col.name] = v; // unexpected type: keep losslessly
      row[col.name] = col.nullable ? (col.type === 'j' ? DB_NULL : null) : ZERO[col.type];
      extra[`__absent:${col.name}`] = 1;
    }
  }
  row.extra = Object.keys(extra).length ? extra : DB_NULL;
  return row;
}

function fromRow(c, row) {
  const extra = { ...(row.extra || {}) };
  const doc = { id: row.id };
  if (!extra['__absent:createdAt']) doc.createdAt = row.createdAt.toISOString();
  for (const col of columns(c)) {
    if (extra[`__absent:${col.name}`]) { delete extra[`__absent:${col.name}`]; continue; }
    const v = row[col.name];
    if (v === null || v === undefined) {
      if (extra[`__null:${col.name}`]) doc[col.name] = null;
    } else doc[col.name] = DEC[col.type] ? DEC[col.type](v) : v;
    delete extra[`__null:${col.name}`];
  }
  for (const k of Object.keys(extra)) if (!k.startsWith('__')) doc[k] = extra[k];
  if (extra.createdAt !== undefined) doc.createdAt = extra.createdAt;
  return doc;
}

/** Collections ordered parents-first (for inserts); reverse for deletes. */
function order() {
  const names = Object.keys(spec);
  const deps = Object.fromEntries(names.map((n) => [n, new Set(Object.values(spec[n].fk || {}).map((f) => f[0]))]));
  const out = [];
  const seen = new Set();
  const visit = (n, path = []) => {
    if (seen.has(n)) return;
    if (path.includes(n)) throw new Error(`FK cycle: ${[...path, n].join(' -> ')}`);
    for (const d of deps[n]) visit(d, [...path, n]);
    seen.add(n); out.push(n);
  };
  names.forEach((n) => visit(n));
  return out;
}

/**
 * Make a row safe to write given what's in memory: a nullable FK pointing at a missing parent is nulled;
 * a required FK pointing at a missing parent means the row is an orphan and is skipped (null returned).
 */
function resolveFks(c, row, exists) {
  for (const [f, [parent, nullable]] of Object.entries(spec[c].fk || {})) {
    const v = row[f];
    if (v === null || v === undefined) { if (!nullable) return null; continue; }
    if (!exists(parent, v)) { if (nullable) row[f] = null; else return null; }
  }
  return row;
}

module.exports = { spec, model, delegate, columns, toRow, fromRow, order, resolveFks, setDbNull };
