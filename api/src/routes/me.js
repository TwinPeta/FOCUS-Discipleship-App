const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { conflict, validation } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { myBadges } = require('../utils/activity');
const S = require('../utils/serialize');

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
