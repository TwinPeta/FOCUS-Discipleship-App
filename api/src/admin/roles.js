// Roles & permissions: the six built-in roles plus custom Backoffice roles, and the permission matrix each one uses.
// See ./permissions.js for how the matrix is enforced.
const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { validation, notFound, conflict, forbidden } = require('../utils/errors');
const C = require('./core');
const P = require('./permissions');

const { SYSTEM_ADMIN: SYS } = C.ROLES || { SYSTEM_ADMIN: 'SYSTEM_ADMIN' };
const BUILT_IN = [
  { role: 'STUDENT', slug: 'student', name: 'Student', where: 'App', scope: 'Own account', backoffice: false },
  { role: 'ALUMNI', slug: 'alumni', name: 'Alumni', where: 'App', scope: 'Own account', backoffice: false },
  { role: 'MENTOR', slug: 'mentor', name: 'Mentor', where: 'App', scope: 'Own caregroup', backoffice: false },
  { role: 'SUPER_MENTOR', slug: 'super-mentor', name: 'Super-mentor', where: 'App + Backoffice (limited)', scope: 'Own caregroup', backoffice: true },
  { role: 'CONTENT_ADMIN', slug: 'content-admin', name: 'Content admin', where: 'Backoffice', scope: 'All campuses', backoffice: true },
  { role: 'SYSTEM_ADMIN', slug: 'system-admin', name: 'System admin', where: 'Backoffice', scope: 'All campuses', backoffice: true },
];
// Custom roles borrow how people sign in from one of these
const BASES = ['CONTENT_ADMIN', 'SUPER_MENTOR'];
const LOCKED = ['SYSTEM_ADMIN', 'STUDENT', 'ALUMNI', 'MENTOR'];

const users = () => store.where('users', (u) => !u.deletedAt);
const peopleIn = (role) => users().filter((u) => !u.customRoleId && C.roleOf(u) === role).length;

function dto(b) {
  if (b.custom) {
    const r = b.custom;
    return {
      id: r.id, slug: r.id, name: r.name, description: r.description || '', builtIn: false, base: r.base, editable: true, renamable: true, deletable: true,
      edited: true, where: r.base === 'SUPER_MENTOR' ? 'App + Backoffice (limited)' : 'Backoffice', scope: r.base === 'SUPER_MENTOR' ? 'Own caregroup' : 'All campuses',
      people: users().filter((u) => u.customRoleId === r.id).length, matrix: r.matrix,
    };
  }
  const override = P.overrides()[b.role];
  return {
    id: b.role, slug: b.slug, name: b.name, description: DESCRIPTIONS[b.role], builtIn: true, base: b.role, editable: !LOCKED.includes(b.role), renamable: false, deletable: false,
    edited: Boolean(override), where: b.where, scope: b.scope, people: peopleIn(b.role), matrix: override || P.defaultMatrix(b.role),
  };
}
const DESCRIPTIONS = {
  STUDENT: 'Browses content, joins the general caregroup and one specific caregroup, posts, prays, shares testimonies and writes to members.',
  ALUMNI: 'Former student. Reads content and joins conversations. Can be invited later to become a mentor.',
  MENTOR: 'Helps the super-mentor guide a caregroup. Can hide or warn on content reported in the caregroup (level 1).',
  SUPER_MENTOR: 'Leads a caregroup. Welcomes new members, edits meeting details, follows up members, handles level 1 reports and can delete testimonies.',
  CONTENT_ADMIN: 'Creates, validates and publishes content, pathways, badges and announcements. Reviews testimonies.',
  SYSTEM_ADMIN: 'Manages users, roles, caregroups, campuses, settings, data requests and the audit log.',
};

const findRole = (id) => {
  const built = BUILT_IN.find((b) => b.slug === id || b.role === id);
  if (built) return { built };
  const custom = P.customRoles().find((r) => r.id === id);
  if (custom) return { custom };
  throw notFound('Role');
};

router.get('/roles', C.allow(SYS), (_req, res) => {
  res.json(C.list([...BUILT_IN.map((b) => dto({ ...b })), ...P.customRoles().map((custom) => dto({ custom }))], { modules: P.MODULES }));
});
router.get('/roles/:id', C.allow(SYS), (req, res, next) => {
  try { const f = findRole(req.params.id); res.json(dto(f.built ? { ...f.built } : f)); } catch (e) { next(e); }
});

const matrixRule = { type: 'object' };
function cleanName(name, ownId) {
  const n = String(name || '').trim();
  const taken = [...BUILT_IN.map((b) => b.name), ...P.customRoles().filter((r) => r.id !== ownId).map((r) => r.name)].some((x) => x.toLowerCase() === n.toLowerCase());
  if (taken) throw conflict('role_exists', 'A role with this name already exists');
  return n;
}

router.post('/roles', C.allow(SYS), (req, res, next) => {
  try {
    const b = check(req.body, { name: { required: true, type: 'string', min: 2, max: 60 }, description: { type: 'string', max: 400 }, base: { required: true, type: 'string', enum: BASES }, matrix: matrixRule });
    const role = { id: `role_${require('crypto').randomBytes(6).toString('hex')}`, name: cleanName(b.name), description: (b.description || '').trim(), base: b.base, matrix: P.sanitize(b.matrix || {}), createdAt: store.now() };
    P.setSetting(P.KEY_CUSTOM, [...P.customRoles(), role]);
    C.audit(req, 'role_created', role.name);
    res.status(201).json(dto({ custom: role }));
  } catch (e) { next(e); }
});

router.put('/roles/:id', C.allow(SYS), (req, res, next) => {
  try {
    const f = findRole(req.params.id);
    const b = check(req.body, { name: { type: 'string', min: 2, max: 60 }, description: { type: 'string', max: 400 }, matrix: matrixRule });
    if (f.built) {
      if (LOCKED.includes(f.built.role)) throw forbidden('role_locked', `${f.built.name} has fixed permissions`);
      if (b.matrix) P.setSetting(P.KEY_ROLES, { ...P.overrides(), [f.built.role]: P.sanitize(b.matrix) });
      C.audit(req, 'role_updated', f.built.name);
      return res.json(dto({ ...f.built }));
    }
    const list = P.customRoles();
    const r = list.find((x) => x.id === f.custom.id);
    if (b.name) r.name = cleanName(b.name, r.id);
    if (b.description !== undefined) r.description = String(b.description).trim();
    if (b.matrix) r.matrix = P.sanitize(b.matrix);
    P.setSetting(P.KEY_CUSTOM, list);
    C.audit(req, 'role_updated', r.name);
    res.json(dto({ custom: r }));
  } catch (e) { next(e); }
});

// Back to the proposed matrix
router.post('/roles/:id/reset', C.allow(SYS), (req, res, next) => {
  try {
    const f = findRole(req.params.id);
    if (!f.built) throw validation([{ field: 'id', message: 'only built-in roles can be reset' }]);
    const next_ = { ...P.overrides() }; delete next_[f.built.role];
    P.setSetting(P.KEY_ROLES, next_);
    C.audit(req, 'role_updated', `${f.built.name} (reset)`);
    res.json(dto({ ...f.built }));
  } catch (e) { next(e); }
});

router.delete('/roles/:id', C.allow(SYS), (req, res, next) => {
  try {
    const f = findRole(req.params.id);
    if (!f.custom) throw forbidden('role_locked', 'Built-in roles cannot be deleted');
    if (users().some((u) => u.customRoleId === f.custom.id)) throw conflict('role_in_use', 'People still have this role. Change their role first.');
    P.setSetting(P.KEY_CUSTOM, P.customRoles().filter((r) => r.id !== f.custom.id));
    C.audit(req, 'role_deleted', f.custom.name);
    res.status(204).end();
  } catch (e) { next(e); }
});

module.exports = { router };
