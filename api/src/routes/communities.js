const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, conflict, forbidden } = require('../utils/errors');
const { paginate, byNewest } = require('../utils/pagination');
const { requireMember, requireSuperMentor } = require('../middleware/auth');
const realtime = require('../realtime/socket');
const S = require('../utils/serialize');

function joinRequestDto(j, viewerId) {
  return {
    id: j.id,
    community: S.communitySummary(store.get('communities', j.communityId), viewerId),
    user: S.userRef(store.get('users', j.userId), j.communityId),
    status: j.status,
    created_at: j.createdAt,
    decided_at: j.decidedAt || null,
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
    realtime.emit(j.userId, 'join_request.decided', { request_id: j.id, community_id: j.communityId, status: j.status });
    res.json(joinRequestDto(j, req.user.id));
  } catch (e) { next(e); }
});

router.joinRequestDto = joinRequestDto;
module.exports = router;
