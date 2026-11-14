// Cursor pagination over an in-memory array. Cursor = base64url(offset).
function paginate(items, query) {
  const limit = Math.min(Math.max(parseInt(query.limit, 10) || 20, 1), 100);
  let offset = 0;
  if (query.cursor) {
    const n = parseInt(Buffer.from(String(query.cursor), 'base64url').toString(), 10);
    if (Number.isFinite(n) && n >= 0) offset = n;
  }
  const slice = items.slice(offset, offset + limit);
  const next = offset + limit < items.length ? Buffer.from(String(offset + limit)).toString('base64url') : null;
  return { items: slice, next_cursor: next };
}

const byNewest = (a, b) => (a.createdAt < b.createdAt ? 1 : -1);

module.exports = { paginate, byNewest };
