const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, conflict } = require('../utils/errors');
const { requireSuperMentor } = require('../middleware/auth');
const { notify } = require('../utils/notify');

// Mentor-level moderation: a super-mentor reviews reports on content in their own community.
// Several reports about the same item form one case. Staff handle the rest through /admin.
const CONTENT = { post: 'posts', comment: 'comments', prayer_request: 'prayerRequests', testimony: 'testimonies' };
const REASON_LABEL = {
  harassment_bullying: 'Harassment or bullying', offensive_content: 'Offensive or inappropriate content',
  breaks_community_rules: 'Breaking community rules', spam_or_fake_profile: 'Spam or fake profile', other: 'Something else',
};

const communityOf = (type, t) => (type === 'comment' ? store.get('posts', t.postId)?.communityId : t.communityId);
const previewOf = (type, t) => String(type === 'testimony' ? `${t.title}: ${t.body}` : t.text).slice(0, 200);

function cases(communityId) {
  const groups = new Map();
  store.where('reports', (r) => r.status === 'open' && !r.escalated && CONTENT[r.targetType]).forEach((r) => {
    const t = store.get(CONTENT[r.targetType], r.targetId);
    if (!t || t.hidden || communityOf(r.targetType, t) !== communityId) return;
    const key = `${r.targetType}:${r.targetId}`;
    if (!groups.has(key)) groups.set(key, { key, type: r.targetType, target: t, reports: [] });
    groups.get(key).reports.push(r);
  });
  return [...groups.values()];
}

function caseDto(g) {
  const reports = g.reports.slice().sort((a, b) => (a.createdAt < b.createdAt ? -1 : 1));
  const counts = {};
  reports.forEach((r) => { counts[r.reason] = (counts[r.reason] || 0) + 1; });
  const reason = Object.keys(counts).sort((a, b) => counts[b] - counts[a] || reports.findIndex((r) => r.reason === a) - reports.findIndex((r) => r.reason === b))[0];
  const authorId = g.target.authorId || null;
  const anonymous = g.type === 'prayer_request' && g.target.anonymous;
  const author = authorId && !anonymous ? store.get('users', authorId) : null;
  return {
    id: g.key, community_id: communityOf(g.type, g.target), content: g.type, target_id: g.target.id,
    author: author ? { id: author.id, full_name: author.fullName } : null,
    preview: previewOf(g.type, g.target), reason,
    report_count: new Set(reports.map((r) => r.reporterId)).size,
    first_reporter_name: store.get('users', reports[0].reporterId)?.fullName || 'A member',
    reported_at: reports[0].createdAt, level: 1,
  };
}

router.get('/communities/:communityId/moderation/cases', (req, res, next) => {
  try {
    if (!store.get('communities', req.params.communityId)) throw notFound('Community');
    requireSuperMentor(req.params.communityId, req.user.id);
    res.json({ items: cases(req.params.communityId).map(caseDto).sort((a, b) => (a.reported_at < b.reported_at ? -1 : 1)) });
  } catch (e) { next(e); }
});

router.post('/communities/:communityId/moderation/cases/:caseId/action', (req, res, next) => {
  try {
    if (!store.get('communities', req.params.communityId)) throw notFound('Community');
    requireSuperMentor(req.params.communityId, req.user.id);
    const b = check(req.body, { action: { required: true, type: 'string', enum: ['keep', 'hide', 'warn', 'escalate'] } });
    const g = cases(req.params.communityId).find((x) => x.key === req.params.caseId);
    if (!g) throw conflict('case_closed', 'This case is already closed');
    const dto = caseDto(g);
    const close = (patch = {}) => g.reports.forEach((r) => Object.assign(r, { status: 'resolved', resolution: { action: b.action.toUpperCase(), by: req.user.id, at: store.now(), level: 1 } }, patch));
    switch (b.action) {
      case 'keep': close(); break;
      case 'hide': g.target.hidden = true; close(); break;
      case 'warn': {
        if (!g.target.authorId) throw conflict('no_target', 'No author to warn');
        g.target.hidden = true;
        const label = REASON_LABEL[dto.reason] || 'Community guidelines';
        store.insert('sanctions', {
          userId: g.target.authorId, communityId: req.params.communityId, type: 'WARNING', reason: label, preview: dto.preview,
          issuedBy: req.user.fullName, issuedAt: store.now(), active: true,
        });
        const warning = store.first('sanctions', (s) => s.userId === g.target.authorId && s.type === 'WARNING' && s.issuedBy === req.user.fullName && s.preview === dto.preview);
        notify(g.target.authorId, 'moderator_warning', { title: 'A moderator sent you a warning', body: label, targetRoute: `/warning/${warning ? warning.id : ''}` });
        close();
        break;
      }
      case 'escalate': g.reports.forEach((r) => { r.status = 'in_review'; r.escalated = true; }); break; // now in the admin team's queue
    }
    store.insert('events', { userId: req.user.id, type: 'moderation_action', label: `${b.action} · ${g.type} ${g.target.id.slice(0, 8)}`, internal: true });
    res.json({ ...dto, outcome: { keep: 'kept', hide: 'hidden', warn: 'warned', escalate: 'escalated' }[b.action] });
  } catch (e) { next(e); }
});

module.exports = router;
