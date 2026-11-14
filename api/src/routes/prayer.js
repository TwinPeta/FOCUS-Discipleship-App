const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { requireMember } = require('../middleware/auth');
const { logEvent, awardBadge } = require('../utils/activity');
const S = require('../utils/serialize');

function loadRequest(req, _res, next) {
  const r = store.get('prayerRequests', req.params.prayerRequestId);
  const m = r && store.first('memberships', (x) => x.communityId === r.communityId && x.userId === req.user.id && x.status === 'member');
  if (!r || !m) return next(notFound('Prayer request'));
  req.prayer = r;
  next();
}

router.get('/communities/:communityId/prayer-requests', requireMember, (req, res) => {
  const items = store.where('prayerRequests', (r) => r.communityId === req.community.id && !r.hidden).sort(byNewest);
  const page = paginate(items, req.query);
  res.json({ items: page.items.map((r) => S.prayerRequest(r, req.user.id)), next_cursor: page.next_cursor });
});

router.post('/communities/:communityId/prayer-requests', requireMember, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 2000 }, anonymous: { type: 'boolean' } });
    // authorId is stored so moderators can act on abuse, but is never serialized for anonymous requests.
    const r = store.insert('prayerRequests', { communityId: req.community.id, authorId: req.user.id, anonymous: !!b.anonymous, text: b.text.trim() });
    res.status(201).json(S.prayerRequest(r, req.user.id));
  } catch (e) { next(e); }
});

const prayedState = (id, userId) => {
  const rows = store.where('prayed', (p) => p.prayerRequestId === id);
  return { prayed_count: rows.length, prayed_by_me: rows.some((p) => p.userId === userId) };
};

router.put('/prayer-requests/:prayerRequestId/prayed', loadRequest, (req, res) => {
  if (!store.first('prayed', (p) => p.prayerRequestId === req.prayer.id && p.userId === req.user.id)) {
    store.insert('prayed', { prayerRequestId: req.prayer.id, userId: req.user.id });
    logEvent(req.user.id, 'prayed', 'Prayed for a request');
    if (store.where('prayed', (p) => p.userId === req.user.id).length >= 1) awardBadge(req.user.id, 'prayer_partner');
  }
  res.json(prayedState(req.prayer.id, req.user.id));
});

router.delete('/prayer-requests/:prayerRequestId/prayed', loadRequest, (req, res) => {
  store.remove('prayed', (p) => p.prayerRequestId === req.prayer.id && p.userId === req.user.id);
  res.json(prayedState(req.prayer.id, req.user.id));
});

router.get('/prayer-requests/:prayerRequestId/responses', loadRequest, (req, res) => {
  const items = store.where('prayerResponses', (x) => x.prayerRequestId === req.prayer.id && !x.hidden)
    .sort((a, b) => (a.createdAt < b.createdAt ? -1 : 1));
  const page = paginate(items, req.query);
  res.json({ items: page.items.map((c) => S.comment(c, req.prayer.communityId)), next_cursor: page.next_cursor });
});

router.post('/prayer-requests/:prayerRequestId/responses', loadRequest, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 2000 } });
    const c = store.insert('prayerResponses', { prayerRequestId: req.prayer.id, authorId: req.user.id, text: b.text.trim() });
    res.status(201).json(S.comment(c, req.prayer.communityId));
  } catch (e) { next(e); }
});

module.exports = router;
