const router = require('express').Router();
const mailer = require('../services/mailer');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const config = require('../config');
const store = require('../db/store');
const { check } = require('../utils/validate');
const { conflict, unauthorized, badRequest, validation } = require('../utils/errors');
const { rateLimit } = require('../middleware/rateLimit');
const { authenticate } = require('../middleware/auth');
const S = require('../utils/serialize');

const sha = (s) => crypto.createHash('sha256').update(s).digest('hex');
const normPhone = (p) => (p ? p.replace(/[\s-]/g, '') : p);
const normEmail = (e) => (e ? e.trim().toLowerCase() : e);

function ageOf(birthdate) {
  const b = new Date(birthdate);
  const t = new Date();
  let age = t.getFullYear() - b.getFullYear();
  if (t < new Date(t.getFullYear(), b.getMonth(), b.getDate())) age -= 1;
  return age;
}

function issueTokens(user) {
  const access = jwt.sign({ sub: user.id }, config.jwtSecret, { expiresIn: config.accessTtl });
  const refresh = crypto.randomBytes(48).toString('base64url');
  store.insert('refreshTokens', {
    userId: user.id, hash: sha(refresh),
    expiresAt: Date.now() + config.refreshTtlDays * 86400000,
  });
  return { access_token: access, refresh_token: refresh, expires_in: config.accessTtlSeconds };
}

const SP = require('../utils/studentProfile');

const session = (user) => ({ ...issueTokens(user), user: S.myProfile(user) });

router.get('/username-available', (req, res, next) => {
  try {
    check(req.query, { username: { required: true, type: 'string', pattern: /^[a-z0-9_.]{3,30}$/ } });
    const taken = store.first('users', (u) => u.username === req.query.username.toLowerCase());
    res.json({ available: !taken });
  } catch (e) { next(e); }
});

router.post('/register', rateLimit({ windowMs: 3600000, max: 20 }), (req, res, next) => {
  try {
    const b = check(req.body, {
      full_name: { required: true, type: 'string', min: 2, max: 100 },
      username: { required: true, type: 'string', pattern: /^[a-z0-9_.]{3,30}$/i, patternMessage: '3-30 letters, numbers, . or _' },
      birthdate: { required: true, type: 'string', pattern: /^\d{4}-\d{2}-\d{2}$/, patternMessage: 'must be YYYY-MM-DD' },
      country: { required: true, type: 'string', enum: ['UG', 'KE', 'RW'] },
      email: { type: 'string', email: true },
      phone: { type: 'string', pattern: /^\+?[0-9 -]{9,16}$/ },
      institution_type: { required: true, type: 'string', enum: SP.INSTITUTION_TYPES },
      institution_id: { type: 'string' },
      // An institute that is not in the list: its name (institute students only).
      institution_name: { type: 'string', min: 2, max: 120 },
      year_of_study: { type: 'number' },
      accepted_national_activities: { required: true, type: 'boolean' },
      password: { required: true, type: 'string', min: 8, max: 128 },
      accepted_terms: { required: true, type: 'boolean' },
      accepted_code_of_conduct: { required: true, type: 'boolean' },
    });
    const errs = [];
    if (!b.email && !b.phone) errs.push({ field: 'email', message: 'email or phone is required' });
    if (b.accepted_terms !== true) errs.push({ field: 'accepted_terms', message: 'must be accepted' });
    if (b.accepted_code_of_conduct !== true) errs.push({ field: 'accepted_code_of_conduct', message: 'must be accepted' });
    if (b.accepted_national_activities !== true) errs.push({ field: 'accepted_national_activities', message: 'must be accepted' });
    const homeChurch = SP.homeChurchInput(b.home_church, errs);
    const yearOfStudy = SP.yearOfStudyInput(b.year_of_study, b.institution_type, errs);
    if (Number.isNaN(new Date(b.birthdate).getTime()) || new Date(b.birthdate) > new Date())
      errs.push({ field: 'birthdate', message: 'is not a valid date' });
    let inst = null;
    if (b.institution_id) {
      inst = store.get('institutions', b.institution_id);
      if (!inst || inst.type !== b.institution_type) errs.push({ field: 'institution_id', message: 'unknown institution' });
    } else if (!(b.institution_type === 'institute' && b.institution_name)) {
      errs.push({ field: 'institution_id', message: 'is required' });
    }
    const isMinor = !errs.length && ageOf(b.birthdate) < 18;
    // Guardian details may be sent now or later via PUT /me/guardian; until consent the account stays restricted.
    if (isMinor && b.guardian && !(b.guardian.name && (b.guardian.phone || b.guardian.email)))
      errs.push({ field: 'guardian', message: 'guardian name and a phone or email are required' });
    if (b.photo_media_id && store.get('media', b.photo_media_id)?.purpose !== 'profile_photo')
      errs.push({ field: 'photo_media_id', message: 'unknown photo' });
    if (errs.length) throw validation(errs);

    const username = b.username.toLowerCase();
    const email = normEmail(b.email);
    const phone = normPhone(b.phone);
    if (store.first('users', (u) => u.username === username)) throw conflict('username_taken', 'Username is taken');
    if (email && store.first('users', (u) => u.email === email)) throw conflict('email_taken', 'Email is already registered');
    if (phone && store.first('users', (u) => u.phone === phone)) throw conflict('phone_taken', 'Phone is already registered');
    if (!inst) inst = SP.findOrAddInstitute(b.institution_name, b.country);

    const user = store.insert('users', {
      fullName: b.full_name.trim(), username, email, phone, birthdate: b.birthdate, country: b.country,
      institutionId: inst.id, passwordHash: bcrypt.hashSync(b.password, 10),
      photoMediaId: b.photo_media_id || null, platformRole: 'student',
      emailVerified: false, phoneVerified: false, verifiedMentor: false,
      minorStatus: isMinor ? 'pending_guardian_consent' : 'adult',
      guardian: isMinor ? (b.guardian || null) : null,
      consents: { terms: store.now(), codeOfConduct: store.now(), nationalActivities: store.now() },
      homeChurch: homeChurch || null, yearOfStudy,
    });

    // Every student is automatically in the General community of their institution.
    const general = store.first('communities', (c) => c.type === 'general' && c.institutionId === inst.id);
    if (general) {
      store.insert('memberships', { communityId: general.id, userId: user.id, role: 'member', status: 'member', joinedAt: store.now() });
    }
    res.status(201).json(session(user));
  } catch (e) { next(e); }
});

router.post('/login', rateLimit({ windowMs: 900000, max: 20, key: (r) => r.body && r.body.identifier }), (req, res, next) => {
  try {
    const b = check(req.body, { identifier: { required: true, type: 'string' }, password: { required: true, type: 'string' } });
    const id = b.identifier.trim().toLowerCase();
    const ph = normPhone(b.identifier.trim());
    const user = store.first('users', (u) => !u.deletedAt && (u.email === id || u.username === id.replace(/^@/, '') || u.phone === ph));
    if (!user || !bcrypt.compareSync(b.password, user.passwordHash)) throw unauthorized('Invalid credentials');
    require('../utils/sanctions').activeSuspension(user); // lifts a suspension that has ended
    res.json(session(user));
  } catch (e) { next(e); }
});

// Per sender and, separately, per destination: nobody can flood one person's inbox by rotating addresses
router.post('/otp/request', rateLimit({ windowMs: 600000, max: 5, key: (r) => r.body && r.body.destination }), rateLimit({ windowMs: 3600000, max: 8, byAddress: false, key: (r) => r.body && r.body.destination }), (req, res, next) => {
  try {
    const b = check(req.body, {
      channel: { required: true, type: 'string', enum: ['sms', 'email'] },
      destination: { required: true, type: 'string' },
      purpose: { required: true, type: 'string', enum: ['login', 'verify_contact', 'password_reset'] },
    });
    const dest = b.channel === 'sms' ? normPhone(b.destination) : normEmail(b.destination);
    const code = String(crypto.randomInt(0, 1000000)).padStart(6, '0');
    store.remove('otps', (o) => o.destination === dest && o.purpose === b.purpose);
    store.insert('otps', { destination: dest, purpose: b.purpose, hash: sha(code), expiresAt: Date.now() + 600000, attempts: 0 });
    if (b.channel === 'email') mailer.notify(dest, 'otp', { code, purpose: b.purpose });
    else if (config.env !== 'production') console.log(`[otp] SMS gateway not integrated; ${b.purpose} code for ${dest}: ${code}`); // TODO: SMS provider
    res.status(202).end(); // always 202: no account enumeration
  } catch (e) { next(e); }
});

router.post('/otp/verify', rateLimit({ windowMs: 600000, max: 20 }), (req, res, next) => {
  try {
    const b = check(req.body, {
      destination: { required: true, type: 'string' },
      code: { required: true, type: 'string', pattern: /^[0-9]{6}$/ },
      purpose: { required: true, type: 'string', enum: ['login', 'verify_contact', 'password_reset'] },
    });
    const dests = [normPhone(b.destination), normEmail(b.destination)];
    const otp = store.first('otps', (o) => dests.includes(o.destination) && o.purpose === b.purpose);
    const fail = () => badRequest('otp_invalid', 'Invalid code', 'The code is invalid or expired');
    if (!otp || otp.expiresAt < Date.now() || otp.attempts >= 5) throw fail();
    if (otp.hash !== sha(b.code)) { otp.attempts += 1; throw fail(); }
    store.remove('otps', (o) => o.id === otp.id);

    const user = store.first('users', (u) => !u.deletedAt && (u.phone === otp.destination || u.email === otp.destination));
    if (b.purpose === 'login') {
      if (!user) throw fail();
      return res.json(session(user));
    }
    if (b.purpose === 'verify_contact' && user) {
      if (user.phone === otp.destination) user.phoneVerified = true; else user.emailVerified = true;
    }
    res.status(204).end();
  } catch (e) { next(e); }
});

// Forgot password: the emailed 6-digit code (purpose password_reset) and a new password. Signs the account out
// everywhere else. The same reply for an unknown email or a wrong code (no account enumeration).
router.post('/password/reset', rateLimit({ windowMs: 600000, max: 10 }), (req, res, next) => {
  try {
    const b = check(req.body, {
      destination: { required: true, type: 'string' },
      code: { required: true, type: 'string', pattern: /^[0-9]{6}$/ },
      password: { required: true, type: 'string', min: 8, max: 128 },
    });
    const dests = [normPhone(b.destination), normEmail(b.destination)];
    const otp = store.first('otps', (o) => dests.includes(o.destination) && o.purpose === 'password_reset');
    const fail = () => badRequest('otp_invalid', 'Invalid code', 'The code is invalid or expired');
    if (!otp || otp.expiresAt < Date.now() || otp.attempts >= 5) throw fail();
    if (otp.hash !== sha(b.code)) { otp.attempts += 1; throw fail(); }
    const user = store.first('users', (u) => !u.deletedAt && (u.phone === otp.destination || u.email === otp.destination));
    if (!user) throw fail();
    store.remove('otps', (o) => o.id === otp.id);
    user.passwordHash = bcrypt.hashSync(b.password, 10);
    store.remove('refreshTokens', (t) => t.userId === user.id);
    res.status(204).end();
  } catch (e) { next(e); }
});

router.post('/refresh', (req, res, next) => {
  try {
    const b = check(req.body, { refresh_token: { required: true, type: 'string' } });
    const rec = store.first('refreshTokens', (t) => t.hash === sha(b.refresh_token));
    if (!rec || rec.expiresAt < Date.now()) throw unauthorized('Invalid refresh token');
    store.remove('refreshTokens', (t) => t.id === rec.id); // rotate
    const user = store.get('users', rec.userId);
    if (!user || user.deletedAt) throw unauthorized();
    res.json(issueTokens(user));
  } catch (e) { next(e); }
});

router.post('/logout', authenticate, (req, res, next) => {
  try {
    const rt = req.body && req.body.refresh_token;
    if (rt) store.remove('refreshTokens', (t) => t.hash === sha(rt) && t.userId === req.user.id);
    else store.remove('refreshTokens', (t) => t.userId === req.user.id);
    res.status(204).end();
  } catch (e) { next(e); }
});

module.exports = router;
