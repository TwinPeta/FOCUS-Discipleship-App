const store = require('../db/store');
const config = require('../config');
const realtime = require('../realtime/socket');
const mailer = require('../services/mailer');
const { ruleOf, render } = require('./rules');

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

/** True when staff have not switched the trigger (or its channel) off. A type without a rule is always allowed. */
function ruleAllows(rule, channel) {
  if (!rule) return true;
  if (rule.enabled === false) return false;
  return !(rule.channels && rule.channels[channel] === false);
}

/** Emails the notification to a person's address. Never throws. */
function emailIt(user, { title, body }) {
  if (!config.notificationEmails || !user.email || /@invalid$/.test(user.email)) return;
  mailer.notify(user.email, 'notification', { name: user.fullName || 'there', title, body });
}

/**
 * Tells [userId] about something: an in-app notification (unless they muted its category or turned in-app off) and an
 * email (when they chose email). Staff rules apply on top: a switched-off trigger or channel sends nothing, and the
 * rule's wording replaces the default when [vars] are given ({{member_name}}, {{community_name}}, ...).
 * Moderator warnings always go through. Pass `email: false` to leave the email to the caller. `detail` is a personal
 * message that is kept after the wording (a mentor's reason for declining).
 * Returns the in-app notification, or null. Never throws: a notification must not break the action that caused it.
 */
function notify(userId, type, { title, body = null, targetRoute, rule: ruleKey, vars, email = true, detail = null }) {
  try {
    if (!userId || !(type in CATEGORY)) return null;
    const user = store.get('users', userId);
    if (!user || user.deletedAt) return null;
    const prefs = prefsOf(userId);
    const category = CATEGORY[type];
    if (category && prefs.muted.includes(category)) return null;

    const rule = ruleOf(ruleKey || RULE_OF[type]);
    if (rule && rule.enabled === false) return null;
    if (rule && vars) {
      const t = render(rule.template && rule.template.title, { member_name: user.fullName, ...vars });
      const m = render(rule.template && rule.template.message, { member_name: user.fullName, ...vars });
      if (t) title = t;
      if (m || t) body = m || null;
    }
    // A person's own words (a mentor's reason for declining) are never replaced by the rule's wording
    if (detail) body = body ? `${body}\n\n${detail}` : detail;

    if (email && ruleAllows(rule, 'email') && (!category || prefs.channels.includes('email'))) emailIt(user, { title, body });
    if ((category && !prefs.channels.includes('inApp')) || !ruleAllows(rule, 'inApp')) return null;
    const n = store.insert('notifications', { userId, type, title, body, targetRoute, readAt: null });
    realtime.emit(userId, 'notification.created', {
      id: n.id, type: n.type, title: n.title, body: n.body || null, target_route: n.targetRoute, read_at: null, created_at: n.createdAt,
    });
    // The phone, when the app is closed: same title/body, and the data the app needs to open the right screen on tap.
    require('../services/push').notifyUser(userId, { title, body, data: { type, target_route: targetRoute || '/notifications', notification_id: n.id } });
    return n;
  } catch (_e) {
    return null;
  }
}

/** Email-only message for staff (they have no in-app inbox), governed by a rule such as "report_received". */
function emailStaff(userIds, ruleKey, vars) {
  try {
    const rule = ruleOf(ruleKey);
    if (!rule || !ruleAllows(rule, 'email')) return 0;
    let sent = 0;
    for (const id of new Set(userIds)) {
      const u = store.get('users', id);
      if (!u || u.deletedAt) continue;
      emailIt(u, { title: render(rule.template.title, { member_name: u.fullName, ...vars }), body: render(rule.template.message, { member_name: u.fullName, ...vars }) });
      sent++;
    }
    return sent;
  } catch (_e) {
    return 0;
  }
}

module.exports = { notify, emailStaff, prefsOf, DEFAULT_PREFS, CATEGORY };
