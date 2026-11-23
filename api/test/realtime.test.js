process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { WebSocket } = require('ws');
const store = require('../src/db/store');
const realtime = require('../src/realtime/socket');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('./helpers/seed');

let server, base, port;

test.before(async () => {
  server = http.createServer(createApp());
  realtime.attach(server);
  await new Promise((r) => server.listen(0, r));
  port = server.address().port;
  base = `http://127.0.0.1:${port}`;
});
test.after(() => server.close());
test.beforeEach(() => { store.reset(); seed(); });

const login = async (email) => {
  const res = await fetch(`${base}/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier: email, password: DEMO_PASSWORD }),
  });
  return (await res.json()).access_token;
};

/** Opens the socket; the client closes it once open. Resolves when closed. */
const connect = (url, protocols) => new Promise((resolve) => {
  const ws = new WebSocket(url, protocols);
  let opened = false;
  let protocol;
  ws.on('open', () => { opened = true; protocol = ws.protocol; setTimeout(() => ws.close(1000), 50); });
  ws.on('close', (code) => resolve({ opened, protocol, code }));
  ws.on('error', () => {});
});

test('the token travels as a subprotocol, not in the URL', async () => {
  const token = await login('student@fcu.test');
  const result = await connect(`ws://127.0.0.1:${port}/v1/realtime`, ['fcu.bearer', token]);
  assert.equal(result.opened, true);
  assert.equal(result.protocol, 'fcu.bearer', 'the token itself is never echoed back');
});

test('older apps: ?token= still works', async () => {
  const token = await login('student@fcu.test');
  const result = await connect(`ws://127.0.0.1:${port}/v1/realtime?token=${token}`);
  assert.equal(result.opened, true);
  assert.equal(result.code, 1000);
});

test('a bad token is refused with 4401', async () => {
  const result = await connect(`ws://127.0.0.1:${port}/v1/realtime`, ['fcu.bearer', 'not.a.jwt']);
  assert.equal(result.code, 4401);
});
