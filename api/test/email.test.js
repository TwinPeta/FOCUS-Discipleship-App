process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const config = require('../src/config');
const store = require('../src/db/store');
const mailer = require('../src/services/mailer');
const { notify } = require('../src/utils/notify');
const announcements = require('../src/utils/announcements');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('./helpers/seed');

let server, base;
const user = (email) => store.first('users', (u) => u.email === email);
const sent = (to, template) => mailer.outbox.filter((m) => (!to || m.to === to) && (!template || m.template === template));

test.before(async () => {
  server = http.createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());
test.beforeEach(() => { store.reset(); seed(); mailer.outbox.length = 0; config.notificationEmails = true; });

const login = async (email) => {
  const r = await fetch(base + '/v1/admin/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password: DEMO_PASSWORD }) });
  return decodeURIComponent(r.headers.getSetCookie().find((c) => c.startsWith('fcu_access=')).split(';')[0].slice(11));
};
const admin = (token, method, path, body) => fetch(base + '/v1/admin' + path, { method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: body ? JSON.stringify(body) : undefined });

test('a notification is emailed to people who chose email, and respects their choices and the staff rules', () => {
  const s = user('student@fcu.test');
  const tell = (type = 'comment_reply') => notify(s.id, type, { title: 'Someone replied', body: 'Nice post', targetRoute: '/post/1' });

  // default settings: in-app and email
  tell();
  assert.equal(sent('student@fcu.test', 'notification').length, 1);
  assert.equal(sent('student@fcu.test', 'notification')[0].subject, 'Someone replied');
  assert.match(sent('student@fcu.test', 'notification')[0].text, /Nice post/);

  // email switched off in their settings: still in-app, no email
  mailer.outbox.length = 0;
  store.insert('notificationPrefs', { userId: s.id, channels: ['inApp'], muted: [] });
  assert.ok(tell(), 'the in-app notification is still created');
  assert.equal(sent('student@fcu.test').length, 0);

  // email only: no in-app, but the email goes out
  store.first('notificationPrefs', (p) => p.userId === s.id).channels = ['email'];
  assert.equal(tell(), null);
  assert.equal(sent('student@fcu.test').length, 1);

  // muted category: nothing at all
  mailer.outbox.length = 0;
  store.first('notificationPrefs', (p) => p.userId === s.id).muted = ['replies'];
  tell();
  assert.equal(sent().length, 0);
});

test('staff rules: switching a trigger or channel off is honoured, prayer emails are off by default, and a kill switch exists', () => {
  const { ruleOf } = require('../src/utils/rules');
  const s = user('student@fcu.test');
  const approve = () => notify(s.id, 'request_approved', { title: 'Approved', targetRoute: '/x' });

  assert.ok(approve(), 'in-app is created');
  assert.equal(sent('student@fcu.test').length, 1, 'default: email is on');

  mailer.outbox.length = 0;
  const rule = ruleOf('join_request_approved');
  rule.channels.email = false;
  assert.ok(approve(), 'email off: still in-app');
  assert.equal(sent().length, 0);

  rule.channels.email = true; rule.channels.inApp = false;
  assert.equal(approve(), null, 'in-app off: no notification');
  assert.equal(sent().length, 1, 'but the email still goes');

  mailer.outbox.length = 0;
  rule.enabled = false;
  assert.equal(approve(), null);
  assert.equal(sent().length, 0, 'a disabled rule sends nothing at all');

  notify(s.id, 'prayed_for_you', { title: 'Someone prayed for you', targetRoute: '/p' });
  assert.equal(sent().length, 0, 'prayer notifications are not emailed unless staff turn that on');

  rule.enabled = true; rule.channels.inApp = true;
  config.notificationEmails = false;
  approve();
  assert.equal(sent().length, 0, 'NOTIFICATION_EMAILS=false stops all notification emails');
});

test('the wording staff write in a rule is what people receive (placeholders, old tags, and blanks)', () => {
  const { ruleOf } = require('../src/utils/rules');
  const s = user('student@fcu.test');
  const rule = ruleOf('join_request_approved');
  rule.template = { title: 'Hello {{member_name}}, welcome to {{community_name}}', message: 'See you at {{community}}. {{unknown}}' }; // {{community}} is an old tag
  const n = notify(s.id, 'request_approved', { title: 'default', targetRoute: '/x', vars: { community_name: 'Growth Circle' } });
  assert.equal(n.title, 'Hello Grace Namuli, welcome to Growth Circle');
  assert.equal(n.body, 'See you at Growth Circle.');
  const mail = sent('student@fcu.test', 'notification')[0];
  assert.equal(mail.subject, 'Hello Grace Namuli, welcome to Growth Circle');
  assert.match(mail.text, /See you at Growth Circle\./);
  assert.ok(!/\{\{/.test(mail.text), 'no raw braces ever reach a person');
});

test('a student hears the outcome of their testimony review', async () => {
  const token = await login('super@fcu.test');
  const growth = store.first('communities', (c) => c.name === 'Growth Circle');
  const author = user('student@fcu.test');
  const make = () => store.insert('testimonies', { communityId: growth.id, authorId: author.id, title: 'God is faithful', body: 'My story', status: 'pending_review' });
  const review = (t, body) => admin(token, 'POST', `/moderation/testimonies/${t.id}/review`, body);

  let t = make();
  assert.equal((await review(t, { action: 'APPROVE' })).status, 200);
  let mail = sent('student@fcu.test', 'notification');
  assert.equal(mail.length, 1);
  assert.equal(mail[0].subject, 'Your story is live');
  assert.match(mail[0].text, /Growth Circle/);
  assert.ok(store.first('notifications', (n) => n.userId === author.id && n.title === 'Your story is live'));

  mailer.outbox.length = 0;
  t = make();
  assert.equal((await review(t, { action: 'REQUEST_CHANGES', notes: 'Please remove the phone number' })).status, 200);
  mail = sent('student@fcu.test', 'notification');
  assert.equal(mail[0].subject, 'Your story needs a change');
  assert.match(mail[0].text, /remove the phone number/);
});

test('a new report is emailed to the community\'s super-mentor unless staff switch that rule off', async () => {
  const { ruleOf } = require('../src/utils/rules');
  const growth = store.first('communities', (c) => c.name === 'Growth Circle');
  const stu = user('student@fcu.test');
  const post = store.insert('posts', { communityId: growth.id, authorId: user('david@fcu.test').id, text: 'hello', pinned: false, mediaIds: [] });
  const file = async () => {
    const login = await fetch(base + '/v1/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ identifier: stu.email, password: DEMO_PASSWORD }) });
    const { access_token: tok } = await login.json();
    return fetch(base + '/v1/reports', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${tok}`, 'Idempotency-Key': Math.random().toString(36).slice(2) }, body: JSON.stringify({ target_type: 'post', target_id: post.id, reason: 'spam_or_fake_profile' }) });
  };
  assert.equal((await file()).status, 201);
  const mail = sent('super@fcu.test', 'notification');
  assert.equal(mail.length, 1);
  assert.equal(mail[0].subject, 'New report to review');
  assert.match(mail[0].text, /spam or fake profile/);
  assert.match(mail[0].text, /Growth Circle/);
  assert.equal(sent('student@fcu.test').length, 0, 'the reporter is not emailed');

  mailer.outbox.length = 0;
  ruleOf('report_received').channels.email = false;
  assert.equal((await file()).status, 201);
  assert.equal(sent().length, 0);
});

test('inactive members get one "we miss you" per period, only if they opted in', () => {
  const inactivity = require('../src/utils/inactivity');
  const s = user('student@fcu.test');
  const old = new Date(Date.now() - 20 * 864e5).toISOString();
  const away = () => { store.col('users').forEach((u) => { u.lastActiveAt = u.platformRole === 'system_admin' ? new Date().toISOString() : old; }); store.col('events').length = 0; };

  away();
  assert.equal(inactivity.run(), 0, 'inactivity reminders are muted by default: nobody is told');
  assert.equal(sent().length, 0);

  store.col('users').forEach((u) => { delete u.lastInactivityNoticeAt; });
  store.insert('notificationPrefs', { userId: s.id, channels: ['inApp', 'email'], muted: [] });
  assert.equal(inactivity.run(), 1, 'the one person who opted in');
  assert.equal(sent('student@fcu.test', 'notification')[0].subject, 'We miss you');
  assert.ok(store.first('notifications', (n) => n.userId === s.id && n.type === 'inactivity'));
  assert.equal(inactivity.run(), 0, 'not again within the same period');

  // someone active recently is left alone; the staff-set threshold is respected
  store.col('users').forEach((u) => { delete u.lastInactivityNoticeAt; });
  s.lastActiveAt = new Date().toISOString();
  assert.equal(inactivity.run(), 0);
  s.lastActiveAt = new Date(Date.now() - 5 * 864e5).toISOString();
  store.insert('settings', { key: 'inactivityDays', value: 3 });
  assert.equal(inactivity.run(), 1);
});

test('a moderator warning is emailed even if the person turned email off', () => {
  const s = user('student@fcu.test');
  store.insert('notificationPrefs', { userId: s.id, channels: ['inApp'], muted: [] });
  notify(s.id, 'moderator_warning', { title: 'A moderator sent you a warning', targetRoute: '/w' });
  assert.equal(sent('student@fcu.test', 'notification').length, 1);
});

test('announcements reach their audience once: now, scheduled, and never the history', async () => {
  const token = await login('admin@fcu.test');
  const everyone = announcements.recipients({ audienceType: 'all' }).length;
  assert.ok(everyone >= 4);

  // published now to everyone
  let res = await admin(token, 'POST', '/announcements', { title: 'Welcome back', message: 'Term starts Monday', audienceType: 'all', publishTiming: 'now' });
  assert.equal(res.status, 201);
  assert.equal(sent(null, 'notification').length, everyone);
  assert.equal(store.where('notifications', (n) => n.type === 'announcement').length, everyone);
  assert.ok(!sent().some((m) => m.to === 'admin@fcu.test'), 'staff accounts are not part of "everyone"');

  // to one community: only its members
  mailer.outbox.length = 0;
  const growth = store.first('communities', (c) => c.name === 'Growth Circle');
  const members = store.where('memberships', (m) => m.communityId === growth.id && m.status === 'member').length;
  res = await admin(token, 'POST', '/announcements', { title: 'Circle night', message: 'Tuesday 5pm', audienceType: 'community', communityId: growth.id, publishTiming: 'now' });
  assert.equal(res.status, 201);
  assert.equal(sent(null, 'notification').length, members);

  // scheduled: nothing until its time, then exactly once (even if the sweep runs twice)
  mailer.outbox.length = 0;
  res = await admin(token, 'POST', '/announcements', { title: 'Later', message: 'See you', audienceType: 'all', publishTiming: 'scheduled', scheduledFor: new Date(Date.now() + 3600e3).toISOString() });
  assert.equal(res.status, 201);
  assert.equal(sent().length, 0);
  store.first('announcements', (a) => a.title === 'Later').scheduledFor = new Date(Date.now() - 1000).toISOString();
  announcements.publishDue();
  announcements.publishDue();
  assert.equal(sent(null, 'notification').length, everyone);
  assert.equal(store.first('announcements', (a) => a.title === 'Later').status, 'published');

  // an announcement published before delivery existed is history, not news
  mailer.outbox.length = 0;
  store.remove('settings', (s) => s.key === 'announcementDeliveryStart');
  store.insert('announcements', { title: 'Old', message: 'x', audienceType: 'all', status: 'published', authorName: 'A' });
  announcements.publishDue();
  assert.equal(sent().length, 0);
});

test('a super-mentor message to their community is delivered to its members', async () => {
  const token = await login('super@fcu.test');
  const res = await admin(token, 'POST', '/my-community/announcements', { message: 'Bring a friend on Tuesday' });
  assert.equal(res.status, 201);
  assert.ok(sent(null, 'notification').length >= 2);
  assert.ok(sent(null, 'notification').every((m) => /Bring a friend/.test(m.text)));
});

test('the guardian consent reminder emails the guardian when the app has their address', async () => {
  const token = await login('admin@fcu.test');
  const minor = user('david@fcu.test');
  minor.birthdate = '2012-05-01'; minor.minorStatus = 'pending_guardian_consent';
  minor.guardian = { name: 'Mr Kato', email: 'guardian@example.com' };
  const consent = store.insert('guardianConsents', { userId: minor.id, guardianName: 'Mr Kato', guardianContact: '', status: 'PENDING', updatedAt: store.now() });

  let res = await admin(token, 'POST', `/privacy/guardian-consents/${consent.id}/remind`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { ok: true, emailed: true });
  const mail = sent('guardian@example.com', 'guardianConsent');
  assert.equal(mail.length, 1);
  assert.match(mail[0].subject, /David Kato/);
  assert.match(mail[0].text, /under 18/);

  // phone only: honest answer, nothing sent
  mailer.outbox.length = 0;
  minor.guardian = { name: 'Mr Kato', phone: '+256700000009' };
  res = await admin(token, 'POST', `/privacy/guardian-consents/${consent.id}/remind`);
  assert.deepEqual(await res.json(), { ok: true, emailed: false });
  assert.equal(sent().length, 0);
});

test('delivery tries again on rate limits and server errors, and gives up at once on a bad request', async () => {
  const calls = [];
  const script = (...results) => ({ emails: { send: async (m) => { calls.push(m); const r = results[Math.min(calls.length - 1, results.length - 1)]; if (r instanceof Error) throw r; return r; } } });
  const msg = { from: 'x <x@example.com>', to: 'a@example.com', subject: 's', text: 't', html: '<p>t</p>' };

  mailer.useClient(script({ data: null, error: { message: 'Too many requests', statusCode: 429 } }, { data: null, error: { message: 'oops', statusCode: 500 } }, { data: { id: 'ok-3' }, error: null }));
  assert.deepEqual(await mailer.deliver(msg), { id: 'ok-3' });
  assert.equal(calls.length, 3, 'two failures, then success');

  calls.length = 0;
  mailer.useClient(script({ data: null, error: { message: 'The from domain is not verified', statusCode: 403 } }));
  await assert.rejects(() => mailer.deliver(msg), /not verified/);
  assert.equal(calls.length, 1, 'a 403 will not get better: no retries');

  calls.length = 0;
  mailer.useClient(script(Object.assign(new Error('fetch failed'), {})));
  await assert.rejects(() => mailer.deliver(msg), /fetch failed/);
  assert.equal(calls.length, 4, 'network trouble is retried, then reported');
  mailer.useClient(null);
});

test('production settings that would break emails are reported', () => {
  const ok = { env: 'production', resendApiKey: 're_x', mailFrom: 'FCU <hello@focusuganda.org>', backofficeUrl: 'https://backoffice.focusuganda.org' };
  assert.deepEqual(mailer.configProblems(ok), []);
  assert.equal(mailer.configProblems({ ...ok, resendApiKey: '' }).length, 1);
  assert.match(mailer.configProblems({ ...ok, mailFrom: 'FCU Student Community <no-reply@localhost>' })[0], /MAIL_FROM/);
  assert.match(mailer.configProblems({ ...ok, backofficeUrl: 'http://localhost:3000' })[0], /BACKOFFICE_URL/);
  assert.deepEqual(mailer.configProblems({ env: 'development', resendApiKey: '', mailFrom: 'x@localhost', backofficeUrl: 'http://localhost:3000' }), [], 'only production is checked');
});
