const store = require('../db/store');
const config = require('../config');
const realtime = require('../realtime/socket');
const mailer = require('../services/mailer');

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
// Back-office notification rules are keyed by trigger; this is the rule that governs each notification type.
const RULE_OF = {
  request_approved: 'join_request_approved',
  request_declined: 'join_request_declined',
  inactivity: 'inactivity_reminder',
  announcement: 'new_announcement',
  prayed_for_you: 'prayer_received',
};
const DEFAULT_PREFS = { channels: ['inApp', 'email'], muted: ['inactivityReminders'] };

const prefsOf = (userId) => {
  const p = store.first('notificationPrefs', (x) => x.userId === userId);
  return p ? { channels: p.channels, muted: p.muted } : DEFAULT_PREFS;
};

/** Staff can switch a trigger off, or its email channel off, in the back office. No rule yet = the seeded defaults (prayer emails are off). */
function ruleAllowsEmail(type) {
  const key = RULE_OF[type];
  if (!key) return true;
  const rule = store.first('notificationRules', (r) => r.triggerKey === key);
  if (!rule) return key !== 'prayer_received';
  return rule.enabled !== false && !(rule.channels && rule.channels.email === false);
}

/** Emails the notification when the person chose email, unless staff switched it off. Never throws. */
function emailIt(user, type, prefs, category, { title, body }) {
  if (!config.notificationEmails || !user.email || /@invalid$/.test(user.email)) return;
  if (category && !prefs.channels.includes('email')) return; // warnings (no category) are always sent
  if (!ruleAllowsEmail(type)) return;
  mailer.notify(user.email, 'notification', { name: user.fullName || 'there', title, body });
}

/**
 * Tells [userId] about something: an in-app notification (unless they muted its category or turned in-app off) and an
 * email (when they chose email and staff have not switched it off). Moderator warnings always go through.
 * Returns the in-app notification, or null. Never throws: a notification must not break the action that caused it.
 */
function notify(userId, type, { title, body = null, targetRoute }) {
  try {
    if (!userId || !(type in CATEGORY)) return null;
    const user = store.get('users', userId);
    if (!user || user.deletedAt) return null;
    const prefs = prefsOf(userId);
    const category = CATEGORY[type];
    if (category && prefs.muted.includes(category)) return null;
    emailIt(user, type, prefs, category, { title, body });
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
