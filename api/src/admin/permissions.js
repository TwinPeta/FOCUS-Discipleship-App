// Backoffice permissions: which modules a role can use, and what it can do in each.
// Codes: V view, C create, E edit, A approve/validate, D delete, X export. `own: true` limits the role to its own caregroup(s).
//
// How it is enforced: `enforce` runs after sign-in on every back-office request. When a request maps to a module (RULES below)
// and the person's role has its own matrix (a custom role, or a built-in role an admin has edited), that matrix decides:
// a missing code is a 403, a granted code lets the request through even where the old per-route role list would say no.
// A built-in role nobody has edited keeps the original role-list guards, so nothing changes until an admin edits it.
const store = require('../db/store');
const { forbidden } = require('../utils/errors');

const MODULES = ['Dashboard', 'Reports & exports', 'New members', 'Caregroups & meetings', 'Cover photos', 'Campuses', 'Members', 'Role changes', 'Content library', 'Pathways & badges', 'Announcements', 'Notification rules', 'Moderation level 1', 'Moderation level 2', 'Testimony review', 'Consents & data requests', 'Audit log', 'Settings'];
const CODES = ['V', 'C', 'E', 'A', 'D', 'X'];

// Proposed matrix, to be validated with FOCUS Uganda (same as the permissions matrix screen).
const DEFAULTS = {
  STUDENT: {
  },
  ALUMNI: {
  },
  MENTOR: {
    'Members': { codes: ['V'], own: true },
    'Moderation level 1': { codes: ['A'], own: true },
  },
  SUPER_MENTOR: {
    'Dashboard': { codes: ['V'], own: true },
    'Reports & exports': { codes: ['V'], own: true },
    'New members': { codes: ['V', 'A'], own: true },
    'Caregroups & meetings': { codes: ['V', 'E'], own: true },
    'Members': { codes: ['V'], own: true },
    'Announcements': { codes: ['C'], own: true },
    'Moderation level 1': { codes: ['A'], own: true },
  },
  CONTENT_ADMIN: {
    'Dashboard': { codes: ['V'] },
    'Reports & exports': { codes: ['V', 'X'] },
    'New members': { codes: ['V'] },
    'Caregroups & meetings': { codes: ['V'] },
    'Campuses': { codes: ['V'] },
    'Content library': { codes: ['V', 'C', 'E', 'A', 'D'] },
    'Pathways & badges': { codes: ['V', 'C', 'E', 'D'] },
    'Announcements': { codes: ['V', 'C', 'E', 'D'] },
    'Notification rules': { codes: ['V', 'E'] },
    'Moderation level 1': { codes: ['V'] },
    'Moderation level 2': { codes: ['A'] },
    'Testimony review': { codes: ['A'] },
  },
  SYSTEM_ADMIN: {
    'Dashboard': { codes: ['V'] },
    'Reports & exports': { codes: ['V', 'X'] },
    'New members': { codes: ['V', 'A'] },
    'Caregroups & meetings': { codes: ['V', 'C', 'E', 'D'] },
    'Cover photos': { codes: ['E'] },
    'Campuses': { codes: ['V', 'C', 'E', 'D'] },
    'Members': { codes: ['V', 'C', 'E', 'D'] },
    'Role changes': { codes: ['A'] },
    'Content library': { codes: ['V', 'C', 'E', 'A', 'D'] },
    'Pathways & badges': { codes: ['V', 'C', 'E', 'D'] },
    'Announcements': { codes: ['V', 'C', 'E', 'D'] },
    'Notification rules': { codes: ['V', 'E'] },
    'Moderation level 1': { codes: ['V'] },
    'Moderation level 2': { codes: ['A', 'D'] },
    'Testimony review': { codes: ['A'] },
    'Consents & data requests': { codes: ['A'] },
    'Audit log': { codes: ['V', 'X'] },
    'Settings': { codes: ['E'] },
  },
};

// [method, path pattern (under /v1/admin), module, code]
const RULES = [
  ['GET', /^\/dashboard$/, 'Dashboard', 'V'], ['GET', /^\/my-community$/, 'Dashboard', 'V'],
  ['GET', /^\/reports$/, 'Reports & exports', 'V'], ['POST', /^\/reports\/export$/, 'Reports & exports', 'X'],
  ['GET', /^\/reports\/schedules$/, 'Reports & exports', 'V'], ['*', /^\/reports\/schedules(\/.*)?$/, 'Reports & exports', 'E'],
  ['GET', /^\/join-requests$/, 'New members', 'V'], ['POST', /^\/join-requests\/.+$/, 'New members', 'A'],
  ['POST', /^\/my-community\/join-requests\/.+$/, 'New members', 'A'],
  ['GET', /^\/communities(\/[^/]+)?$/, 'Caregroups & meetings', 'V'], ['POST', /^\/communities$/, 'Caregroups & meetings', 'C'],
  ['PATCH', /^\/communities\/[^/]+$/, 'Caregroups & meetings', 'E'], ['PATCH', /^\/my-community\/meeting$/, 'Caregroups & meetings', 'E'],
  ['GET', /^\/institutions$/, 'Campuses', 'V'], ['GET', /^\/churches$/, 'Campuses', 'V'],
  ['POST', /^\/institutions$/, 'Campuses', 'C'], ['PATCH', /^\/institutions\/[^/]+$/, 'Campuses', 'E'],
  ['GET', /^\/members(\/.*)?$/, 'Members', 'V'], ['POST', /^\/members$/, 'Members', 'C'], ['POST', /^\/members\/import$/, 'Members', 'C'],
  ['POST', /^\/members\/[^/]+\/(suspend|remind)$/, 'Members', 'E'], ['PATCH', /^\/members\/[^/]+\/community$/, 'Members', 'E'],
  ['POST', /^\/my-community\/members\/[^/]+\/remind$/, 'Members', 'E'],
  ['PATCH', /^\/members\/[^/]+\/role$/, 'Role changes', 'A'],
  ['GET', /^\/(content(\/.*)?|bible-links)$/, 'Content library', 'V'], ['POST', /^\/content$/, 'Content library', 'C'],
  ['PATCH', /^\/content\/[^/]+$/, 'Content library', 'E'], ['POST', /^\/content\/[^/]+\/transition$/, 'Content library', 'A'],
  ['GET', /^\/(pathways|badges)(\/.*)?$/, 'Pathways & badges', 'V'], ['POST', /^\/(pathways|badges)$/, 'Pathways & badges', 'C'],
  ['PATCH', /^\/(pathways|badges)\/[^/]+$/, 'Pathways & badges', 'E'], ['PUT', /^\/(pathways|badges)\/[^/]+$/, 'Pathways & badges', 'E'],
  ['DELETE', /^\/(pathways|badges)\/[^/]+$/, 'Pathways & badges', 'D'],
  ['GET', /^\/(announcements|stories)$/, 'Announcements', 'V'], ['POST', /^\/(announcements|stories|my-community\/announcements)$/, 'Announcements', 'C'],
  ['PATCH', /^\/(announcements|stories)\/[^/]+$/, 'Announcements', 'E'], ['PUT', /^\/stories\/reorder$/, 'Announcements', 'E'],
  ['GET', /^\/(notifications\/rules|settings\/inactivity-threshold)$/, 'Notification rules', 'V'],
  ['PATCH', /^\/notifications\/rules\/[^/]+$/, 'Notification rules', 'E'], ['PUT', /^\/settings\/inactivity-threshold$/, 'Notification rules', 'E'],
  ['GET', /^\/moderation\/(reports|posts)$/, 'Moderation level 1', 'V'], ['POST', /^\/moderation\/(reports|posts)\/[^/]+\/action$/, 'Moderation level 1', 'A'],
  ['POST', /^\/my-community\/moderation\/[^/]+$/, 'Moderation level 1', 'A'],
  ['GET', /^\/moderation\/sanctions$/, 'Moderation level 2', 'V'], ['POST', /^\/moderation\/sanctions\/[^/]+\/reinstate$/, 'Moderation level 2', 'A'],
  ['GET', /^\/moderation\/testimonies$/, 'Testimony review', 'V'], ['POST', /^\/moderation\/testimonies\/[^/]+\/review$/, 'Testimony review', 'A'],
  ['GET', /^\/privacy\/.+$/, 'Consents & data requests', 'V'], ['POST', /^\/privacy\/.+$/, 'Consents & data requests', 'A'],
  ['GET', /^\/audit-log$/, 'Audit log', 'V'], ['POST', /^\/audit-log\/export$/, 'Audit log', 'X'],
  ['GET', /^\/settings\/(?!inactivity-threshold)[^/]+$/, 'Settings', 'V'], ['PATCH', /^\/settings\/[^/]+$/, 'Settings', 'E'],
];

const KEY_ROLES = 'rolePermissionOverrides'; // { ROLE: matrix } for built-in roles an admin has edited
const KEY_CUSTOM = 'customRoles'; // [{ id, name, description, base, matrix, createdAt }]
const getSetting = (k, d) => { const s = store.first('settings', (x) => x.key === k); return s ? s.value : d; };
const setSetting = (k, v) => { const s = store.first('settings', (x) => x.key === k); if (s) s.value = v; else store.insert('settings', { key: k, value: v }); };

const customRoles = () => getSetting(KEY_CUSTOM, []);
const overrides = () => getSetting(KEY_ROLES, {});
const defaultMatrix = (role) => JSON.parse(JSON.stringify(DEFAULTS[role] || {}));

/** Clean a submitted matrix: known modules and codes only. */
function sanitize(input) {
  const out = {};
  for (const m of MODULES) {
    const c = input && input[m];
    if (!c || !Array.isArray(c.codes)) continue;
    const codes = CODES.filter((x) => c.codes.includes(x));
    if (codes.length) out[m] = c.own ? { codes, own: true } : { codes };
  }
  return out;
}

/** The matrix that governs a person, or null when the original role-list guards apply. */
function matrixFor(user, role) {
  if (user.customRoleId) { const r = customRoles().find((x) => x.id === user.customRoleId); if (r) return r.matrix; }
  return overrides()[role] || null;
}

function find(method, path) {
  return RULES.find(([m, re]) => (m === '*' || m === method) && re.test(path));
}

function enforce(req, _res, next) {
  const matrix = matrixFor(req.user, req.role);
  if (!matrix) return next();
  const rule = find(req.method, req.path);
  if (!rule) return next();
  const [, , module, code] = rule;
  const cell = matrix[module];
  if (!cell || !cell.codes.includes(code)) return next(forbidden('permission_denied', `Your role cannot ${code === 'V' ? 'view' : 'do this in'} ${module}`));
  req.permGrant = true;
  // "own" means only the caregroups this person leads; otherwise everything
  req.scope = cell.own ? require('./core').ownScope(req.user) : null;
  next();
}

module.exports = { MODULES, CODES, DEFAULTS, RULES, KEY_ROLES, KEY_CUSTOM, customRoles, overrides, defaultMatrix, sanitize, matrixFor, enforce, setSetting };
