const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, conflict, forbidden } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { requireMember, requireSuperMentor } = require('../middleware/auth');
const realtime = require('../realtime/socket');
const S = require('../utils/serialize');
const { notify } = require('../utils/notify');

function joinRequestDto(j, viewerId) {
  return {
    id: j.id,
    community: S.communitySummary(store.get('communities', j.communityId), viewerId),
    user: S.userRef(store.get('users', j.userId), j.communityId),
    status: j.status,
    created_at: j.createdAt,
    decided_at: j.decidedAt || null,
    note: j.note || null, // the super-mentor's message when declining
  };
}

// Browse / search. Defaults to the caller's institution.
router.get('/communities', (req, res) => {
  const { type, q } = req.query;
  const institutionId = req.query.institution_id || req.user.institutionId;
  const needle = q ? String(q).toLowerCase() : null;
  const days = { mon: 'monday', tue: 'tuesday', wed: 'wednesday', thu: 'thursday', fri: 'friday', sat: 'saturday', sun: 'sunday' };
  const items = store.col('communities').filter((c) => {
    if (c.institutionId !== institutionId) return false;
    if (type && c.type !== type) return false;
    if (!needle) return true;
    const hay = [c.name, c.meeting?.weekday, days[c.meeting?.weekday], c.meeting?.location].filter(Boolean).join(' ').toLowerCase();
    return hay.includes(needle);
  });
  const page = paginate(items, req.query);
  res.json({ items: page.items.map((c) => S.communitySummary(c, req.user.id)), next_cursor: page.next_cursor });
});

router.get('/communities/:communityId', (req, res, next) => {
  const c = store.get('communities', req.params.communityId);
  if (!c) return next(notFound('Community'));
  res.json(S.community(c, req.user.id));
});

router.get('/communities/:communityId/members', requireMember, (req, res) => {
  const { role, online } = req.query;
  const rank = { super_mentor: 0, mentor: 1, member: 2 };
  let ms = store.where('memberships', (m) => m.communityId === req.community.id && m.status === 'member');
  if (role) ms = ms.filter((m) => m.role === role);
  if (online !== undefined) ms = ms.filter((m) => realtime.isOnline(m.userId) === (online === 'true'));
  ms.sort((a, b) => rank[a.role] - rank[b.role]);
  const page = paginate(ms, req.query);
  res.json({
    items: page.items.map((m) => ({
      ...S.userRef(store.get('users', m.userId), req.community.id),
      joined_at: m.joinedAt,
    })),
    next_cursor: page.next_cursor,
  });
});

// When each member last did anything, for the super-mentor's "members to follow up". Timestamps only, never the events.
router.get('/communities/:communityId/members/last-active', (req, res, next) => {
  try {
    if (!store.get('communities', req.params.communityId)) throw notFound('Community');
    requireSuperMentor(req.params.communityId, req.user.id);
    const ids = new Set(store.where('memberships', (m) => m.communityId === req.params.communityId && m.status === 'member').map((m) => m.userId));
    const last = {};
    store.where('events', (e) => ids.has(e.userId) && !e.internal).forEach((e) => {
      if (!last[e.userId] || last[e.userId] < e.createdAt) last[e.userId] = e.createdAt;
    });
    res.json({ items: Object.entries(last).map(([user_id, last_active_at]) => ({ user_id, last_active_at })) });
  } catch (e) { next(e); }
});

router.post('/communities/:communityId/join-requests', (req, res, next) => {
  try {
    const c = store.get('communities', req.params.communityId);
    if (!c) throw notFound('Community');
    if (c.type !== 'specific') throw conflict('not_joinable', 'The general community is joined automatically');
    if (c.institutionId !== req.user.institutionId) throw forbidden('wrong_institution', 'This community belongs to another institution');
    // Rule: only one specific community per user (pending or approved).
    const existing = store.first('memberships', (m) =>
      m.userId === req.user.id && store.get('communities', m.communityId)?.type === 'specific');
    if (existing) throw conflict('community_limit_reached', 'You can join only one specific community');

    const jr = store.insert('joinRequests', { communityId: c.id, userId: req.user.id, status: 'pending', decidedAt: null });
    store.insert('memberships', { communityId: c.id, userId: req.user.id, role: 'member', status: 'pending', joinedAt: null });
    res.status(201).json(joinRequestDto(jr, req.user.id));
  } catch (e) { next(e); }
});

router.get('/communities/:communityId/join-requests', (req, res, next) => {
  try {
    if (!store.get('communities', req.params.communityId)) throw notFound('Community');
    requireSuperMentor(req.params.communityId, req.user.id);
    const status = req.query.status || 'pending';
    const items = store.where('joinRequests', (j) => j.communityId === req.params.communityId && j.status === status).sort(byNewest);
    res.json({ items: items.map((j) => joinRequestDto(j, req.user.id)) });
  } catch (e) { next(e); }
});

router.delete('/join-requests/:requestId', (req, res, next) => {
  try {
    const j = store.get('joinRequests', req.params.requestId);
    if (!j || j.userId !== req.user.id) throw notFound('Join request');
    if (j.status !== 'pending') throw conflict('not_pending', 'Only pending requests can be cancelled');
    j.status = 'cancelled';
    j.decidedAt = store.now();
    store.remove('memberships', (m) => m.userId === j.userId && m.communityId === j.communityId && m.status === 'pending');
    res.status(204).end();
  } catch (e) { next(e); }
});

router.post('/join-requests/:requestId/decision', (req, res, next) => {
  try {
    const j = store.get('joinRequests', req.params.requestId);
    if (!j) throw notFound('Join request');
    requireSuperMentor(j.communityId, req.user.id);
    const b = check(req.body, { decision: { required: true, type: 'string', enum: ['approve', 'reject'] }, note: { type: 'string', max: 500 } });
    if (j.status !== 'pending') throw conflict('not_pending', 'This request was already decided');
    j.status = b.decision === 'approve' ? 'approved' : 'rejected';
    j.decidedAt = store.now();
    j.note = b.note || null;
    if (b.decision === 'approve') {
      const m = store.first('memberships', (x) => x.userId === j.userId && x.communityId === j.communityId);
      if (m) { m.status = 'member'; m.joinedAt = store.now(); }
    } else {
      store.remove('memberships', (m) => m.userId === j.userId && m.communityId === j.communityId && m.status === 'pending');
    }
    notify(j.userId, b.decision === 'approve' ? 'request_approved' : 'request_declined', {
      title: b.decision === 'approve' ? 'Your request was approved' : 'Your request was not accepted',
      body: b.decision === 'approve' ? null : (j.note || null),
      targetRoute: b.decision === 'approve' ? '/request/approved' : '/request/declined',
      vars: { community_name: (store.get('communities', j.communityId) || {}).name },
    });
    realtime.emit(j.userId, 'join_request.decided', { request_id: j.id, community_id: j.communityId, status: j.status });
    res.json(joinRequestDto(j, req.user.id));
  } catch (e) { next(e); }
});

// Leave my specific community (the General community cannot be left; a super-mentor must be replaced by staff first).
router.delete('/communities/:communityId/membership', (req, res, next) => {
  try {
    const c = store.get('communities', req.params.communityId);
    if (!c) throw notFound('Community');
    if (c.type !== 'specific') throw conflict('not_leavable', 'The general community cannot be left');
    const m = store.first('memberships', (x) => x.communityId === c.id && x.userId === req.user.id && x.status === 'member');
    if (!m) throw notFound('Membership');
    if (m.role === 'super_mentor') throw conflict('super_mentor_cannot_leave', 'Ask the FCU team to hand over leadership first');
    store.remove('memberships', (x) => x.id === m.id);
    res.status(204).end();
  } catch (e) { next(e); }
});

router.joinRequestDto = joinRequestDto;
module.exports = router;
