const crypto = require('crypto');

/**
 * In-memory document store. Each collection is an array of plain objects with an `id`.
 * Data is lost on restart. Swap this module for a real database (PostgreSQL recommended)
 * by keeping the same function names; routes only use these helpers.
 */
const names = [
  'users', 'institutions', 'communities', 'memberships', 'joinRequests',
  'posts', 'likes', 'comments',
  'prayerRequests', 'prayed', 'prayerResponses',
  'testimonies',
  'pathways', 'pathwayProgress',
  'resources', 'resourceProgress', 'quizzes', 'quizAttempts',
  'badges', 'userBadges', 'events',
  'conversations', 'messages', 'notifications', 'notificationPrefs', 'meetingAttendance',
  'reports', 'blocks',
  'media', 'devices', 'refreshTokens', 'otps', 'landingStories',
  // Back-office (staff) collections
  'content', 'adminPathways', 'adminBadges', 'announcements', 'adminStories', 'notificationRules',
  'auditLog', 'sanctions', 'dataRequests', 'guardianConsents', 'reportSchedules', 'staffSessions',
  'resetTokens', 'settings',
];

const db = Object.fromEntries(names.map((n) => [n, []]));

const uid = () => crypto.randomUUID();
const now = () => new Date().toISOString();

const insert = (col, doc) => {
  const row = { id: uid(), createdAt: now(), ...doc };
  db[col].push(row);
  return row;
};
const get = (col, id) => db[col].find((r) => r.id === id) || null;
const where = (col, pred) => db[col].filter(pred);
const first = (col, pred) => db[col].find(pred) || null;
const update = (col, id, patch) => {
  const row = get(col, id);
  if (row) Object.assign(row, patch);
  return row;
};
const remove = (col, pred) => {
  const before = db[col].length;
  db[col] = db[col].filter((r) => !pred(r));
  return before - db[col].length;
};
const reset = () => names.forEach((n) => (db[n] = []));

module.exports = {
  get db() { return db; },
  col: (n) => db[n],
  insert, get, where, first, update, remove, reset, uid, now,
};
