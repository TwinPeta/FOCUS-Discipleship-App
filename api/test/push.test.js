process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const config = require('../src/config');
const store = require('../src/db/store');
const push = require('../src/services/push');
const { notify } = require('../src/utils/notify');
const { seed } = require('./helpers/seed');

const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', { modulusLength: 2048 });
const SA = JSON.stringify({ client_email: 'fcm@fcu-demo.iam.gserviceaccount.com', project_id: 'fcu-demo', private_key: privateKey.export({ type: 'pkcs8', format: 'pem' }) });
const user = (email) => store.first('users', (u) => u.email === email);

test.beforeEach(() => { store.reset(); seed(); push.outbox.length = 0; push.recent.length = 0; config.fcm.serviceAccountJson = ''; push.reset(); });
test.afterEach(() => { config.env = 'test'; config.fcm.serviceAccountJson = ''; push.useFetch(null); push.reset(); });

// A scripted Google + FCM: records every call, answers FCM with whatever the test queues.
function fake(fcmAnswers = []) {
  const calls = { oauth: [], fcm: [] };
  push.useFetch(async (url, init) => {
    if (String(url).includes('oauth2.googleapis.com')) { calls.oauth.push(new URLSearchParams(String(init.body))); return { ok: true, status: 200, json: async () => ({ access_token: 'ya29.test', expires_in: 3600 }) }; }
    calls.fcm.push({ url: String(url), headers: init.headers, body: JSON.parse(init.body) });
    const a = fcmAnswers.shift() || { status: 200, body: { name: 'projects/fcu-demo/messages/1' } };
    return { ok: a.status < 300, status: a.status, json: async () => a.body };
  });
  return calls;
}
const live = () => { config.env = 'development'; config.fcm.serviceAccountJson = SA; push.reset(); };

test('every notification that reaches the inbox is also pushed to the person\'s phones, with what the app needs to open it', async () => {
  const s = user('student@fcu.test');
  store.insert('devices', { userId: s.id, platform: 'android', pushToken: 't-android' });
  store.insert('devices', { userId: s.id, platform: 'ios', pushToken: 't-ios' });
  const n = notify(s.id, 'comment_reply', { title: 'Someone replied', body: 'Nice post', targetRoute: '/post/9' });
  await push.flush();
  assert.equal(push.outbox.length, 2);
  assert.deepEqual(push.outbox.map((p) => p.platform).sort(), ['android', 'ios']);
  assert.deepEqual(push.outbox[0].data, { type: 'comment_reply', target_route: '/post/9', notification_id: n.id });
  assert.equal(push.outbox[0].title, 'Someone replied');

  // no inbox notification (muted, or switched off by staff) = no push; no phone = nothing to push
  push.outbox.length = 0;
  store.insert('notificationPrefs', { userId: s.id, channels: ['inApp', 'email'], muted: ['replies'] });
  notify(s.id, 'comment_reply', { title: 'x', targetRoute: '/x' });
  const f = user('david@fcu.test');
  notify(f.id, 'comment_reply', { title: 'x', targetRoute: '/x' });
  await push.flush();
  assert.equal(push.outbox.length, 0);
});

test('sign-in with the service key is a real RS256 JWT, cached, and the message has the right shape', async () => {
  live();
  const calls = fake();
  const s = user('student@fcu.test');
  store.insert('devices', { userId: s.id, platform: 'android', pushToken: 'tok-a' });
  store.insert('devices', { userId: s.id, platform: 'ios', pushToken: 'tok-i' });
  const out = await push.sendToUser(s.id, { title: 'Hi', body: 'There', data: { type: 'announcement', target_route: '/notifications', n: 5 } });
  assert.deepEqual([out.sent, out.failed], [2, 0]);

  assert.equal(calls.oauth.length, 1, 'one Google sign-in serves both messages');
  const form = calls.oauth[0];
  assert.equal(form.get('grant_type'), 'urn:ietf:params:oauth:grant-type:jwt-bearer');
  const [h, c, sig] = form.get('assertion').split('.');
  assert.deepEqual(JSON.parse(Buffer.from(h, 'base64url')), { alg: 'RS256', typ: 'JWT' });
  const claims = JSON.parse(Buffer.from(c, 'base64url'));
  assert.equal(claims.iss, 'fcm@fcu-demo.iam.gserviceaccount.com');
  assert.equal(claims.scope, 'https://www.googleapis.com/auth/firebase.messaging');
  assert.equal(claims.aud, 'https://oauth2.googleapis.com/token');
  assert.ok(crypto.createVerify('RSA-SHA256').update(`${h}.${c}`).verify(publicKey, Buffer.from(sig, 'base64url')), 'signed with the service key');

  assert.equal(calls.fcm.length, 2);
  assert.equal(calls.fcm[0].url, 'https://fcm.googleapis.com/v1/projects/fcu-demo/messages:send');
  assert.equal(calls.fcm[0].headers.Authorization, 'Bearer ya29.test');
  const m = calls.fcm[0].body.message;
  assert.equal(m.token, 'tok-a');
  assert.deepEqual(m.notification, { title: 'Hi', body: 'There' });
  assert.deepEqual(m.data, { type: 'announcement', target_route: '/notifications', n: '5' }, 'FCM data values are strings');
  assert.equal(m.android.notification.channel_id, 'fcu_general');
});

test('a dead phone is forgotten, rate limits are retried, other refusals are reported', async () => {
  live();
  const s = user('student@fcu.test');
  const dead = store.insert('devices', { userId: s.id, platform: 'android', pushToken: 'tok-dead' });
  const calls = fake([{ status: 404, body: { error: { status: 'NOT_FOUND', message: 'Requested entity was not found.', details: [{ errorCode: 'UNREGISTERED' }] } } }]);
  let out = await push.sendToUser(s.id, { title: 'x', data: {} });
  assert.deepEqual([out.sent, out.failed], [0, 1]);
  assert.ok(!store.get('devices', dead.id), 'the dead token is removed');
  assert.match(push.recent[0].error, /device removed/);

  store.insert('devices', { userId: s.id, platform: 'android', pushToken: 'tok-ok' });
  calls.fcm.length = 0;
  fake([{ status: 429, body: { error: { message: 'quota' } } }, { status: 503, body: {} }, { status: 200, body: {} }]);
  out = await push.sendToUser(s.id, { title: 'x', data: {} });
  assert.equal(out.sent, 1, 'two transient failures, then success');

  const calls3 = fake([{ status: 403, body: { error: { message: 'Permission denied' } } }]);
  out = await push.sendToUser(s.id, { title: 'x', data: {} });
  assert.deepEqual([out.sent, out.failed], [0, 1]);
  assert.equal(calls3.fcm.length, 1, 'a 403 will not get better: no retries');
  assert.ok(store.first('devices', (d) => d.pushToken === 'tok-ok'), 'a refusal is not a dead phone');
});

test('without a key nothing is sent and nothing breaks; a bad key is explained', async () => {
  config.env = 'development';
  const s = user('student@fcu.test');
  store.insert('devices', { userId: s.id, platform: 'android', pushToken: 'tok' });
  const calls = fake();
  assert.equal(push.enabled(), false);
  notify(s.id, 'comment_reply', { title: 'x', targetRoute: '/x' }); // would push; there is no key
  await push.flush();
  assert.equal(calls.fcm.length, 0);
  assert.deepEqual(push.status().devices, { total: 1, android: 1, ios: 0 });

  config.fcm.serviceAccountJson = '{"client_email":"x"}'; push.reset();
  assert.equal(push.enabled(), false, 'an incomplete key does not count as configured');
  config.fcm.serviceAccountJson = SA; config.fcm.enabled = false; push.reset();
  assert.equal(push.enabled(), false, 'PUSH_ENABLED=false switches it off');
  config.fcm.enabled = true;
});
