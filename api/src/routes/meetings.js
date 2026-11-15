const router = require('express').Router();
const store = require('../db/store');
const { check } = require('../utils/validate');
const { notFound, conflict, ApiError } = require('../utils/errors');
const { requireMember } = require('../middleware/auth');
const { logEvent } = require('../utils/activity');
const M = require('../utils/meetings');

const dto = (c, rec, userId) => {
  const mine = store.first('meetingAttendance', (a) => a.userId === userId && a.meetingId === rec.id);
  return {
    id: rec.id, community_id: c.id, starts_at: new Date(rec.startsAt).toISOString(), room: c.meeting?.location || '',
    going: !!mine?.going, attended: !!mine?.attendedAt,
  };
};

router.get('/communities/:communityId/meetings', requireMember, (req, res) => {
  const c = req.community;
  const asked = Date.parse(req.query.now);
  // `now` lets the app and tests ask "as of" a moment; a client clock can never grant a check-in (see below).
  const { next, past } = M.schedule(c, Number.isNaN(asked) ? Date.now() : asked);
  res.json({ next: next && dto(c, next, req.user.id), past: past.map((r) => dto(c, r, req.user.id)) });
});

function loadMeeting(req, _res, next) {
  const r = M.resolve(store, req.params.meetingId);
  const member = r && store.first('memberships', (m) => m.communityId === r.community.id && m.userId === req.user.id && m.status === 'member');
  if (!r || !member) return next(notFound('Meeting'));
  req.meeting = { id: req.params.meetingId, community: r.community, startsAt: r.startsAt };
  next();
}

function record(req) {
  return store.first('meetingAttendance', (a) => a.userId === req.user.id && a.meetingId === req.meeting.id) ||
    store.insert('meetingAttendance', { userId: req.user.id, communityId: req.meeting.community.id, meetingId: req.meeting.id, going: false, attendedAt: null });
}

router.put('/meetings/:meetingId/going', loadMeeting, (req, res, next) => {
  try {
    const b = check(req.body, { going: { required: true, type: 'boolean' } });
    record(req).going = b.going;
    res.json(dto(req.meeting.community, { id: req.meeting.id, startsAt: req.meeting.startsAt }, req.user.id));
  } catch (e) { next(e); }
});

router.post('/meetings/:meetingId/check-in', loadMeeting, (req, res, next) => {
  try {
    const rec = record(req);
    if (rec.attendedAt) throw conflict('already_checked_in', 'You already checked in to this meeting');
    // The server clock decides: check-in is open from 30 minutes before the start to 2 hours after.
    if (!M.windowOpen(req.meeting.startsAt, Date.now())) throw new ApiError(409, 'check_in_closed', 'Conflict', 'Check-in is not open for this meeting');
    rec.attendedAt = store.now();
    logEvent(req.user.id, 'meeting_attended', `Checked in to ${req.meeting.community.name}`);
    res.json(dto(req.meeting.community, { id: req.meeting.id, startsAt: req.meeting.startsAt }, req.user.id));
  } catch (e) { next(e); }
});

module.exports = router;
