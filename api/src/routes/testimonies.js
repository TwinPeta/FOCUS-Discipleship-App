const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, validation } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { requireMember } = require('../middleware/auth');
const { logEvent } = require('../utils/activity');
const S = require('../utils/serialize');

// Visible: published ones, plus the author's own pending/rejected ones.
const visibleTo = (t, userId) => t.status === 'published' || t.authorId === userId;

router.get('/communities/:communityId/testimonies', requireMember, (req, res) => {
  const items = store.where('testimonies', (t) => t.communityId === req.community.id && visibleTo(t, req.user.id)).sort(byNewest);
  const page = paginate(items, req.query);
  res.json({
    has_my_pending: items.some((t) => t.authorId === req.user.id && t.status === 'pending_review'),
    items: page.items.map((t) => S.testimony(t, { viewerId: req.user.id })),
    next_cursor: page.next_cursor,
  });
});

router.post('/communities/:communityId/testimonies', requireMember, (req, res, next) => {
  try {
    const b = check(req.body, {
      title: { required: true, type: 'string', min: 1, max: 120 },
      body: { required: true, type: 'string', min: 1, max: 10000 },
      media_ids: { type: 'array', maxItems: 4 },
      consent: { required: true, type: 'boolean' },
    });
    if (b.consent !== true) throw validation([{ field: 'consent', message: 'You must agree to share your story' }]);
    for (const id of b.media_ids || []) {
      const m = store.get('media', id);
      if (!m || m.ownerId !== req.user.id) throw validation([{ field: 'media_ids', message: `unknown media ${id}` }]);
    }
    // Always moderated before publication (BRD s.8.1).
    const t = store.insert('testimonies', {
      communityId: req.community.id, authorId: req.user.id, title: b.title.trim(), body: b.body.trim(),
      mediaIds: b.media_ids || [], status: 'pending_review', approvedBy: null, publishedAt: null,
    });
    logEvent(req.user.id, 'testimony_submitted', 'Submitted a testimony for review');
    res.status(201).json(S.testimony(t, { detail: true, viewerId: req.user.id }));
  } catch (e) { next(e); }
});

// A testimony the caller may see: a member of its community, and published (or their own).
function loadTestimony(req, _res, next) {
  const t = store.get('testimonies', req.params.testimonyId);
  const member = t && store.first('memberships', (m) => m.communityId === t.communityId && m.userId === req.user.id && m.status === 'member');
  if (!t || !member || !visibleTo(t, req.user.id)) return next(notFound('Testimony'));
  req.testimony = t;
  next();
}

router.get('/testimonies/:testimonyId', loadTestimony, (req, res) => {
  res.json(S.testimony(req.testimony, { detail: true, viewerId: req.user.id }));
});

// "Encouraged": one reaction per member, on published stories only.
function setEncouraged(on) {
  return (req, res, next) => {
    if (req.testimony.status !== 'published') return next(validation([{ field: 'testimonyId', message: 'only published stories can be encouraged' }]));
    const mine = (e) => e.testimonyId === req.testimony.id && e.userId === req.user.id;
    if (on && !store.first('testimonyEncouragements', mine)) store.insert('testimonyEncouragements', { testimonyId: req.testimony.id, userId: req.user.id });
    if (!on) store.remove('testimonyEncouragements', mine);
    res.json(S.encouragedState(req.testimony.id, req.user.id));
  };
}
router.put('/testimonies/:testimonyId/encourage', loadTestimony, setEncouraged(true));
router.delete('/testimonies/:testimonyId/encourage', loadTestimony, setEncouraged(false));

module.exports = router;
