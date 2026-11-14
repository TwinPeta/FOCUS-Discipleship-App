const router = require('express').Router();
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, forbidden, conflict, validation } = require('../utils/errors');
const realtime = require('../realtime/socket');
const C = require('./core');
const config = require('../config');
const mailer = require('../services/mailer');
const { SYS, CA, SM } = C;

const ROLE_ENUM = ['STUDENT', 'MENTOR', 'SUPER_MENTOR', 'ALUMNI', 'CONTENT_ADMIN', 'SYSTEM_ADMIN'];
const someRole = [SYS, CA, SM];

// ───────── shared user/membership helpers ─────────
function uniqueUsername(email) {
  const base = email.split('@')[0].toLowerCase().replace(/[^a-z0-9_.]/g, '').slice(0, 24) || 'user';
  let name = base, n = 1;
  while (store.first('users', (u) => u.username === name)) name = `${base}${++n}`;
  return name;
}
function ensureGeneral(user) {
  const g = store.first('communities', (c) => c.type === 'general' && c.institutionId === user.institutionId);
  if (g && !store.first('memberships', (m) => m.userId === user.id && m.communityId === g.id))
    store.insert('memberships', { communityId: g.id, userId: user.id, role: 'member', status: 'member', joinedAt: store.now() });
}
function setSpecific(user, communityId, role = 'member') {
  store.remove('memberships', (m) => m.userId === user.id && store.get('communities', m.communityId)?.type === 'specific');
  if (communityId) store.insert('memberships', { communityId, userId: user.id, role, status: 'member', joinedAt: store.now() });
}
function applyRole(user, role) {
  user.platformRole = role === SYS ? 'system_admin' : role === CA ? 'content_admin' : (['system_admin', 'content_admin'].includes(user.platformRole) ? 'student' : user.platformRole);
  user.roleOverride = [SYS, CA].includes(role) ? undefined : role;
  user.verifiedMentor = [SYS, CA, SM, 'MENTOR'].includes(role);
  const ms = C.specificMemberships(user.id)[0];
  if (ms && [SM, 'MENTOR'].includes(role)) ms.role = role === SM ? 'super_mentor' : 'mentor';
  else if (ms && ['STUDENT', 'ALUMNI'].includes(role)) ms.role = 'member';
}
function createUser(b, { invited = true } = {}) {
  const email = b.email.trim().toLowerCase();
  if (store.first('users', (u) => u.email === email && !u.deletedAt)) throw conflict('email_taken', 'Email is already registered');
  const inst = store.get('institutions', b.institutionId);
  if (!inst) throw validation([{ field: 'institutionId', message: 'unknown institution' }]);
  if (b.communityId) {
    const c = store.get('communities', b.communityId);
    if (!c || c.type !== 'specific' || c.institutionId !== inst.id) throw validation([{ field: 'communityId', message: 'unknown community for this institution' }]);
  }
  const role = b.role || 'STUDENT';
  const u = store.insert('users', {
    fullName: b.fullName.trim(), username: uniqueUsername(email), email, phone: b.phone ? String(b.phone).replace(/[\s-]/g, '') : undefined,
    birthdate: b.birthdate || undefined, institutionId: inst.id, country: inst.country, passwordHash: bcrypt.hashSync(crypto.randomBytes(12).toString('hex'), 10),
    emailVerified: false, phoneVerified: false, minorStatus: C.isMinor(b.birthdate) ? (b.guardianConsentReceived ? 'consented' : 'pending_guardian_consent') : 'adult',
    platformRole: 'student', invited, verifiedMentor: false,
  });
  applyRole(u, role);
  ensureGeneral(u);
  if (b.communityId) setSpecific(u, b.communityId, role === SM ? 'super_mentor' : role === 'MENTOR' ? 'mentor' : 'member');
  if (C.STAFF.includes(role)) { // staff get a set-password link to the back office; students/mentors sign in to the app with an emailed code
    const token = crypto.randomBytes(24).toString('hex');
    store.insert('resetTokens', { userId: u.id, token, expiresAt: Date.now() + 7 * 864e5, used: false });
    mailer.notify(u.email, 'invite', { name: u.fullName, link: `${config.backofficeUrl}/reset-password?token=${token}` });
  }
  if (C.isMinor(b.birthdate)) store.insert('guardianConsents', { userId: u.id, guardianName: '', guardianContact: '', status: b.guardianConsentReceived ? 'RECEIVED' : 'PENDING', updatedAt: store.now() });
  return u;
}

const memberScope = (req) => (u) => req.scope === null || C.specificMemberships(u.id, null).some((m) => req.scope.includes(m.communityId));

// ───────── dashboard ─────────
router.get('/dashboard', C.allow(...someRole), (req, res) => {
  const users = store.where('users', (u) => !u.deletedAt).filter(memberScope(req));
  const statuses = users.map(C.statusOf);
  const pending = store.where('joinRequests', (j) => j.status === 'pending' && C.inScope(req.scope, j.communityId)).length;
  const openReports = store.where('reports', (r) => r.status === 'open').length;
  const pendingContent = store.where('content', (c) => c.status === 'IN_REVIEW').length;
  const pendingTestimonies = store.where('testimonies', (t) => t.status === 'pending_review' && C.inScope(req.scope, t.communityId)).length;
  const inactive = users.filter((u, i) => statuses[i] === 'INACTIVE').map((u) => {
    const last = C.lastActive(u);
    const ms = C.specificMemberships(u.id)[0];
    return { id: u.id, name: u.fullName, community: ms ? store.get('communities', ms.communityId)?.name || '' : '', daysInactive: Math.floor((Date.now() - Date.parse(last)) / 864e5), lastActiveAt: last };
  });
  const days = [...Array(7)].map((_, i) => { const d = new Date(Date.now() - (6 - i) * 864e5); return d.toISOString().slice(0, 10); });
  const events = store.col('events').filter((e) => !e.internal);
  const weeklyActivity = days.map((d) => ({
    day: new Date(d).toLocaleDateString('en-US', { weekday: 'short', timeZone: 'UTC' }),
    logins: users.filter((u) => (u.lastLoginAt || '').startsWith(d)).length,
    completions: events.filter((e) => e.createdAt.startsWith(d) && /complet|finish/.test(e.type)).length,
  }));
  res.json({
    kpis: [
      { id: 'members', label: 'Total members', value: String(users.length), changePercent: 0 },
      { id: 'active', label: 'Active members', value: String(statuses.filter((s) => s === 'ACTIVE').length), changePercent: 0 },
      { id: 'pending', label: 'Pending join requests', value: String(pending), changePercent: 0 },
      { id: 'reports', label: 'Open reports', value: String(openReports), changePercent: 0 },
    ],
    weeklyActivity,
    needsAttention: [
      { id: 'jr', label: 'Join requests awaiting approval', count: pending, href: '/join-requests' },
      { id: 'rep', label: 'Reports to review', count: openReports, href: '/moderation/reports' },
      { id: 'tes', label: 'Testimonies awaiting review', count: pendingTestimonies, href: '/moderation/testimonies' },
      ...(req.role === SM ? [] : [{ id: 'con', label: 'Content awaiting validation', count: pendingContent, href: '/content' }]),
    ].filter((x) => x.count > 0),
    inactiveMembers: inactive,
  });
});

// ───────── members ─────────
router.get('/members', C.allow(SYS, SM), (req, res) => {
  const q = String(req.query.q || '').toLowerCase();
  let items = store.where('users', (u) => !u.deletedAt).filter(memberScope(req)).map(C.memberDto);
  if (q) items = items.filter((m) => `${m.fullName} ${m.email} ${m.username}`.toLowerCase().includes(q));
  for (const k of ['role', 'status', 'communityId', 'institutionId']) if (req.query[k]) items = items.filter((m) => m[k] === req.query[k]);
  res.json(C.list(items));
});
router.get('/members/inactive', C.allow(SYS, SM), (req, res) => res.json(C.list(store.where('users', (u) => !u.deletedAt).filter(memberScope(req)).filter((u) => C.statusOf(u) === 'INACTIVE').map(C.memberDto))));

function loadMember(req) {
  const u = C.must('users', req.params.id, 'Member');
  if (!memberScope(req)(u)) throw notFound('Member');
  return u;
}
router.get('/members/:id', C.allow(SYS, SM), (req, res, next) => { try { res.json(C.memberDto(loadMember(req))); } catch (e) { next(e); } });

router.post('/members', C.allow(SYS), (req, res, next) => {
  try {
    const b = check(req.body, {
      fullName: { required: true, type: 'string', min: 2, max: 100 }, email: { required: true, type: 'string', email: true },
      phone: { type: 'string' }, birthdate: { type: 'string', pattern: /^\d{4}-\d{2}-\d{2}$/ },
      role: { type: 'string', enum: ROLE_ENUM }, institutionId: { required: true, type: 'string' }, communityId: { type: 'string' },
    });
    b.guardianConsentReceived = req.body.guardianConsentReceived === true;
    if (b.role === SM && !b.communityId) throw validation([{ field: 'communityId', message: 'is required for a super-mentor' }]);
    const u = createUser(b);
    if (b.role && [SYS, CA, SM].includes(b.role)) C.audit(req, 'staff_created', `${u.fullName} (${b.role})`);
    res.status(201).json(C.memberDto(u));
  } catch (e) { next(e); }
});

router.post('/members/import', C.allow(SYS), (req, res, next) => {
  try {
    if (!req.body || !Array.isArray(req.body.rows)) throw validation([{ field: 'rows', message: 'must be an array' }]);
    if (req.body.rows.length > 2000) throw validation([{ field: 'rows', message: 'at most 2000 rows per import' }]);
    let createdCount = 0, skippedCount = 0; const failedRows = [];
    req.body.rows.forEach((r, i) => {
      const rowNumber = i + 1;
      try {
        const row = { ...r };
        if (!row.institutionId && row.institutionName) row.institutionId = store.first('institutions', (x) => x.name.toLowerCase() === String(row.institutionName).toLowerCase())?.id;
        if (!row.communityId && row.communityName) row.communityId = store.first('communities', (x) => x.name.toLowerCase() === String(row.communityName).toLowerCase() && x.institutionId === row.institutionId)?.id;
        check(row, { fullName: { required: true, type: 'string', min: 2 }, email: { required: true, type: 'string', email: true }, institutionId: { required: true, type: 'string' } });
        if (row.role && !ROLE_ENUM.includes(row.role)) row.role = 'STUDENT';
        if (store.first('users', (u) => u.email === row.email.trim().toLowerCase())) { skippedCount++; return; }
        createUser(row); createdCount++;
      } catch (e) { failedRows.push({ rowNumber, error: e.errors ? e.errors.map((x) => `${x.field} ${x.message}`).join('; ') : (e.detail || e.message) }); }
    });
    res.json({ createdCount, skippedCount, failedRows });
  } catch (e) { next(e); }
});

router.patch('/members/:id/role', C.allow(SYS), (req, res, next) => {
  try {
    const u = loadMember(req);
    const b = check(req.body, { role: { required: true, type: 'string', enum: ROLE_ENUM } });
    if (u.id === req.user.id) throw forbidden('cannot_change_own_role', 'You cannot change your own role');
    const before = C.roleOf(u);
    applyRole(u, b.role);
    C.audit(req, 'role_changed', `${u.fullName}: ${before} → ${b.role}`);
    res.json(C.memberDto(u));
  } catch (e) { next(e); }
});

router.patch('/members/:id/community', C.allow(SYS), (req, res, next) => {
  try {
    const u = loadMember(req);
    const b = check(req.body, { communityId: { required: true, type: 'string' } });
    const c = C.must('communities', b.communityId, 'Community');
    if (c.type !== 'specific' || c.institutionId !== u.institutionId) throw validation([{ field: 'communityId', message: 'must be a specific community of the member\'s institution' }]);
    const role = C.roleOf(u);
    setSpecific(u, c.id, role === SM ? 'super_mentor' : role === 'MENTOR' ? 'mentor' : 'member');
    store.insert('events', { userId: u.id, type: 'community_moved', label: `Moved to ${c.name}`, internal: true });
    res.json(C.memberDto(u));
  } catch (e) { next(e); }
});

router.post('/members/:id/suspend', C.allow(SYS), (req, res, next) => {
  try {
    const u = loadMember(req);
    const b = check(req.body, { reason: { required: true, type: 'string', min: 5, max: 500 } });
    if (u.id === req.user.id) throw forbidden('cannot_suspend_self', 'You cannot suspend yourself');
    u.suspended = true;
    const ms = C.specificMemberships(u.id)[0];
    store.insert('sanctions', { userId: u.id, communityId: ms ? ms.communityId : null, type: 'SUSPENSION', reason: b.reason, issuedBy: req.user.fullName, issuedAt: store.now(), active: true });
    store.remove('refreshTokens', (r) => r.userId === u.id);
    C.audit(req, 'moderation_action', `Suspended ${u.fullName}`);
    res.json(C.memberDto(u));
  } catch (e) { next(e); }
});

router.post('/members/:id/remind', C.allow(SYS, SM), (req, res, next) => {
  try {
    const u = loadMember(req);
    store.insert('events', { userId: u.id, type: 'reminder_sent', label: 'Check-in reminder sent', internal: true });
    if (u.email) mailer.notify(u.email, 'reminder', { name: u.fullName, from: req.user.fullName });
    res.json({ ok: true });
  } catch (e) { next(e); }
});

// ───────── institutions ─────────
const COUNTRY_CODES = Object.fromEntries(Object.entries(C.COUNTRY_NAMES).map(([k, v]) => [v.toLowerCase(), k]));
function instInput(body, partial) {
  const b = check(body, {
    name: { required: !partial, type: 'string', min: 2, max: 120 }, type: { required: !partial, type: 'string', enum: ['UNIVERSITY', 'HIGH_SCHOOL'] },
    country: { type: 'string' }, city: { required: !partial, type: 'string', min: 2 }, generalCoverUrl: { type: 'string' },
  });
  const out = {};
  if (b.name) out.name = b.name.trim();
  if (b.type) out.type = b.type === 'HIGH_SCHOOL' ? 'high_school' : 'university';
  if (b.country !== undefined || !partial) {
    const code = COUNTRY_CODES[String(b.country || 'Uganda').toLowerCase()] || (C.COUNTRY_NAMES[String(b.country).toUpperCase()] && String(b.country).toUpperCase());
    if (!code) throw validation([{ field: 'country', message: 'must be one of: ' + Object.values(C.COUNTRY_NAMES).join(', ') }]);
    out.country = code;
  }
  if (b.city) out.city = b.city.trim();
  if (b.generalCoverUrl !== undefined) out.generalCoverUrl = b.generalCoverUrl;
  if (typeof body.shownInSignup === 'boolean') out.shownInSignup = body.shownInSignup;
  return out;
}
router.get('/institutions', C.allow(...someRole), (_req, res) => res.json(C.list(store.col('institutions').map(C.institutionDto))));
router.post('/institutions', C.allow(SYS), (req, res, next) => {
  try {
    const d = instInput(req.body, false);
    if (store.first('institutions', (i) => i.name.toLowerCase() === d.name.toLowerCase() && i.country === d.country)) throw conflict('institution_exists', 'Institution already exists');
    const i = store.insert('institutions', { shownInSignup: true, ...d });
    store.insert('communities', { type: 'general', name: 'General community', initials: 'GE', institutionId: i.id, description: `Everyone on the ${i.name} campus, open to all.` });
    res.status(201).json(C.institutionDto(i));
  } catch (e) { next(e); }
});
router.patch('/institutions/:id', C.allow(SYS), (req, res, next) => {
  try {
    const i = C.must('institutions', req.params.id, 'Institution');
    res.json(C.institutionDto(Object.assign(i, instInput(req.body, true))));
  } catch (e) { next(e); }
});

// ───────── communities ─────────
const visibleCommunity = (req) => (c) => C.inScope(req.scope, c.id);
router.get('/communities', C.allow(...someRole), (req, res) => {
  let items = store.col('communities').filter(visibleCommunity(req)).map(C.communityDto);
  if (req.query.institutionId) items = items.filter((c) => c.institutionId === req.query.institutionId);
  if (req.query.kind) items = items.filter((c) => c.kind === req.query.kind);
  res.json(C.list(items));
});
router.get('/communities/:id', C.allow(...someRole), (req, res, next) => {
  try { const c = C.must('communities', req.params.id, 'Community'); if (!visibleCommunity(req)(c)) throw notFound('Community'); res.json(C.communityDto(c)); } catch (e) { next(e); }
});

function applyCommunity(c, b, partial) {
  if (b.name !== undefined) c.name = b.name.trim();
  if (b.name) c.initials = b.name.split(/\s+/).map((w) => w[0]).join('').slice(0, 2).toUpperCase();
  if (b.description !== undefined) c.description = b.description;
  if (b.coverPhotoUrl !== undefined) c.coverPhotoUrl = b.coverPhotoUrl;
  if (typeof b.openForJoinRequests === 'boolean') c.openForJoinRequests = b.openForJoinRequests;
  if (b.status) c.closed = b.status === 'CLOSED';
  if (b.meetingDay !== undefined || b.meetingTime !== undefined || b.meetingPlace !== undefined) {
    const code = b.meetingDay ? C.dayCode(b.meetingDay) : (c.meeting || {}).weekday;
    if (b.meetingDay && !code) throw validation([{ field: 'meetingDay', message: 'must be a weekday' }]);
    c.meeting = { recurrence: 'weekly', timezone: 'Africa/Kampala', ...(c.meeting || {}), weekday: code, start_time: b.meetingTime ?? (c.meeting || {}).start_time, location: b.meetingPlace ?? (c.meeting || {}).location };
  }
  if (b.superMentorId !== undefined) {
    if (b.superMentorId) {
      const u = C.must('users', b.superMentorId, 'Super-mentor');
      store.where('memberships', (m) => m.communityId === c.id && m.role === 'super_mentor' && m.userId !== u.id).forEach((m) => { m.role = 'mentor'; });
      setSpecificFor(u, c.id, 'super_mentor');
    }
  }
  if (Array.isArray(b.mentorIds)) {
    b.mentorIds.forEach((id) => { const u = C.must('users', id, 'Mentor'); const m = store.first('memberships', (x) => x.userId === id && x.communityId === c.id); if (!m || m.role === 'member') setSpecificFor(u, c.id, 'mentor'); });
  }
}
function setSpecificFor(user, communityId, role) {
  const m = store.first('memberships', (x) => x.userId === user.id && x.communityId === communityId);
  if (m) { m.role = role; m.status = 'member'; m.joinedAt = m.joinedAt || store.now(); } else setSpecific(user, communityId, role);
}
const commRules = (partial) => ({
  institutionId: { required: !partial, type: 'string' }, name: { required: !partial, type: 'string', min: 2, max: 120 }, description: { type: 'string', max: 1000 },
  coverPhotoUrl: { type: 'string' }, meetingDay: { type: 'string' }, meetingTime: { type: 'string' }, meetingPlace: { type: 'string' },
  superMentorId: { type: 'string' }, mentorIds: { type: 'array' }, status: { type: 'string', enum: ['ACTIVE', 'CLOSED'] },
});
router.post('/communities', C.allow(SYS), (req, res, next) => {
  try {
    const b = check(req.body, commRules(false));
    C.must('institutions', b.institutionId, 'Institution');
    const c = store.insert('communities', { type: b.kind === 'GENERAL' ? 'general' : 'specific', institutionId: b.institutionId, name: b.name.trim() });
    applyCommunity(c, b, false);
    res.status(201).json(C.communityDto(c));
  } catch (e) { next(e); }
});
router.patch('/communities/:id', C.allow(SYS, SM), (req, res, next) => {
  try {
    const c = C.must('communities', req.params.id, 'Community');
    if (!visibleCommunity(req)(c)) throw notFound('Community');
    const b = check(req.body, commRules(true));
    if (req.role === SM) { delete b.superMentorId; delete b.institutionId; delete b.status; } // super-mentors manage content, not structure
    applyCommunity(c, b, true);
    res.json(C.communityDto(c));
  } catch (e) { next(e); }
});

// ───────── join requests ─────────
const STATUS_OUT = { pending: 'PENDING', approved: 'APPROVED', rejected: 'DECLINED', cancelled: 'DECLINED' };
function jrDto(j) {
  const u = store.get('users', j.userId) || {};
  const c = store.get('communities', j.communityId) || {};
  const inst = store.get('institutions', u.institutionId);
  const cur = store.first('memberships', (m) => m.userId === j.userId && m.status === 'member' && store.get('communities', m.communityId)?.type === 'specific');
  const curC = cur && store.get('communities', cur.communityId);
  return {
    id: j.id, studentId: j.userId, studentUsername: u.username || '', institutionName: inst ? inst.name : '',
    requestedCommunityId: j.communityId, requestedCommunityName: c.name || '', requestedAt: j.createdAt, status: STATUS_OUT[j.status] || 'PENDING',
    currentSpecificCommunityId: curC ? curC.id : null, currentSpecificCommunityName: curC ? curC.name : null,
  };
}
router.get('/join-requests', C.allow(SYS, SM, CA), (req, res) => {
  let items = store.col('joinRequests').filter((j) => C.inScope(req.scope, j.communityId));
  if (req.query.status) items = items.filter((j) => STATUS_OUT[j.status] === String(req.query.status).toUpperCase());
  items = items.sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)).map(jrDto);
  res.json(C.list(items, { counts: { pending: items.filter((x) => x.status === 'PENDING').length } }));
});
function decide(req, j, approve, reason) {
  if (!C.inScope(req.scope, j.communityId)) throw notFound('Join request');
  if (j.status !== 'pending') throw conflict('not_pending', 'This request was already decided');
  if (approve) {
    const other = store.first('memberships', (m) => m.userId === j.userId && m.status === 'member' && m.communityId !== j.communityId && store.get('communities', m.communityId)?.type === 'specific');
    if (other) throw conflict('community_limit_reached', 'Student already belongs to another specific community');
  }
  j.status = approve ? 'approved' : 'rejected'; j.decidedAt = store.now(); j.decidedBy = req.user.id; j.note = reason || null;
  if (approve) { const m = store.first('memberships', (x) => x.userId === j.userId && x.communityId === j.communityId); if (m) { m.status = 'member'; m.joinedAt = store.now(); } }
  else store.remove('memberships', (m) => m.userId === j.userId && m.communityId === j.communityId && m.status === 'pending');
  try { realtime.emit(j.userId, 'join_request.decided', { request_id: j.id, community_id: j.communityId, status: j.status }); } catch { /* realtime optional */ }
}
router.post('/join-requests/bulk-approve', C.allow(SYS, SM), (req, res, next) => {
  try {
    if (!req.body || !Array.isArray(req.body.ids)) throw validation([{ field: 'ids', message: 'must be an array' }]);
    const approved = [], skipped = [];
    for (const id of req.body.ids) {
      const j = store.get('joinRequests', id);
      if (!j) { skipped.push({ id, reason: 'not_found' }); continue; }
      try { decide(req, j, true); approved.push(id); } catch (e) { skipped.push({ id, reason: e.code || 'error' }); }
    }
    res.json({ approved, skipped });
  } catch (e) { next(e); }
});
router.post('/join-requests/:id/approve', C.allow(SYS, SM), (req, res, next) => { try { const j = C.must('joinRequests', req.params.id, 'Join request'); decide(req, j, true); res.json(jrDto(j)); } catch (e) { next(e); } });
router.post('/join-requests/:id/decline', C.allow(SYS, SM), (req, res, next) => { try { const j = C.must('joinRequests', req.params.id, 'Join request'); decide(req, j, false, req.body && req.body.reason); res.json(jrDto(j)); } catch (e) { next(e); } });

// ───────── staff accounts (roles page) ─────────
router.post('/roles/staff', C.allow(SYS), (req, res, next) => {
  try {
    const b = check(req.body, { fullName: { required: true, type: 'string', min: 2 }, email: { required: true, type: 'string', email: true }, role: { required: true, type: 'string', enum: [SYS, CA, SM] }, communityId: { type: 'string' } });
    if (b.role === SM && !b.communityId) throw validation([{ field: 'communityId', message: 'is required for a super-mentor' }]);
    const comm = b.communityId && C.must('communities', b.communityId, 'Community');
    const institutionId = comm ? comm.institutionId : store.col('institutions')[0].id;
    const u = createUser({ fullName: b.fullName, email: b.email, role: b.role, institutionId, communityId: b.communityId });
    C.audit(req, 'staff_created', `${u.fullName} (${b.role})`);
    res.status(201).json({ id: u.id, fullName: u.fullName, email: u.email, role: b.role, communityId: b.communityId || null, createdAt: u.createdAt });
  } catch (e) { next(e); }
});

module.exports = { router, createUser, applyRole, jrDto };
