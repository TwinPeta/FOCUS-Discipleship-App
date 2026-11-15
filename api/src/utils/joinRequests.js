// Deciding a join request. Every way of doing it (the app's super-mentor screen, the back office list, bulk approve and
// the super-mentor's own home) goes through here, so the student always ends up in the same state and always hears about it.
const store = require('../db/store');
const { conflict } = require('./errors');
const { notify } = require('./notify');
const realtime = require('../realtime/socket');

/**
 * Approves or declines [j]. Throws a 409 when it was already decided (`not_pending`) or when approving would put the
 * student in a second specific community (`community_limit_reached`); in both cases nothing changes.
 * On success: the membership is created or confirmed (or the pending one removed), and the student is told in-app, by email
 * (if they chose it), on their phone, and over the live connection.
 */
function decide(j, { approve, by = null, note = null }) {
  if (j.status !== 'pending') throw conflict('not_pending', 'This request was already decided');
  if (approve) {
    const other = store.first('memberships', (m) => m.userId === j.userId && m.status === 'member' && m.communityId !== j.communityId
      && (store.get('communities', m.communityId) || {}).type === 'specific');
    if (other) throw conflict('community_limit_reached', `This student already belongs to ${(store.get('communities', other.communityId) || {}).name || 'another community'}`);
  }

  j.status = approve ? 'approved' : 'rejected';
  j.decidedAt = store.now();
  j.decidedBy = by;
  j.note = note || null;

  const existing = store.first('memberships', (m) => m.userId === j.userId && m.communityId === j.communityId);
  if (approve) {
    if (existing) { existing.status = 'member'; existing.joinedAt = existing.joinedAt || store.now(); }
    else store.insert('memberships', { communityId: j.communityId, userId: j.userId, role: 'member', status: 'member', joinedAt: store.now() });
  } else {
    store.remove('memberships', (m) => m.userId === j.userId && m.communityId === j.communityId && m.status === 'pending');
  }

  notify(j.userId, approve ? 'request_approved' : 'request_declined', {
    title: approve ? 'Your request was approved' : 'Your request was not accepted',
    detail: approve ? null : j.note,
    targetRoute: approve ? '/request/approved' : '/request/declined',
    vars: { community_name: (store.get('communities', j.communityId) || {}).name },
  });
  try { realtime.emit(j.userId, 'join_request.decided', { request_id: j.id, community_id: j.communityId, status: j.status }); } catch { /* live updates are optional */ }
  return j;
}

module.exports = { decide };
