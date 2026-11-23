const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { idempotency } = require('../middleware/idempotency');
const { requireMember } = require('../middleware/auth');
const { logEvent, awardBadge } = require('../utils/activity');
const S = require('../utils/serialize');
const { notify } = require('../utils/notify');

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

router.post('/communities/:communityId/prayer-requests', requireMember, idempotency, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 2000 }, anonymous: { type: 'boolean' } });
    // authorId is stored so moderators can act on abuse, but is never serialized for anonymous requests.
    const r = store.insert('prayerRequests', { communityId: req.community.id, authorId: req.user.id, anonymous: !!b.anonymous, text: b.text.trim() });
    res.status(201).json(S.prayerRequest(r, req.user.id));
  } catch (e) { next(e); }
});

router.get('/prayer-requests/:prayerRequestId', loadRequest, (req, res) => res.json(S.prayerRequest(req.prayer, req.user.id)));

// An owner replying on their own anonymous request stays anonymous.
const responseDto = (c, prayer) => {
  const anonymous = !!prayer.anonymous && c.authorId === prayer.authorId;
  const dto = S.comment(c, prayer.communityId);
  return anonymous ? { ...dto, author: null, anonymous: true } : { ...dto, anonymous: false };
};

const prayedState = (id, userId) => {
  const rows = store.where('prayed', (p) => p.prayerRequestId === id);
  return { prayed_count: rows.length, prayed_by_me: rows.some((p) => p.userId === userId) };
};

router.put('/prayer-requests/:prayerRequestId/prayed', loadRequest, (req, res) => {
  if (!store.first('prayed', (p) => p.prayerRequestId === req.prayer.id && p.userId === req.user.id)) {
    store.insert('prayed', { prayerRequestId: req.prayer.id, userId: req.user.id });
    logEvent(req.user.id, 'prayed', 'Prayed for a request');
    // Never names the person who prayed, and the owner of an anonymous request is only ever addressed privately.
    if (req.prayer.authorId !== req.user.id) {
      notify(req.prayer.authorId, 'prayed_for_you', { title: 'Someone prayed for you', targetRoute: `/prayer/${req.prayer.id}`, vars: { community_name: (store.get('communities', req.prayer.communityId) || {}).name } });
    }
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
  res.json({ items: page.items.map((c) => responseDto(c, req.prayer)), next_cursor: page.next_cursor });
});

router.post('/prayer-requests/:prayerRequestId/responses', loadRequest, idempotency, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 2000 } });
    const c = store.insert('prayerResponses', { prayerRequestId: req.prayer.id, authorId: req.user.id, text: b.text.trim() });
    if (req.prayer.authorId !== req.user.id) {
      notify(req.prayer.authorId, 'prayer_response', { title: 'Someone responded to your prayer request', body: b.text.trim().slice(0, 140), targetRoute: `/prayer/${req.prayer.id}` });
    }
    res.status(201).json(responseDto(c, req.prayer));
  } catch (e) { next(e); }
});

module.exports = router;
