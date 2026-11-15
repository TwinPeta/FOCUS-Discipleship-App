// Announcements reach people: when one is published (now, or when its scheduled time arrives) every person in its
// audience gets a notification, and an email if they chose email. `delivered` makes sure it happens once.
const store = require('../db/store');
const { notify } = require('./notify');

const STAFF_ROLES = ['system_admin', 'content_admin'];

function recipients(a) {
  if (a.audienceType === 'community') {
    const ids = new Set(store.where('memberships', (m) => m.communityId === a.communityId && m.status === 'member').map((m) => m.userId));
    return store.where('users', (u) => ids.has(u.id) && !u.deletedAt);
  }
  return store.where('users', (u) => !u.deletedAt && !STAFF_ROLES.includes(u.platformRole));
}

/** Notifies the audience of a published announcement, once. Returns how many people were told. */
function deliver(a) {
  if (a.delivered || a.status !== 'published') return 0;
  a.delivered = true;
  const people = recipients(a);
  const community = a.audienceType === 'community' ? (store.get('communities', a.communityId) || {}).name : 'All communities';
  const vars = { community_name: community, item_title: a.title, message_preview: String(a.message || '').slice(0, 140) };
  for (const u of people) {
    notify(u.id, 'announcement', { title: a.title, body: vars.message_preview, targetRoute: '/notifications', vars });
  }
  return people.length;
}

/** Publishes scheduled announcements whose time has come and delivers anything published but not yet delivered. */
function publishDue() {
  // Announcements published before delivery existed are history: never send those out now.
  if (!store.first('settings', (s) => s.key === 'announcementDeliveryStart')) {
    store.insert('settings', { key: 'announcementDeliveryStart', value: store.now() });
    store.col('announcements').forEach((a) => { if (a.status === 'published' && a.delivered === undefined) a.delivered = true; });
  }
  store.col('announcements').forEach((a) => {
    if (a.status === 'scheduled' && Date.parse(a.scheduledFor) <= Date.now()) a.status = 'published';
    if (a.status === 'published' && !a.delivered) deliver(a);
  });
}

module.exports = { deliver, publishDue, recipients };
