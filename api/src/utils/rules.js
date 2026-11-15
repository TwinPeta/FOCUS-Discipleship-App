// Staff-editable notification rules (back office > Notifications): which events notify people, through which channels,
// and the wording. This module owns the defaults and the wording, so what staff edit is what people receive.
const store = require('../db/store');

// [trigger, label, who gets it, title, message]. Placeholders are the ones the back-office editor offers:
// {{member_name}} {{community_name}} {{item_title}} {{message_preview}}
const RULE_SEED = [
  ['join_request_approved', 'Join request approved', 'Student', 'Welcome to {{community_name}}', 'Your request was approved. See you at the next meeting!'],
  ['join_request_declined', 'Join request declined', 'Student', 'About your join request', 'Your request to join {{community_name}} could not be approved.'],
  ['inactivity_reminder', 'Inactivity reminder', 'Student', 'We miss you', 'It has been a while, {{member_name}}. Come back and continue your journey.'],
  ['new_announcement', 'New announcement', 'Student', '{{item_title}}', '{{message_preview}}'],
  ['prayer_received', 'Prayer received', 'Student', 'Someone prayed for you', 'A member of your community prayed for your request.'],
  ['report_received', 'Report received', 'Staff', 'New report to review', 'A report ({{item_title}}) was filed in {{community_name}}.'],
  ['testimony_published', 'Testimony published', 'Student', 'Your story is live', 'Your testimony was approved and published in {{community_name}}.'],
];

// Wording saved before the editor and the seed agreed on names keeps working.
const ALIASES = { community: 'community_name', title: 'item_title', message: 'message_preview', name: 'member_name' };

function ensureRules() {
  if (store.col('notificationRules').length) return;
  RULE_SEED.forEach(([triggerKey, triggerLabel, recipient, title, message]) => store.insert('notificationRules', {
    triggerKey, triggerLabel, recipient, channels: { inApp: true, email: triggerKey !== 'prayer_received', sms: false },
    enabled: true, template: { title, message }, updatedAt: store.now(),
  }));
}

/** The rule for a trigger (created from the defaults on first use), or null for a trigger without one. */
function ruleOf(triggerKey) {
  if (!triggerKey) return null;
  ensureRules();
  return store.first('notificationRules', (r) => r.triggerKey === triggerKey) || null;
}

/** Fills {{placeholders}}; unknown or missing ones become empty so a template never shows raw braces. */
function render(text, vars = {}) {
  return String(text || '').replace(/\{\{\s*(\w+)\s*\}\}/g, (_m, k) => {
    const v = vars[k] ?? vars[ALIASES[k]];
    return v === undefined || v === null ? '' : String(v);
  }).replace(/[ \t]{2,}/g, ' ').trim();
}

module.exports = { RULE_SEED, ensureRules, ruleOf, render };
