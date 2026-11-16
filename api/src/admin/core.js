// Shared helpers for the back-office (staff) API mounted at /v1/admin.
const sessions = require('./sessions');
const config = require('../config');
const store = require('../db/store');
const { unauthorized, forbidden, notFound, validation } = require('../utils/errors');

const ROLES = { STUDENT: 'STUDENT', MENTOR: 'MENTOR', SUPER_MENTOR: 'SUPER_MENTOR', ALUMNI: 'ALUMNI', CONTENT_ADMIN: 'CONTENT_ADMIN', SYSTEM_ADMIN: 'SYSTEM_ADMIN' };
const STAFF = [ROLES.SYSTEM_ADMIN, ROLES.CONTENT_ADMIN, ROLES.SUPER_MENTOR];
const { SYSTEM_ADMIN: SYS, CONTENT_ADMIN: CA, SUPER_MENTOR: SM } = ROLES;


// ───────── roles & scope ─────────
const specificMemberships = (userId, status = 'member') =>
  store.where('memberships', (m) => m.userId === userId && (!status || m.status === status) && store.get('communities', m.communityId)?.type === 'specific');

function roleOf(u) {
  if (u.platformRole === 'system_admin') return SYS;
  if (u.platformRole === 'content_admin') return CA;
  if (u.roleOverride) return u.roleOverride;
  const ms = specificMemberships(u.id);
  if (ms.some((m) => m.role === 'super_mentor')) return SM;
  if (ms.some((m) => m.role === 'mentor')) return ROLES.MENTOR;
  return ROLES.STUDENT;
}

// null = unrestricted; array = community ids the user may act on
function scopeOf(u) {
  const role = roleOf(u);
  if (role === SYS || role === CA) return null;
  return store.where('memberships', (m) => m.userId === u.id && m.role === 'super_mentor' && m.status === 'member').map((m) => m.communityId);
}
const inScope = (scope, communityId) => scope === null || scope.includes(communityId);

function statusOf(u) {
  if (u.suspended) return 'SUSPENDED';
  if (u.invited && !u.lastLoginAt) return 'INVITED';
  const last = Date.parse(lastActive(u));
  return Date.now() - last > 30 * 864e5 ? 'INACTIVE' : 'ACTIVE';
}
const lastActive = (u) => {
  const ev = store.where('events', (e) => e.userId === u.id && !e.internal).map((e) => e.createdAt).sort().pop();
  return u.lastActiveAt || ev || u.lastLoginAt || u.createdAt;
};

// ───────── serializers ─────────
const COUNTRY_NAMES = { UG: 'Uganda', KE: 'Kenya', RW: 'Rwanda' };
const isMinor = (birthdate, threshold = 18) => {
  if (!birthdate) return false;
  const d = new Date(birthdate); if (Number.isNaN(d.getTime())) return false;
  const t = new Date(); let age = t.getFullYear() - d.getFullYear();
  if (t.getMonth() < d.getMonth() || (t.getMonth() === d.getMonth() && t.getDate() < d.getDate())) age--;
  return age < threshold;
};

function memberDto(u) {
  const inst = store.get('institutions', u.institutionId);
  const ms = specificMemberships(u.id)[0];
  const c = ms && store.get('communities', ms.communityId);
  const minor = isMinor(u.birthdate);
  const gc = minor && store.first('guardianConsents', (g) => g.userId === u.id);
  return {
    id: u.id, fullName: u.fullName, username: u.username, email: u.email, phone: u.phone || null,
    birthdate: u.birthdate || null, isMinor: minor,
    guardianConsentStatus: minor ? (gc ? gc.status : 'PENDING') : null,
    role: roleOf(u), status: statusOf(u),
    institutionId: u.institutionId, institutionName: inst ? inst.name : '',
    communityId: c ? c.id : null, communityName: c ? c.name : null,
    lastActiveAt: lastActive(u),
    participation: {
      resourcesCompleted: store.where('resourceProgress', (r) => r.userId === u.id).length,
      meetingsAttended: store.where('events', (e) => e.userId === u.id && e.type === 'meeting_attended').length,
      badgesEarned: store.where('userBadges', (b) => b.userId === u.id).length,
    },
  };
}

const DAYS = { mon: 'Monday', tue: 'Tuesday', wed: 'Wednesday', thu: 'Thursday', fri: 'Friday', sat: 'Saturday', sun: 'Sunday' };
const dayCode = (name) => (name ? Object.keys(DAYS).find((k) => DAYS[k].toLowerCase() === String(name).toLowerCase() || k === String(name).toLowerCase().slice(0, 3)) : undefined);

function communityDto(c) {
  const inst = store.get('institutions', c.institutionId);
  const sm = store.first('memberships', (m) => m.communityId === c.id && m.role === 'super_mentor' && m.status === 'member');
  const smUser = sm && store.get('users', sm.userId);
  const mentorIds = store.where('memberships', (m) => m.communityId === c.id && m.role === 'mentor' && m.status === 'member').map((m) => m.userId);
  const mt = c.meeting || {};
  return {
    id: c.id, institutionId: c.institutionId, institutionName: inst ? inst.name : '',
    kind: c.type === 'general' ? 'GENERAL' : 'SPECIFIC', name: c.name, description: c.description || '',
    coverPhotoUrl: c.coverPhotoUrl || '', meetingDay: DAYS[mt.weekday] || '', meetingTime: mt.start_time || '', meetingPlace: mt.location || '',
    superMentorId: sm ? sm.userId : '', superMentorName: smUser ? smUser.fullName : null, mentorIds,
    openForJoinRequests: c.openForJoinRequests !== false, status: c.closed ? 'CLOSED' : 'ACTIVE',
    memberCount: store.where('memberships', (m) => m.communityId === c.id && m.status === 'member').length,
    createdAt: c.createdAt,
  };
}

function institutionDto(i) {
  const comms = store.where('communities', (c) => c.institutionId === i.id);
  return {
    id: i.id, name: i.name, type: { high_school: 'HIGH_SCHOOL', institute: 'INSTITUTE' }[i.type] || 'UNIVERSITY',
    country: COUNTRY_NAMES[i.country] || i.country, city: i.city || '', generalCoverUrl: i.generalCoverUrl || '',
    shownInSignup: i.shownInSignup !== false,
    communityCount: comms.length,
    studentCount: store.where('users', (u) => u.institutionId === i.id).length,
    createdAt: i.createdAt,
  };
}

// ───────── audit ─────────
const AUDIT_LABELS = {
  role_changed: 'Changed role', staff_created: 'Created staff account', content_published: 'Published content',
  moderation_action: 'Moderation action', data_request_processed: 'Processed data request',
  audit_exported: 'Exported audit log', settings_updated: 'Updated settings',
};
function audit(req, action, target, place = 'Back office') {
  store.insert('auditLog', {
    occurredAt: store.now(), actorId: req.user.id, actorName: req.user.fullName, actorRole: roleOf(req.user),
    action, actionLabel: AUDIT_LABELS[action] || action, target, place,
  });
}

// ───────── auth middleware ─────────
// The session is looked up on the server on every request (see ./sessions.js); the cookie is just a random handle.
function adminAuth(req, res, next) {
  const found = sessions.find(req);
  if (!found) return next(unauthorized('Missing, invalid or expired session'));
  const { session, token, viaCookie } = found;
  const u = store.get('users', session.userId);
  if (!u || u.deletedAt) { sessions.revoke(session.id); return next(unauthorized()); }
  if (u.suspended) { sessions.revokeAll(u.id); return next(forbidden('ACCOUNT_SUSPENDED', 'Account suspended')); }
  if (!STAFF.includes(roleOf(u))) return next(forbidden('not_staff', 'Staff access only'));
  req.user = u; req.role = roleOf(u); req.scope = scopeOf(u); req.session = session;
  if (sessions.touch(session) && viaCookie) sessions.setCookie(res, token, session); // keeps a remembered session sliding forward
  next();
}
const allow = (...roles) => (req, _res, next) => (roles.includes(req.role) ? next() : next(forbidden('forbidden', `Requires one of: ${roles.join(', ')}`)));

// ───────── misc ─────────
const must = (col, id, label) => { const r = store.get(col, id); if (!r) throw notFound(label); return r; };
const list = (items, extra = {}) => ({ items, total: items.length, ...extra });
const text = (v) => (typeof v === 'string' ? v.trim() : v);
const getSetting = (key, def) => { const s = store.first('settings', (x) => x.key === key); return s ? s.value : def; };
const setSetting = (key, value) => { const s = store.first('settings', (x) => x.key === key); if (s) s.value = value; else store.insert('settings', { key, value }); };
const needObj = (b) => { if (!b || typeof b !== 'object') throw validation([{ field: 'body', message: 'JSON body required' }]); return b; };

module.exports = {
  ROLES, STAFF, SYS, CA, SM, roleOf, scopeOf, inScope, statusOf, lastActive, specificMemberships,
  memberDto, communityDto, institutionDto, communityDays: DAYS, dayCode, isMinor, COUNTRY_NAMES,
  audit, adminAuth, allow, must, list, text, getSetting, setSetting, needObj,
};
