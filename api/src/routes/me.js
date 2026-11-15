const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { conflict, validation } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { myBadges } = require('../utils/activity');
const S = require('../utils/serialize');
const { prefsOf, CATEGORY } = require('../utils/notify');
const { activeSuspension, suspensionEnd } = require('../utils/sanctions');

router.get('/', (req, res) => res.json(S.myProfile(req.user)));

router.patch('/', (req, res, next) => {
  try {
    const b = check(req.body, {
      full_name: { type: 'string', min: 2, max: 100 },
      photo_media_id: { type: 'string' },
      country: { type: 'string', enum: ['UG', 'KE', 'RW'] },
      phone: { type: 'string', pattern: /^\+?[0-9 -]{9,16}$/ },
      email: { type: 'string', email: true },
      institution_id: { type: 'string' },
    });
    const u = req.user;
    if (b.email) {
      const email = b.email.trim().toLowerCase();
      if (store.first('users', (x) => x.email === email && x.id !== u.id)) throw conflict('email_taken', 'Email is already registered');
      if (email !== u.email) { u.email = email; u.emailVerified = false; }
    }
    if (b.phone) {
      const phone = b.phone.replace(/[\s-]/g, '');
      if (store.first('users', (x) => x.phone === phone && x.id !== u.id)) throw conflict('phone_taken', 'Phone is already registered');
      if (phone !== u.phone) { u.phone = phone; u.phoneVerified = false; }
    }
    if (b.institution_id) {
      if (!store.get('institutions', b.institution_id)) throw validation([{ field: 'institution_id', message: 'unknown institution' }]);
      u.institutionId = b.institution_id;
    }
    if (b.photo_media_id !== undefined) {
      const m = store.get('media', b.photo_media_id);
      if (b.photo_media_id && (!m || m.ownerId !== u.id)) throw validation([{ field: 'photo_media_id', message: 'unknown photo' }]);
      u.photoMediaId = b.photo_media_id || null;
    }
    if (b.full_name) u.fullName = b.full_name.trim();
    if (b.country) u.country = b.country;
    res.json(S.myProfile(u));
  } catch (e) { next(e); }
});

const guardianOut = (u) => (u.guardian ? {
  name: u.guardian.name, relationship: u.guardian.relationship || null,
  email: u.guardian.email || null, phone: u.guardian.phone || null,
  status: u.minorStatus === 'minor_consented' ? 'confirmed' : 'pending',
} : null);

router.get('/guardian', (req, res) => res.json({ guardian: guardianOut(req.user) }));

// Minors record who their guardian is (the app asks after sign-up). Consent itself is confirmed by staff.
router.put('/guardian', (req, res, next) => {
  try {
    const u = req.user;
    if (u.minorStatus === 'adult') throw validation([{ field: 'guardian', message: 'only applies to users under 18' }]);
    const b = check(req.body, {
      name: { required: true, type: 'string', min: 2, max: 100 },
      relationship: { type: 'string', max: 40 },
      email: { type: 'string', email: true },
      phone: { type: 'string', pattern: /^\+?[0-9 -]{9,16}$/ },
    });
    if (!b.email && !b.phone) throw validation([{ field: 'email', message: 'a guardian email or phone is required' }]);
    if (b.email && u.email && b.email.trim().toLowerCase() === u.email) throw validation([{ field: 'email', message: "use your guardian's email, not your own" }]);
    u.guardian = { name: b.name.trim(), relationship: b.relationship || '', email: b.email ? b.email.trim().toLowerCase() : undefined, phone: b.phone };
    res.json({ guardian: guardianOut(u) });
  } catch (e) { next(e); }
});

router.delete('/', (req, res) => {
  // Right to delete (BRD s.7): soft-delete now; a retention job should purge after the grace period.
  req.user.deletedAt = store.now();
  store.insert('dataRequests', { userId: req.user.id, type: 'DELETION', requestedAt: req.user.deletedAt, status: 'OPEN' });
  store.remove('refreshTokens', (t) => t.userId === req.user.id);
  res.status(202).json({ status: 'scheduled', scheduled_at: req.user.deletedAt });
});

router.post('/export', (req, res) => {
  store.insert('dataRequests', { userId: req.user.id, type: 'EXPORT', requestedAt: store.now(), status: 'OPEN' });
  store.insert('events', { userId: req.user.id, type: 'data_export_requested', label: 'Requested data export', internal: true });
  res.status(202).json({ status: 'queued' });
});

router.get('/communities', (req, res) => {
  const mine = store.where('memberships', (m) => m.userId === req.user.id);
  const dto = (m) => ({
    community: S.communitySummary(store.get('communities', m.communityId), req.user.id),
    membership_status: m.status === 'member' ? 'member' : 'pending',
    joined_at: m.joinedAt || null,
    // While pending, which request it is (so the app can cancel it without a second call)
    join_request_id: m.status === 'member' ? null
      : ((store.first('joinRequests', (j) => j.userId === req.user.id && j.communityId === m.communityId && j.status === 'pending') || {}).id || null),
  });
  const find = (type) => mine.find((m) => store.get('communities', m.communityId)?.type === type);
  const g = find('general');
  const s = find('specific');
  res.json({ general: g ? dto(g) : null, specific: s ? dto(s) : null });
});

router.get('/join-requests', (req, res) => {
  const items = store.where('joinRequests', (j) => j.userId === req.user.id).sort(byNewest);
  res.json({ items: items.map((j) => require('./communities').joinRequestDto(j, req.user.id)) });
});

const notificationDto = (n) => ({
  id: n.id, type: n.type, title: n.title, body: n.body || null, target_route: n.targetRoute,
  read_at: n.readAt || null, created_at: n.createdAt,
});

router.get('/notifications', (req, res) => {
  const items = store.where('notifications', (n) => n.userId === req.user.id).sort(byNewest);
  const page = paginate(items, req.query);
  res.json({ unread_count: items.filter((n) => !n.readAt).length, items: page.items.map(notificationDto), next_cursor: page.next_cursor });
});

router.post('/notifications/read-all', (req, res) => {
  const t = store.now();
  store.where('notifications', (n) => n.userId === req.user.id && !n.readAt).forEach((n) => { n.readAt = t; });
  res.status(204).end();
});

router.post('/notifications/:id/read', (req, res, next) => {
  const n = store.get('notifications', req.params.id);
  if (!n || n.userId !== req.user.id) return next(require('../utils/errors').notFound('Notification'));
  if (!n.readAt) n.readAt = store.now();
  res.status(204).end();
});

router.get('/notification-preferences', (req, res) => res.json(prefsOf(req.user.id)));

router.put('/notification-preferences', (req, res, next) => {
  try {
    const b = check(req.body, { channels: { required: true, type: 'array' }, muted: { required: true, type: 'array' } });
    const categories = new Set(Object.values(CATEGORY).filter(Boolean));
    const bad = [];
    if (!b.channels.every((c) => ['inApp', 'email'].includes(c))) bad.push({ field: 'channels', message: 'must be inApp and/or email' });
    if (!b.muted.every((c) => categories.has(c))) bad.push({ field: 'muted', message: 'unknown category' });
    if (bad.length) throw validation(bad);
    let rec = store.first('notificationPrefs', (p) => p.userId === req.user.id);
    if (!rec) rec = store.insert('notificationPrefs', { userId: req.user.id, channels: [], muted: [] });
    rec.channels = [...new Set(b.channels)];
    rec.muted = [...new Set(b.muted)];
    res.json(prefsOf(req.user.id));
  } catch (e) { next(e); }
});

// Warnings a moderator or the FCU team sent me.
const warningDto = (s) => ({
  id: s.id, reason: s.reason || '', preview: s.preview || '', created_at: s.issuedAt, acknowledged: !!s.acknowledgedAt,
});
router.get('/warnings', (req, res) => {
  const items = store.where('sanctions', (s) => s.userId === req.user.id && s.type === 'WARNING').sort((a, b) => (a.issuedAt < b.issuedAt ? 1 : -1));
  res.json({ items: items.map(warningDto) });
});
router.post('/warnings/:id/acknowledge', (req, res, next) => {
  const s = store.get('sanctions', req.params.id);
  if (!s || s.userId !== req.user.id || s.type !== 'WARNING') return next(require('../utils/errors').notFound('Warning'));
  if (!s.acknowledgedAt) s.acknowledgedAt = store.now();
  res.json(warningDto(s));
});

// My current suspension, if any (ends by itself).
router.get('/suspension', (req, res) => {
  const s = activeSuspension(req.user);
  res.json({ suspension: s ? { reason: s.reason || '', until: suspensionEnd(s) } : null });
});

router.get('/activity', (req, res) => {
  const events = store.where('events', (e) => e.userId === req.user.id && !e.internal).sort(byNewest);
  const page = paginate(events, req.query);
  res.json({
    badges: myBadges(req.user.id),
    recent: {
      items: page.items.map((e) => ({ id: e.id, type: e.type, label: e.label, occurred_at: e.createdAt })),
      next_cursor: page.next_cursor,
    },
  });
});

module.exports = router;
