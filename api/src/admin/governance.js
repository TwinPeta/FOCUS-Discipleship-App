const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { conflict, forbidden, validation, notFound } = require('../utils/errors');
const bcrypt = require('bcryptjs');
const C = require('./core');
const { SYS, CA, SM } = C;

const comm = (id) => store.get('communities', id);
const userName = (id) => store.get('users', id)?.fullName || 'Unknown';
const note = (b) => check(b, { notes: { required: true, type: 'string', min: 3, max: 1000 } }).notes;

// ───────── moderation: reports ─────────
function targetOf(r) {
  const col = { post: 'posts', comment: 'comments', testimony: 'testimonies', prayer_request: 'prayerRequests', message: 'messages' }[r.targetType];
  const t = col ? store.get(col, r.targetId) : null;
  let authorId = r.targetType === 'user' ? r.targetId : t && (t.authorId || t.senderId);
  let communityId = t && t.communityId;
  if (!communityId && r.targetType === 'comment' && t) communityId = store.get('posts', t.postId)?.communityId;
  if (!communityId && authorId) communityId = C.specificMemberships(authorId)[0]?.communityId || null;
  return { col, t, authorId, communityId };
}
const REPORT_STATUS = { open: 'OPEN', in_review: 'IN_REVIEW', resolved: 'RESOLVED' };
function reportDto(r) {
  const { authorId, communityId } = targetOf(r);
  const author = authorId && store.get('users', authorId);
  return {
    id: r.id, reason: r.reason, reporterName: userName(r.reporterId), reportedUserId: authorId || '', reportedUserName: author ? author.fullName : 'Unknown',
    reportedUserRole: author ? C.roleOf(author) : 'STUDENT', communityId: communityId || '', communityName: comm(communityId)?.name || '', details: r.details || '',
    screenshotUrl: null, earlierReportsCount: store.where('reports', (x) => x.id !== r.id && targetOf(x).authorId === authorId && x.createdAt < r.createdAt).length,
    status: REPORT_STATUS[r.status] || 'OPEN', createdAt: r.createdAt,
  };
}
const reportVisible = (req) => (r) => C.inScope(req.scope, targetOf(r).communityId) && !(req.role === SM && r.escalated);
router.get('/moderation/reports', C.allow(SYS, SM), (req, res) => {
  let items = store.col('reports').filter(reportVisible(req)).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)).map(reportDto);
  if (req.query.status) items = items.filter((r) => r.status === String(req.query.status).toUpperCase());
  if (req.query.communityId) items = items.filter((r) => r.communityId === req.query.communityId);
  res.json(C.list(items, { counts: { OPEN: items.filter((r) => r.status === 'OPEN').length } }));
});
function sanction(req, userId, communityId, type, reason) {
  return store.insert('sanctions', { userId, communityId: communityId || null, type, reason, issuedBy: req.user.fullName, issuedAt: store.now(), active: true });
}
router.post('/moderation/reports/:id/action', C.allow(SYS, SM), (req, res, next) => {
  try {
    const r = C.must('reports', req.params.id, 'Report');
    if (!reportVisible(req)(r)) throw notFound('Report');
    const b = check(req.body, { action: { required: true, type: 'string', enum: ['DISMISS', 'WARN', 'HIDE', 'ESCALATE', 'SUSPEND', 'DELETE'] } });
    const notes = note(req.body);
    if (r.status === 'resolved') throw conflict('already_resolved', 'This report is already resolved');
    const { t, col, authorId, communityId } = targetOf(r);
    const author = authorId && store.get('users', authorId);
    if (author && C.roleOf(author) === SM && req.role !== SYS) throw forbidden('forbidden', 'Reports about a super-mentor are handled by a system admin');
    if (['SUSPEND', 'DELETE'].includes(b.action) && req.role !== SYS) throw forbidden('forbidden', `Only a system admin can ${b.action.toLowerCase()}`);
    switch (b.action) {
      case 'DISMISS': r.status = 'resolved'; break;
      case 'WARN': if (!authorId) throw conflict('no_target', 'No user to warn'); sanction(req, authorId, communityId, 'WARNING', notes); r.status = 'resolved'; break;
      case 'HIDE': if (!t) throw conflict('no_target', 'Nothing to hide'); t.hidden = true; r.status = 'resolved'; break;
      case 'ESCALATE': r.status = 'in_review'; r.escalated = true; break;
      case 'SUSPEND': if (!author) throw conflict('no_target', 'No user to suspend'); author.suspended = true; require('./sessions').revokeAll(author.id); sanction(req, authorId, communityId, 'SUSPENSION', notes).until = new Date(Date.now() + 7 * 86400000).toISOString(); store.remove('refreshTokens', (x) => x.userId === authorId); r.status = 'resolved'; break;
      case 'DELETE': if (!t || !col) throw conflict('no_target', 'Nothing to delete'); store.remove(col, (x) => x.id === t.id); r.status = 'resolved'; break;
    }
    r.resolution = { action: b.action, notes, by: req.user.id, at: store.now() };
    C.audit(req, 'moderation_action', `${b.action} · report ${r.id.slice(0, 8)}`, comm(communityId)?.name);
    res.json(reportDto(r));
  } catch (e) { next(e); }
});

// ───────── moderation: testimonies ─────────
const TEST_STATUS = { pending_review: 'PENDING', published: 'APPROVED', changes_requested: 'CHANGES_REQUESTED', rejected: 'REJECTED' };
const testDto = (t) => ({
  id: t.id, authorName: userName(t.authorId), communityId: t.communityId, communityName: comm(t.communityId)?.name || '', story: t.body, videoUrl: null,
  studentAgreement: true, notes: t.reviewNotes || null, status: TEST_STATUS[t.status] || 'PENDING', createdAt: t.createdAt,
});
router.get('/moderation/testimonies', C.allow(SYS, SM), (req, res) => {
  let items = store.col('testimonies').filter((t) => C.inScope(req.scope, t.communityId)).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)).map(testDto);
  if (req.query.status) items = items.filter((t) => t.status === String(req.query.status).toUpperCase());
  res.json(C.list(items));
});
router.post('/moderation/testimonies/:id/review', C.allow(SYS, SM), (req, res, next) => {
  try {
    const t = C.must('testimonies', req.params.id, 'Testimony');
    if (!C.inScope(req.scope, t.communityId)) throw notFound('Testimony');
    const b = check(req.body, { action: { required: true, type: 'string', enum: ['APPROVE', 'REQUEST_CHANGES', 'REJECT'] }, notes: { type: 'string', max: 1000 } });
    if (t.status !== 'pending_review') throw conflict('not_pending', 'This testimony was already reviewed');
    if (b.action !== 'APPROVE' && !b.notes) throw validation([{ field: 'notes', message: 'tell the student why' }]);
    t.status = { APPROVE: 'published', REQUEST_CHANGES: 'changes_requested', REJECT: 'rejected' }[b.action];
    t.reviewNotes = b.notes || null; t.reviewedBy = req.user.id;
    if (b.action === 'APPROVE') { t.approvedBy = req.user.id; t.publishedAt = store.now(); }
    C.audit(req, 'moderation_action', `Testimony ${b.action} · ${userName(t.authorId)}`, comm(t.communityId)?.name);
    res.json(testDto(t));
  } catch (e) { next(e); }
});

// ───────── moderation: posts / prayer / comments ─────────
const POST_COLS = [['POST', 'posts'], ['PRAYER', 'prayerRequests'], ['COMMENT', 'comments']];
function postDto(kind, p) {
  const cid = p.communityId || store.get('posts', p.postId)?.communityId;
  return { id: p.id, kind, authorName: p.anonymous ? 'Anonymous' : userName(p.authorId), communityId: cid || '', communityName: comm(cid)?.name || '', content: p.text, reportCount: store.where('reports', (r) => r.targetId === p.id && r.status !== 'resolved').length, hidden: !!p.hidden, createdAt: p.createdAt };
}
router.get('/moderation/posts', C.allow(SYS, SM), (req, res) => {
  const items = POST_COLS.flatMap(([k, col]) => store.col(col).map((p) => postDto(k, p)))
    .filter((p) => C.inScope(req.scope, p.communityId) && (p.reportCount > 0 || p.hidden || req.query.all === 'true'))
    .sort((a, b) => b.reportCount - a.reportCount || (a.createdAt < b.createdAt ? 1 : -1));
  res.json(C.list(items));
});
router.post('/moderation/posts/:id/action', C.allow(SYS, SM), (req, res, next) => {
  try {
    const b = check(req.body, { action: { required: true, type: 'string', enum: ['KEEP', 'HIDE', 'WARN_AUTHOR', 'ESCALATE'] } });
    const notes = note(req.body);
    const hit = POST_COLS.map(([k, col]) => [k, store.get(col, req.params.id)]).find(([, p]) => p);
    if (!hit) throw notFound('Post');
    const [kind, p] = hit; const dto = postDto(kind, p);
    if (!C.inScope(req.scope, dto.communityId)) throw notFound('Post');
    const open = store.where('reports', (r) => r.targetId === p.id && r.status !== 'resolved');
    if (b.action === 'KEEP') open.forEach((r) => { r.status = 'resolved'; });
    if (b.action === 'HIDE') { p.hidden = true; open.forEach((r) => { r.status = 'resolved'; }); }
    if (b.action === 'WARN_AUTHOR') { if (!p.authorId) throw conflict('no_target', 'No author'); sanction(req, p.authorId, dto.communityId, 'WARNING', notes); }
    if (b.action === 'ESCALATE') open.forEach((r) => { r.status = 'in_review'; r.escalated = true; });
    C.audit(req, 'moderation_action', `${b.action} · ${kind.toLowerCase()} ${p.id.slice(0, 8)}`, dto.communityName);
    res.json(postDto(kind, p));
  } catch (e) { next(e); }
});

// ───────── sanctions ─────────
const sanctionDto = (s) => ({ id: s.id, userId: s.userId, userName: userName(s.userId), communityId: s.communityId || '', communityName: comm(s.communityId)?.name || '', type: s.type, reason: s.reason, issuedBy: s.issuedBy, issuedAt: s.issuedAt, active: !!s.active });
router.get('/moderation/sanctions', C.allow(SYS, SM), (req, res) => res.json(C.list(store.col('sanctions').filter((s) => !s.communityId || C.inScope(req.scope, s.communityId)).sort((a, b) => (a.issuedAt < b.issuedAt ? 1 : -1)).map(sanctionDto))));
router.post('/moderation/sanctions/:id/reinstate', C.allow(SYS), (req, res, next) => {
  try {
    const s = C.must('sanctions', req.params.id, 'Sanction');
    const b = check(req.body, { reason: { required: true, type: 'string', min: 3, max: 500 } });
    if (!s.active) throw conflict('not_active', 'Sanction is not active');
    s.active = false; s.reinstatedBy = req.user.fullName; s.reinstatedReason = b.reason;
    if (s.type === 'SUSPENSION' && !store.first('sanctions', (x) => x.active && x.type === 'SUSPENSION' && x.userId === s.userId)) { const u = store.get('users', s.userId); if (u) u.suspended = false; }
    C.audit(req, 'moderation_action', `Reinstated ${userName(s.userId)}`);
    res.json(sanctionDto(s));
  } catch (e) { next(e); }
});

// ───────── privacy ─────────
router.get('/privacy/guardian-consents', C.allow(SYS), (_req, res) => {
  store.col('users').filter((u) => !u.deletedAt && C.isMinor(u.birthdate)).forEach((u) => { if (!store.first('guardianConsents', (g) => g.userId === u.id)) store.insert('guardianConsents', { userId: u.id, guardianName: '', guardianContact: '', status: 'PENDING', updatedAt: store.now() }); });
  res.json(C.list(store.col('guardianConsents').map((g) => ({ id: g.id, studentName: userName(g.userId), guardianName: g.guardianName || '—', guardianContact: g.guardianContact || '—', status: g.status, updatedAt: g.updatedAt }))));
});
router.post('/privacy/guardian-consents/:id/remind', C.allow(SYS), (req, res, next) => {
  try {
    const g = C.must('guardianConsents', req.params.id, 'Guardian consent');
    if (g.status === 'RECEIVED') throw conflict('already_received', 'Consent already received');
    g.lastReminderAt = store.now(); g.updatedAt = store.now(); res.json({ ok: true });
  } catch (e) { next(e); }
});
const dataReqDto = (d) => {
  const u = store.get('users', d.userId) || {};
  const days = C.getSetting('retention', {}).deletionDeadlineDays || 30;
  return { id: d.id, memberName: u.fullName || 'Unknown', memberEmail: u.email || '', type: d.type, requestedAt: d.requestedAt, deadlineAt: new Date(Date.parse(d.requestedAt) + days * 864e5).toISOString(), status: d.status };
};
router.get('/privacy/data-requests', C.allow(SYS), (_req, res) => res.json(C.list(store.col('dataRequests').sort((a, b) => (a.requestedAt < b.requestedAt ? 1 : -1)).map(dataReqDto))));
router.post('/privacy/data-requests/:id/process', C.allow(SYS), (req, res, next) => {
  try {
    const d = C.must('dataRequests', req.params.id, 'Data request');
    if (d.status === 'DONE') throw conflict('already_done', 'Request already processed');
    const u = store.get('users', d.userId);
    if (d.type === 'DELETION' && u) {
      // Irreversible: anonymise personal data (content stays but is detached from identity)
      Object.assign(u, { deletedAt: u.deletedAt || store.now(), fullName: 'Deleted user', email: `deleted-${u.id}@invalid`, phone: null, birthdate: null, photoUrl: null, username: `deleted-${u.id.slice(0, 8)}`, passwordHash: bcrypt.hashSync(u.id + Date.now(), 4) });
      store.remove('refreshTokens', (t) => t.userId === u.id); require('./sessions').revokeAll(u.id); store.remove('devices', (x) => x.userId === u.id);
    }
    d.status = 'DONE'; d.processedBy = req.user.id; d.processedAt = store.now();
    C.audit(req, 'data_request_processed', `${d.type} · ${d.id.slice(0, 8)}`, 'Privacy');
    res.json(dataReqDto(d));
  } catch (e) { next(e); }
});

// ───────── audit log ─────────
router.get('/audit-log', C.allow(SYS), (req, res) => {
  let items = [...store.col('auditLog')].sort((a, b) => (a.occurredAt < b.occurredAt ? 1 : -1));
  const days = { '7d': 7, '30d': 30, '90d': 90 }[req.query.period];
  if (days) items = items.filter((e) => Date.now() - Date.parse(e.occurredAt) <= days * 864e5);
  if (req.query.action) items = items.filter((e) => e.action === req.query.action);
  if (req.query.role) items = items.filter((e) => e.actorRole === req.query.role);
  const q = String(req.query.q || '').toLowerCase();
  if (q) items = items.filter((e) => `${e.actorName} ${e.actionLabel} ${e.target} ${e.place}`.toLowerCase().includes(q));
  res.json(C.list(items.map(({ id, occurredAt, actorName, actorRole, action, actionLabel, target, place }) => ({ id, occurredAt, actorName, actorRole, action, actionLabel, target, place }))));
});
router.post('/audit-log/export', C.allow(SYS), (req, res) => {
  C.audit(req, 'audit_exported', `${Number(req.body && req.body.count) || store.col('auditLog').length} entries`);
  res.json({ ok: true });
});

// ───────── reports & analytics ─────────
const REPORT_LABELS = { discipleship_summary: 'Discipleship summary', community_health: 'Community health & attendance', content_completions: 'Content completions' };
function reportsData(req) {
  const users = store.col('users').filter((u) => !u.deletedAt);
  const inCampus = (u) => !req.query.campus || req.query.campus === 'all' || u.institutionId === req.query.campus;
  const scoped = users.filter((u) => inCampus(u) && (req.scope === null || C.specificMemberships(u.id, null).some((m) => req.scope.includes(m.communityId)))
    && (!req.query.community || req.query.community === 'all' || C.specificMemberships(u.id, null).some((m) => m.communityId === req.query.community)));
  const months = [...Array(6)].map((_, i) => { const d = new Date(); d.setUTCDate(1); d.setUTCMonth(d.getUTCMonth() - (5 - i)); return d; });
  const membersOverTime = months.map((d) => {
    const key = d.toISOString().slice(0, 7); const end = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1)).toISOString();
    const total = scoped.filter((u) => u.createdAt < end);
    const active = total.filter((u) => store.col('events').some((e) => e.userId === u.id && !e.internal && e.createdAt.startsWith(key)));
    return { period: d.toLocaleDateString('en-US', { month: 'short', year: '2-digit', timeZone: 'UTC' }), totalMembers: total.length, activeMembers: active.length };
  });
  const byType = {};
  store.col('resourceProgress').forEach((p) => { const r = store.get('resources', p.resourceId); const t = (r && r.type) || 'other'; byType[t] = (byType[t] || 0) + 1; });
  const activeCommunities = store.col('communities').filter((c) => c.type === 'specific' && C.inScope(req.scope, c.id) && (!req.query.campus || req.query.campus === 'all' || c.institutionId === req.query.campus)).map((c) => {
    const ms = store.where('memberships', (m) => m.communityId === c.id && m.status === 'member');
    const act = ms.filter((m) => { const u = store.get('users', m.userId); return u && C.statusOf(u) === 'ACTIVE'; }).length;
    return { id: c.id, name: c.name, campus: store.get('institutions', c.institutionId)?.name || '', memberCount: ms.length, activePercent: ms.length ? Math.round((act / ms.length) * 100) : 0 };
  }).sort((a, b) => b.activePercent - a.activePercent);
  return { membersOverTime, completionsByType: Object.entries(byType).map(([type, completions]) => ({ type, completions })), activeCommunities, scheduledReports: store.col('reportSchedules').map(schedDto) };
}
const schedDto = (s) => ({ id: s.id, reportType: s.reportType, reportLabel: REPORT_LABELS[s.reportType], cadence: s.cadence, recipientEmail: s.recipientEmail, active: s.active !== false });
router.get('/reports', C.allow(SYS, CA, SM), (req, res) => res.json(reportsData(req)));
router.post('/reports/export', C.allow(SYS, CA, SM), (req, res, next) => {
  try {
    const b = check(req.body, { format: { required: true, type: 'string', enum: ['csv', 'json', 'pdf', 'xlsx'] } });
    if (b.format !== 'csv' && b.format !== 'json') return res.status(501).json({ type: 'about:blank', title: 'Not implemented', status: 501, code: 'format_unsupported', detail: `${b.format} export is not available yet; use csv or json` });
    req.query = { ...(req.body.filters || {}) };
    const d = reportsData(req);
    if (b.format === 'json') return res.json(d);
    const rows = [['community', 'campus', 'members', 'active_percent'], ...d.activeCommunities.map((c) => [c.name, c.campus, c.memberCount, c.activePercent])];
    res.type('text/csv').attachment('report.csv').send(rows.map((r) => r.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n'));
  } catch (e) { next(e); }
});
router.get('/reports/schedules', C.allow(SYS, CA), (_req, res) => res.json(C.list(store.col('reportSchedules').map(schedDto))));
router.post('/reports/schedules', C.allow(SYS, CA), (req, res, next) => {
  try {
    const b = check(req.body, { reportType: { required: true, type: 'string', enum: Object.keys(REPORT_LABELS) }, cadence: { required: true, type: 'string', enum: ['weekly', 'monthly', 'quarterly'] }, recipientEmail: { required: true, type: 'string', email: true } });
    res.status(201).json(schedDto(store.insert('reportSchedules', { ...b, active: true })));
  } catch (e) { next(e); }
});
router.patch('/reports/schedules/:id', C.allow(SYS, CA), (req, res, next) => {
  try {
    const b = check(req.body, { active: { required: true, type: 'boolean' } });
    const sch = C.must('reportSchedules', req.params.id, 'Schedule');
    sch.active = b.active;
    res.json(schedDto(sch));
  } catch (e) { next(e); }
});
router.delete('/reports/schedules/:id', C.allow(SYS, CA), (req, res, next) => { try { C.must('reportSchedules', req.params.id, 'Schedule'); store.remove('reportSchedules', (s) => s.id === req.params.id); res.status(204).end(); } catch (e) { next(e); } });

// ───────── my community (super-mentor home) ─────────
function myCommunity(req) {
  const id = req.scope && req.scope[0];
  const c = id && comm(id);
  if (!c) throw notFound('Community');
  return c;
}
const myJr = (j) => { const u = store.get('users', j.userId) || {}; return { id: j.id, studentName: u.fullName || '', email: u.email || '', requestedAt: j.createdAt, note: j.note || undefined }; };
router.get('/my-community', C.allow(SM), (req, res, next) => {
  try {
    const c = myCommunity(req);
    const ms = store.where('memberships', (m) => m.communityId === c.id && m.status === 'member');
    const pending = store.where('joinRequests', (j) => j.communityId === c.id && j.status === 'pending');
    const inactiveDays = C.getSetting('inactivityDays', 14);
    const follow = ms.map((m) => store.get('users', m.userId)).filter(Boolean).map((u) => ({ u, d: Math.floor((Date.now() - Date.parse(C.lastActive(u))) / 864e5) })).filter((x) => x.d >= inactiveDays);
    const reports = store.col('reports').filter((r) => targetOf(r).communityId === c.id);
    const mt = c.meeting || {};
    res.json({
      communityId: c.id, communityName: c.name, campus: store.get('institutions', c.institutionId)?.name || '',
      kpis: { members: ms.length, pendingRequests: pending.length, reportsToReview: reports.filter((r) => r.status === 'open').length, inactiveMembers: follow.length },
      pendingRequests: pending.map(myJr),
      nextMeeting: { day: C.communityDays[mt.weekday] || '', time: mt.start_time || '', place: mt.location || '' },
      followUpMembers: follow.map(({ u, d }) => ({ id: u.id, name: u.fullName, daysInactive: d, lastActiveAt: C.lastActive(u) })),
      members: ms.map((m) => { const u = store.get('users', m.userId); return u && { id: u.id, name: u.fullName, email: u.email, roleLabel: m.role === 'super_mentor' ? 'Super-mentor' : m.role === 'mentor' ? 'Mentor' : 'Student', joinedAt: m.joinedAt, active: C.statusOf(u) === 'ACTIVE' }; }).filter(Boolean),
      reports: reports.map((r) => ({ id: r.id, targetSummary: `${r.targetType} reported`, reason: r.reason, reportedBy: userName(r.reporterId), createdAt: r.createdAt, status: r.status === 'open' ? 'open' : r.escalated ? 'escalated' : 'dismissed' })),
      resources: store.col('content').filter((x) => x.status === 'PUBLISHED').map((x) => ({ id: x.id, title: x.title, type: { VIDEO: 'Video', DOCUMENT: 'Document' }[x.type] || 'Devotional', pathway: (x.pathwayIds || []).map((p) => store.get('adminPathways', p)?.name).filter(Boolean)[0] || '—', publishedAt: x.validatedAt || x.updatedAt })),
    });
  } catch (e) { next(e); }
});
const ownJoin = (approve) => (req, res, next) => {
  try {
    const c = myCommunity(req); const j = C.must('joinRequests', req.params.id, 'Join request');
    if (j.communityId !== c.id) throw notFound('Join request');
    if (j.status !== 'pending') throw conflict('not_pending', 'This request was already decided');
    if (approve && store.first('memberships', (m) => m.userId === j.userId && m.status === 'member' && m.communityId !== c.id && store.get('communities', m.communityId)?.type === 'specific')) throw conflict('community_limit_reached', 'Student already belongs to another specific community');
    j.status = approve ? 'approved' : 'rejected'; j.decidedAt = store.now(); j.decidedBy = req.user.id; j.note = (req.body && req.body.reason) || null;
    if (approve) { const m = store.first('memberships', (x) => x.userId === j.userId && x.communityId === c.id); if (m) { m.status = 'member'; m.joinedAt = store.now(); } }
    else store.remove('memberships', (m) => m.userId === j.userId && m.communityId === c.id && m.status === 'pending');
    res.json({ ok: true });
  } catch (e) { next(e); }
};
router.post('/my-community/join-requests/:id/approve', C.allow(SM), ownJoin(true));
router.post('/my-community/join-requests/:id/decline', C.allow(SM), ownJoin(false));
router.patch('/my-community/meeting', C.allow(SM), (req, res, next) => {
  try {
    const c = myCommunity(req);
    const b = check(req.body, { day: { required: true, type: 'string' }, time: { required: true, type: 'string', pattern: /^\d{2}:\d{2}$/, patternMessage: 'use HH:MM' }, place: { required: true, type: 'string', min: 2 } });
    const code = C.dayCode(b.day); if (!code) throw validation([{ field: 'day', message: 'must be a weekday' }]);
    c.meeting = { recurrence: 'weekly', timezone: 'Africa/Kampala', ...(c.meeting || {}), weekday: code, start_time: b.time, location: b.place };
    res.json({ day: C.communityDays[code], time: b.time, place: b.place });
  } catch (e) { next(e); }
});
router.post('/my-community/members/:id/remind', C.allow(SM), (req, res, next) => {
  try {
    const c = myCommunity(req);
    if (!store.first('memberships', (m) => m.userId === req.params.id && m.communityId === c.id && m.status === 'member')) throw notFound('Member');
    store.insert('events', { userId: req.params.id, type: 'reminder_sent', label: 'Check-in reminder from your super-mentor', internal: true }); res.json({ ok: true });
  } catch (e) { next(e); }
});
router.post('/my-community/announcements', C.allow(SM), (req, res, next) => {
  try {
    const c = myCommunity(req);
    const b = check(req.body, { title: { type: 'string', max: 120 }, message: { required: true, type: 'string', min: 2, max: 2000 } });
    const a = store.insert('announcements', { title: b.title || 'Message from your super-mentor', message: b.message, audienceType: 'community', communityId: c.id, status: 'published', authorName: req.user.fullName });
    res.status(201).json({ id: a.id });
  } catch (e) { next(e); }
});
router.post('/my-community/moderation/:id', C.allow(SM), (req, res, next) => {
  try {
    const c = myCommunity(req); const r = C.must('reports', req.params.id, 'Report');
    if (targetOf(r).communityId !== c.id) throw notFound('Report');
    const b = check(req.body, { decision: { required: true, type: 'string', enum: ['dismiss', 'dismissed', 'escalate', 'escalated'] }, note: { type: 'string', max: 1000 } });
    if (b.decision.startsWith('dismiss')) r.status = 'resolved'; else { r.status = 'in_review'; r.escalated = true; }
    C.audit(req, 'moderation_action', `${b.decision} · report ${r.id.slice(0, 8)}`, c.name);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

// ───────── account ─────────
router.patch('/account/profile', (req, res, next) => {
  try {
    const b = check(req.body, { fullName: { required: true, type: 'string', min: 2, max: 100 }, avatarUrl: { type: 'string' } });
    req.user.fullName = b.fullName.trim(); if (b.avatarUrl !== undefined) req.user.photoUrl = b.avatarUrl || null;
    res.json({ ok: true });
  } catch (e) { next(e); }
});
router.post('/account/password', (req, res, next) => {
  try {
    const b = check(req.body, { currentPassword: { required: true, type: 'string' }, newPassword: { required: true, type: 'string' } });
    if (!bcrypt.compareSync(b.currentPassword, req.user.passwordHash)) throw validation([{ field: 'currentPassword', message: 'is incorrect' }]);
    if (!require('./auth').strong(b.newPassword)) throw validation([{ field: 'newPassword', message: 'min 8 characters with a letter and a number' }]);
    if (bcrypt.compareSync(b.newPassword, req.user.passwordHash)) throw validation([{ field: 'newPassword', message: 'must differ from the current password' }]);
    req.user.passwordHash = bcrypt.hashSync(b.newPassword, 10);
    store.remove('refreshTokens', (t) => t.userId === req.user.id);
    require('./sessions').revokeAll(req.user.id, req.session.id); // every other device is signed out; this one stays
    res.json({ ok: true });
  } catch (e) { next(e); }
});
const sessDto = (s, cur) => ({ id: s.id, deviceName: s.deviceName, browser: s.browser, os: s.os, ipAddress: s.ipAddress, lastActiveAt: s.lastActiveAt, current: cur });
router.get('/account/sessions', (req, res) => {
  const mine = require('./sessions').active(req.user.id).sort((a, b) => (a.lastActiveAt < b.lastActiveAt ? 1 : -1));
  res.json({ sessions: mine.map((s) => sessDto(s, s.id === req.session.id)) });
});
router.delete('/account/sessions/:id', (req, res, next) => {
  try {
    const s = store.first('staffSessions', (x) => x.id === req.params.id && x.userId === req.user.id);
    if (!s) throw notFound('Session');
    const sessions = require('./sessions');
    sessions.revoke(s.id);
    if (s.id === req.session.id) sessions.clearCookies(res); // ended our own session
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = { router };
