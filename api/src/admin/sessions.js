// Server-side sessions for the back office (staff). The browser holds only an opaque, random cookie; everything
// else (who, until when, from where, revoked or not) lives here, so the back office never decides anything and
// a session can be ended instantly from the server (logout, password change, suspension, "sign out other devices").
const crypto = require('crypto');
const config = require('../config');
const store = require('../db/store');

const COOKIE = process.env.AUTH_ACCESS_COOKIE || 'fcu_access';
const LEGACY_COOKIES = [process.env.AUTH_REFRESH_COOKIE || 'fcu_refresh']; // cleared on logout; no longer issued
const MIN = 60e3;
const HOUR = 3600e3;
const DAY = 864e5;
const MAX_PER_USER = 10; // a person with more devices than this loses the least recently used one
const TOUCH_EVERY = 5 * MIN; // how often activity is written (and a remembered cookie slid forward)

const hash = (t) => crypto.createHash('sha256').update(t).digest('hex');
const idleMs = (s) => (s.remember ? config.staffSession.rememberDays * DAY : config.staffSession.idleHours * HOUR);

function tokenFrom(req) {
  const m = new RegExp(`(?:^|;\\s*)${COOKIE}=([^;]+)`).exec(req.headers.cookie || '');
  if (m) return { token: decodeURIComponent(m[1]), viaCookie: true };
  const [scheme, bearer] = (req.headers.authorization || '').split(' ');
  return scheme === 'Bearer' && bearer ? { token: bearer, viaCookie: false } : { token: null };
}

const live = (s, now = Date.now()) =>
  !!s && (!s.expiresAt || s.expiresAt > now) && Date.parse(s.lastActiveAt || s.createdAt) + idleMs(s) > now;

function cookieOptions(s) {
  return {
    httpOnly: true, sameSite: 'lax', secure: config.env === 'production', path: '/',
    ...(s.remember ? { maxAge: idleMs(s) } : {}), // otherwise a browser-session cookie
  };
}
const setCookie = (res, token, s) => res.cookie(COOKIE, token, cookieOptions(s));
function clearCookies(res) {
  for (const name of [COOKIE, ...LEGACY_COOKIES]) res.clearCookie(name, { path: '/' });
}

function create(user, req, remember) {
  const token = crypto.randomBytes(32).toString('hex');
  const ua = String(req.headers['user-agent'] || '');
  purgeExpired(user.id);
  const open = active(user.id).sort((a, b) => (a.lastActiveAt < b.lastActiveAt ? -1 : 1));
  open.slice(0, Math.max(0, open.length - MAX_PER_USER + 1)).forEach((old) => revoke(old.id));
  const session = store.insert('staffSessions', {
    userId: user.id, tokenHash: hash(token), remember: !!remember, expiresAt: Date.now() + config.staffSession.maxDays * DAY,
    deviceName: /Mobile/.test(ua) ? 'Mobile browser' : 'Desktop browser',
    browser: (ua.match(/(Edg|Chrome|Firefox|Safari)/) || [])[1] || 'Unknown',
    os: (ua.match(/(Windows|Mac OS X|Linux|Android|iPhone)/) || [])[1] || 'Unknown',
    ipAddress: req.ip, lastActiveAt: store.now(),
  });
  return { token, session };
}

/** The live session for this request, or null. Never throws. */
function find(req) {
  const { token, viaCookie } = tokenFrom(req);
  if (!token) return null;
  const session = store.first('staffSessions', (s) => s.tokenHash === hash(token));
  return live(session) ? { session, token, viaCookie } : null;
}

/** Records activity (rate-limited). Returns true when it did, so the caller can slide the cookie. */
function touch(session) {
  if (Date.now() - Date.parse(session.lastActiveAt) < TOUCH_EVERY) return false;
  session.lastActiveAt = store.now();
  return true;
}

const revoke = (id) => store.remove('staffSessions', (s) => s.id === id);
/** Ends every session of a user (suspension, deletion, password reset), optionally keeping one. */
const revokeAll = (userId, exceptId) => store.remove('staffSessions', (s) => s.userId === userId && s.id !== exceptId);
const purgeExpired = (userId) => store.remove('staffSessions', (s) => s.userId === userId && !live(s));
/** Removes every expired session (all users). Called on a timer so abandoned sessions do not pile up. */
const sweep = () => store.remove('staffSessions', (s) => !live(s));
const active = (userId) => store.where('staffSessions', (s) => s.userId === userId && live(s));

module.exports = { COOKIE, MAX_PER_USER, create, find, touch, revoke, revokeAll, active, sweep, setCookie, clearCookies, tokenFrom };
