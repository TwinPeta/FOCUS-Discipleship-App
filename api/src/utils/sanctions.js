const store = require('../db/store');

const DEFAULT_SUSPENSION_DAYS = 7;
const DAY = 86400000;

/** When a suspension ends (ISO). Older ones without an end date run DEFAULT_SUSPENSION_DAYS from when they were issued. */
const suspensionEnd = (s) => s.until || new Date(Date.parse(s.issuedAt) + DEFAULT_SUSPENSION_DAYS * DAY).toISOString();

/** The user's current suspension, or null. Lifts it (and the suspended flag) once it has ended. */
function activeSuspension(user, nowMs = Date.now()) {
  const list = store.where('sanctions', (s) => s.userId === user.id && s.type === 'SUSPENSION' && s.active);
  for (const s of list) if (Date.parse(suspensionEnd(s)) <= nowMs) s.active = false;
  const live = list.filter((s) => s.active).sort((a, b) => (a.issuedAt < b.issuedAt ? 1 : -1))[0] || null;
  if (!live && user.suspended) user.suspended = false;
  return live;
}

module.exports = { activeSuspension, suspensionEnd, DEFAULT_SUSPENSION_DAYS };
