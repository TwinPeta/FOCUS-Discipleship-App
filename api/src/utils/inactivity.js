// Automatic "we miss you": people who have been away for the staff-set number of days (Settings > Notifications) get one
// reminder, then at most one more per period. Their own settings still decide whether it arrives (inactivity reminders
// are muted by default, so this only reaches people who opted in) and so do the staff rule for "inactivity_reminder".
const store = require('../db/store');
const { notify } = require('./notify');

const STAFF_ROLES = ['system_admin', 'content_admin'];
const DAY = 864e5;

function run(now = Date.now()) {
  const setting = store.first('settings', (s) => s.key === 'inactivityDays');
  const days = setting ? Number(setting.value) : 14;
  if (!(days >= 1)) return 0;
  const { lastActive } = require('../admin/core');
  let told = 0;
  for (const u of store.where('users', (x) => !x.deletedAt && !x.suspended && !STAFF_ROLES.includes(x.platformRole))) {
    if (now - Date.parse(lastActive(u)) < days * DAY) continue;
    if (u.lastInactivityNoticeAt && now - Date.parse(u.lastInactivityNoticeAt) < days * DAY) continue;
    u.lastInactivityNoticeAt = new Date(now).toISOString(); // marked even if they muted it, so it is not re-checked every run
    const membership = store.where('memberships', (m) => m.userId === u.id && m.status === 'member').map((m) => store.get('communities', m.communityId)).find((c) => c && c.type === 'specific');
    if (notify(u.id, 'inactivity', {
      title: 'We miss you', body: 'It has been a while. Come back and continue your journey.', targetRoute: '/notifications',
      vars: { community_name: membership ? membership.name : '' },
    })) told++;
  }
  return told;
}

module.exports = { run };
