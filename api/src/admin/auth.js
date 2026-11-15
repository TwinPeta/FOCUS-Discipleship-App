const router = require('express').Router();
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const config = require('../config');
const store = require('../db/store');
const { check } = require('../utils/validate');
const { unauthorized, forbidden, validation, notFound } = require('../utils/errors');
const { rateLimit } = require('../middleware/rateLimit');
const C = require('./core');
const mailer = require('../services/mailer');

const strong = (p) => typeof p === 'string' && p.length >= 8 && /[A-Za-z]/.test(p) && /\d/.test(p);

function sessionUser(u) {
  const role = C.roleOf(u);
  const scope = C.scopeOf(u);
  const c = scope && scope[0] ? store.get('communities', scope[0]) : null;
  return {
    id: u.id, email: u.email, fullName: u.fullName, avatarUrl: u.photoUrl || null, role, status: C.statusOf(u),
    communityId: c ? c.id : null, communityIds: scope || undefined, communityName: c ? c.name : null,
  };
}
C.sessionUser = sessionUser;

function setCookies(res, u, remember) {
  const secure = config.env === 'production';
  const base = { httpOnly: true, sameSite: 'lax', secure, path: '/' };
  const access = C.sign(u, remember ? '7d' : '12h') // the back office has no refresh call, so a staff token must outlast a working session;
  const rt = crypto.randomBytes(32).toString('hex');
  store.insert('refreshTokens', { userId: u.id, tokenHash: crypto.createHash('sha256').update(rt).digest('hex'), admin: true, expiresAt: Date.now() + 30 * 864e5 });
  res.cookie(C.COOKIES.refresh, rt, { ...base, maxAge: 30 * 864e5 });
  // Access cookie goes LAST: the back office's Next.js proxy forwards only one Set-Cookie header (the last), and the access token is what it needs.
  res.cookie(C.COOKIES.access, access, { ...base, maxAge: remember ? 7 * 864e5 : undefined });
  return access;
}

router.post('/login', rateLimit({ windowMs: 900000, max: 20, key: (r) => r.body && r.body.email }), (req, res, next) => {
  try {
    const b = check(req.body, { email: { required: true, type: 'string' }, password: { required: true, type: 'string' } });
    const id = b.email.trim().toLowerCase();
    const u = store.first('users', (x) => !x.deletedAt && (x.email === id || x.username === id));
    if (!u || !bcrypt.compareSync(b.password, u.passwordHash)) throw unauthorized('Invalid credentials');
    if (u.suspended) throw forbidden('ACCOUNT_SUSPENDED', 'Account suspended');
    if (!C.STAFF.includes(C.roleOf(u))) throw forbidden('not_staff', 'This account has no back-office access');
    u.lastLoginAt = store.now();
    const token = setCookies(res, u, b.rememberMe === true);
    const ua = String(req.headers['user-agent'] || '');
    store.insert('staffSessions', {
      userId: u.id, token: token.slice(-16), deviceName: /Mobile/.test(ua) ? 'Mobile browser' : 'Desktop browser',
      browser: (ua.match(/(Edg|Chrome|Firefox|Safari)/) || [])[1] || 'Unknown', os: (ua.match(/(Windows|Mac OS X|Linux|Android|iPhone)/) || [])[1] || 'Unknown',
      ipAddress: req.ip, lastActiveAt: store.now(),
    });
    res.json({ user: sessionUser(u) });
  } catch (e) { next(e); }
});

router.post('/logout', (_req, res) => {
  res.clearCookie(C.COOKIES.access, { path: '/' });
  res.clearCookie(C.COOKIES.refresh, { path: '/' });
  res.json({ ok: true });
});

router.post('/forgot-password', rateLimit({ windowMs: 3600000, max: 10 }), (req, res, next) => {
  try {
    const b = check(req.body, { email: { required: true, type: 'string', email: true } });
    const u = store.first('users', (x) => x.email === b.email.trim().toLowerCase());
    if (u && C.STAFF.includes(C.roleOf(u))) {
      const token = crypto.randomBytes(24).toString('hex');
      store.insert('resetTokens', { userId: u.id, token, expiresAt: Date.now() + 3600e3, used: false });
      mailer.notify(u.email, 'staffReset', { name: u.fullName, link: `${config.backofficeUrl}/reset-password?token=${token}` });
    }
    res.json({ ok: true }); // never reveal whether the account exists
  } catch (e) { next(e); }
});

router.post('/reset-password', (req, res, next) => {
  try {
    const b = check(req.body, { token: { required: true, type: 'string' }, password: { required: true, type: 'string' } });
    const t = store.first('resetTokens', (x) => x.token === b.token);
    if (!t || t.used || t.expiresAt < Date.now()) throw new (require('../utils/errors').ApiError)(410, 'LINK_EXPIRED', 'Link expired', 'This reset link is invalid, expired or already used');
    if (!strong(b.password)) throw validation([{ field: 'password', message: 'min 8 characters with a letter and a number' }]);
    const u = store.get('users', t.userId);
    u.passwordHash = bcrypt.hashSync(b.password, 10);
    t.used = true;
    store.remove('refreshTokens', (r) => r.userId === u.id);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

// Authenticated
router.get('/me', C.adminAuth, (req, res) => res.json({ user: sessionUser(req.user) }));

module.exports = { router, sessionUser, strong };
