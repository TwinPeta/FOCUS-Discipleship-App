const store = require('../db/store');
const realtime = require('../realtime/socket');

// Which settings category each notification type belongs to (null = cannot be muted).
const CATEGORY = {
  request_approved: 'joinRequestUpdates',
  request_declined: 'joinRequestUpdates',
  comment_reply: 'replies',
  prayed_for_you: 'prayerResponses',
  prayer_response: 'prayerResponses',
  announcement: 'announcements',
  meeting_reminder: 'meetingReminders',
  inactivity: 'inactivityReminders',
  moderator_warning: null,
};
const DEFAULT_PREFS = { channels: ['inApp', 'email'], muted: ['inactivityReminders'] };

const prefsOf = (userId) => {
  const p = store.first('notificationPrefs', (x) => x.userId === userId);
  return p ? { channels: p.channels, muted: p.muted } : DEFAULT_PREFS;
};

/**
 * Records an in-app notification for [userId] unless they muted its category or turned in-app off
 * (moderator warnings always go through). Never throws: a notification must not break the action that caused it.
 */
function notify(userId, type, { title, body = null, targetRoute }) {
  try {
    if (!userId || !(type in CATEGORY)) return null;
    const user = store.get('users', userId);
    if (!user || user.deletedAt) return null;
    const prefs = prefsOf(userId);
    const category = CATEGORY[type];
    if (category && prefs.muted.includes(category)) return null;
    if (category && !prefs.channels.includes('inApp')) return null;
    const n = store.insert('notifications', { userId, type, title, body, targetRoute, readAt: null });
    realtime.emit(userId, 'notification.created', {
      id: n.id, type: n.type, title: n.title, body: n.body || null, target_route: n.targetRoute, read_at: null, created_at: n.createdAt,
    });
    return n;
  } catch (_e) {
    return null;
  }
}

module.exports = { notify, prefsOf, DEFAULT_PREFS, CATEGORY };
