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

/** Posts this person hid from their own feed ("Hide this post"). */
const hiddenByMe = (userId) => new Set(store.where('postMarks', (m) => m.userId === userId && m.kind === 'hidden').map((m) => m.postId));

router.get('/communities/:communityId/posts', requireMember, (req, res) => {
  const mine = hiddenByMe(req.user.id);
  const hidden = (p) => p.hidden || mine.has(p.id);
  const kind = req.query.kind; // 'question': the questions only (Answer a question)
  const items = store.where('posts', (p) => p.communityId === req.community.id && !hidden(p) && (!kind || (p.kind || 'post') === kind))
    .sort((a, b) => (b.pinned ? 1 : 0) - (a.pinned ? 1 : 0) || byNewest(a, b));
  const page = paginate(items, req.query);
  res.json({ items: page.items.map((p) => S.post(p, req.user.id)), next_cursor: page.next_cursor });
});

router.post('/communities/:communityId/posts', requireMember, idempotency, (req, res, next) => {
  try {
    const b = check(req.body, {
      text: { required: true, type: 'string', min: 1, max: 5000 }, media_ids: { type: 'array', maxItems: 4 },
      // A question is a post the community answers in its comments.
      kind: { type: 'string', enum: ['post', 'question'] },
      // Name hidden from other students; authorId is kept so moderators can act on abuse.
      anonymous: { type: 'boolean' },
    });
    ownedMedia(b.media_ids, req.user.id);
    const p = store.insert('posts', {
      communityId: req.community.id, authorId: req.user.id, text: b.text.trim(), mediaIds: b.media_ids || [], pinned: false,
      kind: b.kind || 'post', anonymous: !!b.anonymous,
    });
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
      const commentIds = new Set(store.where('comments', (c) => c.postId === req.post.id).map((c) => c.id));
      store.remove('likes', (l) => l.postId === req.post.id);
      store.remove('questionFollows', (f) => f.postId === req.post.id);
      store.remove('postMarks', (m) => m.postId === req.post.id);
      store.remove('answerVotes', (v) => commentIds.has(v.commentId));
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
  res.json({ items: page.items.map((c) => S.comment(c, req.post.communityId, req.user.id)), next_cursor: page.next_cursor });
});

router.post('/posts/:postId/comments', loadPost, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 2000 } });
    const c = store.insert('comments', { postId: req.post.id, authorId: req.user.id, text: b.text.trim() });
    const question = (req.post.kind || 'post') === 'question';
    const preview = b.text.trim().slice(0, 140);
    if (req.post.authorId !== req.user.id) {
      notify(req.post.authorId, 'comment_reply', {
        title: question ? `${req.user.fullName} answered your question` : `${req.user.fullName} commented on your post`,
        body: preview, targetRoute: `/post/${req.post.id}`,
      });
    }
    // Followers of a question hear about each new answer (not the one who wrote it, not the asker twice).
    if (question) {
      for (const f of store.where('questionFollows', (x) => x.postId === req.post.id)) {
        if (f.userId === req.user.id || f.userId === req.post.authorId) continue;
        notify(f.userId, 'comment_reply', { title: 'New answer to a question you follow', body: preview, targetRoute: `/post/${req.post.id}` });
      }
    }
    res.status(201).json(S.comment(c, req.post.communityId, req.user.id));
  } catch (e) { next(e); }
});

// ───── Questions: follow (hear about new answers) ─────
function requireQuestion(req, _res, next) {
  if ((req.post.kind || 'post') !== 'question') return next(validation([{ field: 'postId', message: 'only questions can be followed' }]));
  next();
}

router.put('/posts/:postId/follow', loadPost, requireQuestion, (req, res) => {
  if (!store.first('questionFollows', (f) => f.postId === req.post.id && f.userId === req.user.id))
    store.insert('questionFollows', { postId: req.post.id, userId: req.user.id });
  res.json(S.followState(req.post.id, req.user.id));
});

router.delete('/posts/:postId/follow', loadPost, requireQuestion, (req, res) => {
  store.remove('questionFollows', (f) => f.postId === req.post.id && f.userId === req.user.id);
  res.json(S.followState(req.post.id, req.user.id));
});

// ───── Personal marks: "Hide this post" (from my feed only) and "Pass" on a question ─────
function setMark(kind, on) {
  return (req, res) => {
    const mine = (m) => m.postId === req.post.id && m.userId === req.user.id && m.kind === kind;
    if (on && !store.first('postMarks', mine)) store.insert('postMarks', { postId: req.post.id, userId: req.user.id, kind });
    if (!on) store.remove('postMarks', mine);
    res.status(204).end();
  };
}
function requireQuestionToPass(req, _res, next) {
  if ((req.post.kind || 'post') !== 'question') return next(validation([{ field: 'postId', message: 'only questions can be passed' }]));
  next();
}
router.put('/posts/:postId/hide', loadPost, setMark('hidden', true));
router.delete('/posts/:postId/hide', loadPost, setMark('hidden', false));
router.put('/posts/:postId/pass', loadPost, requireQuestionToPass, setMark('passed', true));
router.delete('/posts/:postId/pass', loadPost, requireQuestionToPass, setMark('passed', false));

// ───── Answers: "Helpful" votes ─────
// Loads the answer; 404 unless the caller belongs to its community (like posts).
function loadAnswer(req, _res, next) {
  const c = store.get('comments', req.params.commentId);
  const post = c && store.get('posts', c.postId);
  const m = post && store.first('memberships', (x) => x.communityId === post.communityId && x.userId === req.user.id && x.status === 'member');
  if (!c || !post || !m || c.hidden) return next(notFound('Answer'));
  if ((post.kind || 'post') !== 'question') return next(validation([{ field: 'commentId', message: 'only answers to questions can be voted on' }]));
  req.answer = c;
  next();
}

router.put('/comments/:commentId/vote', loadAnswer, (req, res, next) => {
  if (req.answer.authorId === req.user.id) return next(forbidden('own_answer', 'You cannot vote for your own answer'));
  if (!store.first('answerVotes', (v) => v.commentId === req.answer.id && v.userId === req.user.id))
    store.insert('answerVotes', { commentId: req.answer.id, userId: req.user.id });
  res.json(S.voteState(req.answer.id, req.user.id));
});

router.delete('/comments/:commentId/vote', loadAnswer, (req, res) => {
  store.remove('answerVotes', (v) => v.commentId === req.answer.id && v.userId === req.user.id);
  res.json(S.voteState(req.answer.id, req.user.id));
});

// ───── Search posts and questions in the caller's communities ─────
router.get('/search/posts', (req, res, next) => {
  try {
    const q = String(req.query.q || '').trim().toLowerCase();
    if (q.length < 2) throw validation([{ field: 'q', message: 'type at least 2 characters' }]);
    const mine = new Set(store.where('memberships', (m) => m.userId === req.user.id && m.status === 'member').map((m) => m.communityId));
    const blocked = (a) => !!store.first('blocks', (x) => (x.blockerId === req.user.id && x.blockedId === a) || (x.blockerId === a && x.blockedId === req.user.id));
    const kind = req.query.kind;
    const hiddenForMe = hiddenByMe(req.user.id);
    const items = store.where('posts', (p) => mine.has(p.communityId) && !p.hidden && !hiddenForMe.has(p.id) && (!kind || (p.kind || 'post') === kind)
      && (p.text || '').toLowerCase().includes(q) && !blocked(p.authorId)).sort(byNewest);
    const page = paginate(items, req.query);
    res.json({ items: page.items.map((p) => S.post(p, req.user.id)), next_cursor: page.next_cursor });
  } catch (e) { next(e); }
});

module.exports = router;
