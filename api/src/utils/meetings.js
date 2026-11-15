// Weekly meetings are not stored: they are derived from communities.meeting
// ({ weekday: 'tue', start_time: '17:00', timezone, location }). Only RSVPs and check-ins are stored.
const DAYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const OFFSET_MIN = { 'Africa/Kampala': 180, 'Africa/Nairobi': 180, 'Africa/Kigali': 120 };
const WEEK = 7 * 86400000;
const OPENS_BEFORE = 30 * 60000; // check-in opens 30 minutes before the start
const CLOSES_AFTER = 2 * 3600000; // and closes 2 hours after it

const offsetMs = (c) => (OFFSET_MIN[c.meeting?.timezone] ?? 180) * 60000;
const pad = (n) => String(n).padStart(2, '0');
const dateKey = (localMs) => { const d = new Date(localMs); return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`; };

/** UTC start (ms) of the meeting on local date `dateStr`, or null if the community does not meet that day. */
function startOn(c, dateStr) {
  const m = c.meeting;
  if (!m || !m.weekday || !m.start_time) return null;
  const [y, mo, d] = dateStr.split('-').map(Number);
  const [h, min] = m.start_time.split(':').map(Number);
  if ([y, mo, d, h, min].some(Number.isNaN)) return null;
  const local = Date.UTC(y, mo - 1, d, h, min);
  if (DAYS[new Date(local).getUTCDay()] !== m.weekday) return null;
  return local - offsetMs(c);
}

const meetingId = (c, localMs) => `${c.id}@${dateKey(localMs)}`;

/** { next, past[] } as { id, startsAt (ms UTC) } records, relative to nowMs. `next` stays current while check-in is open. */
function schedule(c, nowMs, pastCount = 3) {
  const m = c.meeting;
  const target = m && DAYS.indexOf(m.weekday);
  if (!m || target < 0 || !m.start_time) return { next: null, past: [] };
  const off = offsetMs(c);
  const localNow = new Date(nowMs + off);
  const back = (localNow.getUTCDay() - target + 7) % 7;
  const day = Date.UTC(localNow.getUTCFullYear(), localNow.getUTCMonth(), localNow.getUTCDate()) - back * 86400000;
  let start = startOn(c, dateKey(day));
  while (nowMs > start + CLOSES_AFTER) start += WEEK;
  const rec = (utc) => ({ id: meetingId(c, utc + off), startsAt: utc });
  return { next: rec(start), past: Array.from({ length: pastCount }, (_, i) => rec(start - WEEK * (i + 1))) };
}

/** Resolves "communityId@YYYY-MM-DD" to { community, startsAt } or null. */
function resolve(store, id) {
  const [communityId, date] = String(id).split('@');
  const c = communityId && store.get('communities', communityId);
  const startsAt = c && /^\d{4}-\d{2}-\d{2}$/.test(date || '') ? startOn(c, date) : null;
  return startsAt ? { community: c, startsAt } : null;
}

const windowOpen = (startsAt, nowMs) => nowMs >= startsAt - OPENS_BEFORE && nowMs <= startsAt + CLOSES_AFTER;

module.exports = { schedule, resolve, windowOpen, startOn };
