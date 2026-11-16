process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const store = require('../src/db/store');
const mailer = require('../src/services/mailer');
const { createApp } = require('../src/app');
const { seed } = require('./helpers/seed');

const OLD = 'Password123!'; // the fixture password
const NEW = 'A-brand-new-pass-1';
let server;
let base;
const post = (path, body) => fetch(base + path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
const login = (password) => post('/v1/auth/login', { identifier: 'student@fcu.test', password });

/** Asks for a reset code and reads it from the email that was "sent". */
async function codeFor(email) {
  mailer.outbox.length = 0;
  assert.equal((await post('/v1/auth/otp/request', { channel: 'email', destination: email, purpose: 'password_reset' })).status, 202);
  await new Promise((r) => setTimeout(r, 20));
  return (/(\d{6})/.exec(mailer.outbox[0].subject) || [])[1];
}

test.before(async () => {
  store.reset(); seed();
  server = require('http').createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());

test('a student who forgot their password sets a new one with the emailed code', async () => {
  const before = await (await login(OLD)).json();
  const code = await codeFor('student@fcu.test');
  assert.match(code, /^\d{6}$/);

  const res = await post('/v1/auth/password/reset', { destination: 'Student@FCU.test', code, new_password: NEW });
  assert.equal(res.status, 200);
  const session = await res.json();
  assert.ok(session.access_token && session.refresh_token, 'signed in straight away');
  assert.equal(session.user.email, 'student@fcu.test');

  assert.equal((await login(OLD)).status, 401, 'the old password no longer works');
  assert.equal((await login(NEW)).status, 200, 'the new one does');
  assert.equal((await post('/v1/auth/refresh', { refresh_token: before.refresh_token })).status, 401, 'other devices are signed out');
  assert.equal((await post('/v1/auth/password/reset', { destination: 'student@fcu.test', code, new_password: 'Another-pass-22' })).status, 400, 'a code works once');
});

test('a wrong code, a weak password and an unknown address never change anything', async () => {
  const code = await codeFor('david@fcu.test');
  const wrong = code === '000000' ? '111111' : '000000';
  const bad = await post('/v1/auth/password/reset', { destination: 'david@fcu.test', code: wrong, new_password: NEW });
  assert.equal(bad.status, 400);
  assert.equal((await bad.json()).code, 'otp_invalid');
  assert.equal((await post('/v1/auth/password/reset', { destination: 'david@fcu.test', code, new_password: 'short' })).status, 422);
  assert.equal((await post('/v1/auth/login', { identifier: 'david@fcu.test', password: OLD })).status, 200, 'password unchanged');
  // the real code still works after the failed tries
  assert.equal((await post('/v1/auth/password/reset', { destination: 'david@fcu.test', code, new_password: NEW })).status, 200);

  const ghost = await codeFor('nobody@fcu.test');
  const res = await post('/v1/auth/password/reset', { destination: 'nobody@fcu.test', code: ghost, new_password: NEW });
  assert.equal(res.status, 400, 'same answer as a wrong code: no hint whether the account exists');
});

test('a login code cannot be used to reset a password', async () => {
  mailer.outbox.length = 0;
  await post('/v1/auth/otp/request', { channel: 'email', destination: 'mentor@fcu.test', purpose: 'login' });
  await new Promise((r) => setTimeout(r, 20));
  const code = /(\d{6})/.exec(mailer.outbox[0].subject)[1];
  assert.equal((await post('/v1/auth/password/reset', { destination: 'mentor@fcu.test', code, new_password: NEW })).status, 400);
});
