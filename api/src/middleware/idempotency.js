// Replays the stored response when the same Idempotency-Key is re-sent by the same user+route.
const cache = new Map();
const TTL = 24 * 60 * 60 * 1000;

function idempotency(req, res, next) {
  const key = req.get('Idempotency-Key');
  if (!key || !req.user) return next();
  const k = `${req.user.id}|${req.method}|${req.originalUrl}|${key}`;
  const hit = cache.get(k);
  if (hit && hit.exp > Date.now()) {
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
