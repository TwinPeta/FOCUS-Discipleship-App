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

test('staff can switch a trigger (or its email) off, prayer emails are off by default, and a kill switch exists', () => {
  const s = user('student@fcu.test');
  const approve = () => notify(s.id, 'request_approved', { title: 'Approved', targetRoute: '/x' });

  approve();
  assert.equal(sent('student@fcu.test').length, 1, 'no rule yet: the default is to email');

  mailer.outbox.length = 0;
  const rule = store.insert('notificationRules', { triggerKey: 'join_request_approved', enabled: true, channels: { inApp: true, email: false } });
  approve();
  assert.equal(sent().length, 0, 'the rule turns email off');
  rule.channels.email = true; rule.enabled = false;
  approve();
  assert.equal(sent().length, 0, 'a disabled rule sends no email');

  notify(s.id, 'prayed_for_you', { title: 'Someone prayed for you', targetRoute: '/p' });
  assert.equal(sent().length, 0, 'prayer notifications are not emailed unless staff turn that on');

  rule.enabled = true;
  config.notificationEmails = false;
  approve();
  assert.equal(sent().length, 0, 'NOTIFICATION_EMAILS=false stops all notification emails');
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
