const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, forbidden, validation } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { requireMember, isLeaderRole } = require('../middleware/auth');
const { idempotency } = require('../middleware/idempotency');
const { logEvent } = require('../utils/activity');
const S = require('../utils/serialize');
const { notify } = require('../utils/notify');

function ownedMedia(ids, userId) {
  for (const id of ids || []) {
    const m = store.get('media', id);
    if (!m || m.ownerId !== userId) throw validation([{ field: 'media_ids', message: `unknown media ${id}` }]);
  }
}

// Loads post + caller's membership in its community (404 for non-members to avoid leaking existence).
function loadPost(req, _res, next) {
  const post = store.get('posts', req.params.postId);
  const m = post && store.first('memberships', (x) => x.communityId === post.communityId && x.userId === req.user.id && x.status === 'member');
  if (!post || !m) return next(notFound('Post'));
  req.post = post;
  req.membership = m;
  next();
}

router.get('/communities/:communityId/posts', requireMember, (req, res) => {
  const hidden = (p) => p.hidden;
  const items = store.where('posts', (p) => p.communityId === req.community.id && !hidden(p))
    .sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0) || byNewest(a, b));
  const page = paginate(items, req.query);
  res.json({ items: page.items.map((p) => S.post(p, req.user.id)), next_cursor: page.next_cursor });
});

router.post('/communities/:communityId/posts', requireMember, idempotency, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 5000 }, media_ids: { type: 'array', maxItems: 4 } });
    ownedMedia(b.media_ids, req.user.id);
    const p = store.insert('posts', { communityId: req.community.id, authorId: req.user.id, text: b.text.trim(), mediaIds: b.media_ids || [], pinned: false });
    logEvent(req.user.id, 'post_created', 'Shared a post');
    res.status(201).json(S.post(p, req.user.id));
  } catch (e) { next(e); }
});

router.get('/posts/:postId', loadPost, (req, res) => res.json(S.post(req.post, req.user.id)));

router.patch('/posts/:postId', loadPost, (req, res, next) => {
  try {
    if (req.post.authorId !== req.user.id) throw forbidden('forbidden', 'You can only edit your own posts');
    const b = check(req.body, { text: { type: 'string', min: 1, max: 5000 } });
    if (b.text) req.post.text = b.text.trim();
    res.json(S.post(req.post, req.user.id));
  } catch (e) { next(e); }
});

router.delete('/posts/:postId', loadPost, (req, res, next) => {
  try {
    const own = req.post.authorId === req.user.id;
    if (!own && !isLeaderRole(req.membership.role)) throw forbidden();
    if (own) {
      store.remove('posts', (p) => p.id === req.post.id);
      store.remove('likes', (l) => l.postId === req.post.id);
      store.remove('comments', (c) => c.postId === req.post.id);
    } else {
      req.post.hidden = true; // first-level moderation: leaders hide, not destroy (audit trail)
      store.insert('events', { userId: req.user.id, type: 'moderation_hide_post', label: `Hid post ${req.post.id}`, internal: true });
    }
    res.status(204).end();
  } catch (e) { next(e); }
});

function reaction(postId, userId) {
  const likes = store.where('likes', (l) => l.postId === postId);
  return { like_count: likes.length, liked_by_me: likes.some((l) => l.userId === userId) };
}

router.put('/posts/:postId/like', loadPost, (req, res) => {
  if (!store.first('likes', (l) => l.postId === req.post.id && l.userId === req.user.id))
    store.insert('likes', { postId: req.post.id, userId: req.user.id });
  res.json(reaction(req.post.id, req.user.id));
});

router.delete('/posts/:postId/like', loadPost, (req, res) => {
  store.remove('likes', (l) => l.postId === req.post.id && l.userId === req.user.id);
  res.json(reaction(req.post.id, req.user.id));
});

router.get('/posts/:postId/comments', loadPost, (req, res) => {
  const items = store.where('comments', (c) => c.postId === req.post.id && !c.hidden).sort((a, b) => (a.createdAt < b.createdAt ? -1 : 1));
  const page = paginate(items, req.query);
  res.json({ items: page.items.map((c) => S.comment(c, req.post.communityId)), next_cursor: page.next_cursor });
});

router.post('/posts/:postId/comments', loadPost, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 2000 } });
    const c = store.insert('comments', { postId: req.post.id, authorId: req.user.id, text: b.text.trim() });
    if (req.post.authorId !== req.user.id) {
      notify(req.post.authorId, 'comment_reply', { title: `${req.user.fullName} commented on your post`, body: b.text.trim().slice(0, 140), targetRoute: `/post/${req.post.id}` });
    }
    res.status(201).json(S.comment(c, req.post.communityId));
  } catch (e) { next(e); }
});

module.exports = router;
