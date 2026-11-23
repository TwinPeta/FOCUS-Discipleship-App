// Replays the stored response when the same Idempotency-Key is re-sent by the same user+route.
const cache = new Map();
const TTL = 24 * 60 * 60 * 1000;

// Expired entries are only replaced when the same key comes back, so sweep
// them now and then to keep the server's memory flat.
const SWEEP_AT = 1000;
let lastSweep = 0;
function sweep(now) {
  if (cache.size < SWEEP_AT || now - lastSweep < 60 * 1000) return;
  lastSweep = now;
  for (const [k, v] of cache) if (v.exp <= now) cache.delete(k);
}

function idempotency(req, res, next) {
  const key = req.get('Idempotency-Key');
  if (!key || !req.user) return next();
  const k = `${req.user.id}|${req.method}|${req.originalUrl}|${key}`;
  const now = Date.now();
  sweep(now);
  const hit = cache.get(k);
  if (hit && hit.exp > now) {
    res.set('Idempotent-Replay', 'true');
    return res.status(hit.status).json(hit.body);
  }
  const json = res.json.bind(res);
  res.json = (body) => {
    if (res.statusCode < 500) cache.set(k, { status: res.statusCode, body, exp: Date.now() + TTL });
    return json(body);
  };
  next();
}

module.exports = { idempotency };
