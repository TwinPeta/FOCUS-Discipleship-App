const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, forbidden, validation } = require('../utils/errors');
const { paginate } = require('../utils/pagination');
const { idempotency } = require('../middleware/idempotency');
const realtime = require('../realtime/socket');
const S = require('../utils/serialize');

const other = (conv, me) => conv.userIds.find((id) => id !== me);
const lastMessage = (convId) =>
  store.where('messages', (m) => m.conversationId === convId).sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1))[0] || null;

const isBlocked = (a, b) =>
  !!store.first('blocks', (x) => (x.blockerId === a && x.blockedId === b) || (x.blockerId === b && x.blockedId === a));

// Minors awaiting guardian consent can only talk to other minors or verified mentors (BRD s.7).
function assertCanMessage(meId, otherId) {
  const me = store.get('users', meId);
  const them = store.get('users', otherId);
  if (!them || them.deletedAt) throw notFound('User');
  if (isBlocked(meId, otherId)) throw forbidden('blocked', 'You cannot message this user');
  const restricted = (minor, adult) =>
    minor.minorStatus === 'pending_guardian_consent' && adult.minorStatus === 'adult' && !adult.verifiedMentor;
  if (restricted(me, them) || restricted(them, me))
    throw forbidden('messaging_restricted', 'Messaging is restricted until guardian consent is confirmed');
}

// "Mentors" tab: the other person is a mentor/super-mentor in a community I belong to.
function isMentorFor(meId, otherId) {
  const mine = store.where('memberships', (m) => m.userId === meId && m.status === 'member').map((m) => m.communityId);
  return store.where('memberships', (m) => m.userId === otherId && m.status === 'member' &&
    m.role !== 'member' && mine.includes(m.communityId)).length > 0;
}

function summary(conv, meId) {
  const oid = other(conv, meId);
  const last = lastMessage(conv.id);
  const mentor = isMentorFor(meId, oid);
  return {
    id: conv.id,
    participant: S.userRef(store.get('users', oid)),
    kind: mentor ? 'mentor' : 'member',
    last_message: last ? last.text : '',
    last_message_at: last ? last.createdAt : conv.createdAt,
    unread_count: store.where('messages', (m) => m.conversationId === conv.id && m.senderId !== meId && !m.readAt).length,
  };
}

function loadConv(req, _res, next) {
  const c = store.get('conversations', req.params.conversationId);
  if (!c || !c.userIds.includes(req.user.id)) return next(notFound('Conversation'));
  req.conv = c;
  next();
}

router.get('/conversations', (req, res) => {
  const filter = req.query.filter || 'all';
  const q = req.query.q ? String(req.query.q).toLowerCase() : null;
  let items = store.where('conversations', (c) => c.userIds.includes(req.user.id) && !isBlocked(req.user.id, other(c, req.user.id)))
    .map((c) => summary(c, req.user.id));
  if (filter === 'mentors') items = items.filter((c) => c.kind === 'mentor');
  if (filter === 'members') items = items.filter((c) => c.kind !== 'mentor');
  if (q) items = items.filter((c) => c.participant.full_name.toLowerCase().includes(q) ||
    c.participant.username.includes(q) || c.last_message.toLowerCase().includes(q));
  items.sort((a, b) => (a.last_message_at < b.last_message_at ? 1 : -1));
  const unread = items.reduce((n, c) => n + c.unread_count, 0);
  const page = paginate(items, req.query);
  res.json({ unread_total: unread, items: page.items, next_cursor: page.next_cursor });
});

router.post('/conversations', (req, res, next) => {
  try {
    const b = check(req.body, { user_id: { required: true, type: 'string' } });
    if (b.user_id === req.user.id) throw validation([{ field: 'user_id', message: 'cannot message yourself' }]);
    assertCanMessage(req.user.id, b.user_id);
    let conv = store.first('conversations', (c) => c.userIds.includes(req.user.id) && c.userIds.includes(b.user_id));
    const created = !conv;
    if (!conv) conv = store.insert('conversations', { userIds: [req.user.id, b.user_id] });
    res.status(created ? 201 : 200).json(summary(conv, req.user.id));
  } catch (e) { next(e); }
});

router.get('/conversations/:conversationId/messages', loadConv, (req, res) => {
  const msgs = store.where('messages', (m) => m.conversationId === req.conv.id)
    .sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  const page = paginate(msgs, req.query);
  res.json({
    participant: S.userRef(store.get('users', other(req.conv, req.user.id))),
    items: page.items.map(S.message),
    next_cursor: page.next_cursor,
  });
});

router.post('/conversations/:conversationId/messages', loadConv, idempotency, (req, res, next) => {
  try {
    const b = check(req.body, { text: { required: true, type: 'string', min: 1, max: 4000 } });
    const oid = other(req.conv, req.user.id);
    assertCanMessage(req.user.id, oid);
    const m = store.insert('messages', { conversationId: req.conv.id, senderId: req.user.id, text: b.text.trim(), readAt: null });
    const dto = S.message(m);
    realtime.emit(oid, 'message.created', dto);
    res.status(201).json(dto);
  } catch (e) { next(e); }
});

router.post('/conversations/:conversationId/read', loadConv, (req, res) => {
  const upTo = req.body && req.body.up_to_message_id ? store.get('messages', req.body.up_to_message_id) : null;
  const t = store.now();
  store.where('messages', (m) => m.conversationId === req.conv.id && m.senderId !== req.user.id && !m.readAt &&
    (!upTo || m.createdAt <= upTo.createdAt)).forEach((m) => { m.readAt = t; });
  realtime.emit(other(req.conv, req.user.id), 'message.read', { conversation_id: req.conv.id, read_at: t });
  res.status(204).end();
});

module.exports = router;
