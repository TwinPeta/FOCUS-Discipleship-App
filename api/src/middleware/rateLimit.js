const { ApiError } = require('../utils/errors');

// Minimal fixed-window limiter keyed by IP (+ optional extra key). Replace with Redis-backed in production.
function rateLimit({ windowMs, max, key = () => '' }) {
  const hits = new Map();
  return (req, _res, next) => {
    if (process.env.NODE_ENV === 'test') return next();
    const k = `${req.ip}|${key(req)}`;
    const t = Date.now();
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
