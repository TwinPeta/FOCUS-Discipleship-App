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
