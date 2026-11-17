const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, validation } = require('../utils/errors');
const { idempotency } = require('../middleware/idempotency');
const S = require('../utils/serialize');

const TARGETS = { user: 'users', message: 'messages', post: 'posts', comment: 'comments', testimony: 'testimonies', prayer_request: 'prayerRequests' };
const REASONS = ['harassment_bullying', 'offensive_content', 'breaks_community_rules', 'spam_or_fake_profile', 'other'];

router.post('/reports', idempotency, (req, res, next) => {
  try {
    const b = check(req.body, {
      target_type: { required: true, type: 'string', enum: Object.keys(TARGETS) },
      target_id: { required: true, type: 'string' },
      reason: { required: true, type: 'string', enum: REASONS },
      details: { type: 'string', max: 2000 },
      evidence_media_id: { type: 'string' },
    });
    // Nothing empty: "other" says nothing on its own, so it needs details.
    b.details = typeof b.details === 'string' ? b.details.trim() : undefined;
    if (b.reason === 'other' && !b.details) throw validation([{ field: 'details', message: 'tell us what happened' }]);
    if (!store.get(TARGETS[b.target_type], b.target_id)) throw notFound('Report target');
    if (b.target_type === 'user' && b.target_id === req.user.id) throw validation([{ field: 'target_id', message: 'cannot report yourself' }]);
    if (b.evidence_media_id) {
      const m = store.get('media', b.evidence_media_id);
      if (!m || m.ownerId !== req.user.id || m.purpose !== 'report_evidence')
        throw validation([{ field: 'evidence_media_id', message: 'unknown evidence file' }]);
    }
    const r = store.insert('reports', {
      reporterId: req.user.id, targetType: b.target_type, targetId: b.target_id, reason: b.reason,
      details: b.details || '', evidenceMediaId: b.evidence_media_id || null, status: 'open',
    });
    // Tell the people who review reports for that community (staff have no in-app inbox, so by email)
    try {
      const target = store.get(TARGETS[b.target_type], b.target_id) || {};
      const cid = target.communityId || (store.get('posts', target.postId) || {}).communityId
        || ((store.where('memberships', (m) => m.userId === b.target_id && m.status === 'member' && (store.get('communities', m.communityId) || {}).type === 'specific')[0] || {}).communityId);
      const leaders = cid ? store.where('memberships', (m) => m.communityId === cid && m.role === 'super_mentor' && m.status === 'member').map((m) => m.userId) : [];
      require('../utils/notify').emailStaff(leaders.filter((id) => id !== req.user.id), 'report_received', {
        community_name: (store.get('communities', cid) || {}).name || 'the community', item_title: b.reason.replace(/_/g, ' '),
      });
    } catch (_e) { /* a report must never fail because of a notification */ }
    res.status(201).json({ id: r.id, status: 'open' });
  } catch (e) { next(e); }
});

// The people I have blocked (so the app can show and undo them).
router.get('/me/blocks', (req, res) => {
  const items = store.where('blocks', (x) => x.blockerId === req.user.id)
    .map((x) => S.userRef(store.get('users', x.blockedId))).filter(Boolean);
  res.json({ items });
});

router.put('/users/:userId/block', (req, res, next) => {
  try {
    if (!store.get('users', req.params.userId)) throw notFound('User');
    if (req.params.userId === req.user.id) throw validation([{ field: 'userId', message: 'cannot block yourself' }]);
    if (!store.first('blocks', (x) => x.blockerId === req.user.id && x.blockedId === req.params.userId))
      store.insert('blocks', { blockerId: req.user.id, blockedId: req.params.userId });
    res.status(204).end();
  } catch (e) { next(e); }
});

router.delete('/users/:userId/block', (req, res) => {
  store.remove('blocks', (x) => x.blockerId === req.user.id && x.blockedId === req.params.userId);
  res.status(204).end();
});

module.exports = router;
