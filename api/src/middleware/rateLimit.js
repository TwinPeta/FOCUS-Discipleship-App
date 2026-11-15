const { ApiError } = require('../utils/errors');

// Minimal fixed-window limiter keyed by IP (+ optional extra key), or by the key alone with byAddress:false. Replace with Redis-backed in production.
function rateLimit({ windowMs, max, key = () => '', byAddress = true }) {
  const hits = new Map();
  return (req, _res, next) => {
    if (process.env.NODE_ENV === 'test') return next();
    const k = byAddress ? `${req.ip}|${key(req)}` : `|${key(req)}`; // byAddress:false counts everyone together (e.g. one victim's inbox)
    const t = Date.now();
    if (hits.size > 5000) for (const [key2, r] of hits) if (r.reset < t) hits.delete(key2); // do not grow without bound
    const rec = hits.get(k);
    if (!rec || rec.reset < t) {
      hits.set(k, { count: 1, reset: t + windowMs });
      return next();
    }
    rec.count += 1;
    if (rec.count > max) {
      const e = new ApiError(429, 'rate_limited', 'Too many requests', 'Please slow down and retry later');
      e.retryAfter = Math.ceil((rec.reset - t) / 1000);
      return next(e);
    }
    next();
  };
}

module.exports = { rateLimit };
