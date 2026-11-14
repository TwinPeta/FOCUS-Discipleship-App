process.env.NODE_ENV = 'test';
process.env.SEED_DEMO_DATA = 'false';

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('../src/db/seed');
const store = require('../src/db/store');

let server;
let base;
let ctx;

const call = async (method, path, { token, body, headers } = {}) => {
  const res = await fetch(base + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  return { status: res.status, body: text ? JSON.parse(text) : null };
};
const login = async (email) =>
  (await call('POST', '/v1/auth/login', { body: { identifier: email, password: DEMO_PASSWORD } })).body.access_token;

test.before(async () => {
  store.reset();
  ctx = seed();
  server = http.createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());

test('auth: login, wrong password, protected route', async () => {
  assert.equal((await call('GET', '/v1/me')).status, 401);
  const bad = await call('POST', '/v1/auth/login', { body: { identifier: 'student@fcu.test', password: 'nope' } });
  assert.equal(bad.status, 401);
  assert.equal(bad.body.code, 'unauthorized');
  const token = await login('student@fcu.test');
  const me = await call('GET', '/v1/me', { token });
  assert.equal(me.status, 200);
  assert.equal(me.body.username, 'gracen');
  assert.equal(me.body.password_hash, undefined);
});

test('register: validation, minor guardian rule, auto General membership', async () => {
  const inst = store.first('institutions', (i) => i.name === 'Makerere University');
  const base_ = {
    full_name: 'New Student', username: 'newstudent', birthdate: '2004-01-01', country: 'UG',
    email: 'new@fcu.test', institution_type: 'university', institution_id: inst.id,
    password: 'Sup3rSecret!', accepted_terms: true, accepted_code_of_conduct: true,
  };
  const noConduct = await call('POST', '/v1/auth/register', { body: { ...base_, accepted_code_of_conduct: false } });
  assert.equal(noConduct.status, 422);

  const minor = await call('POST', '/v1/auth/register', { body: { ...base_, birthdate: '2012-01-01' } });
  assert.equal(minor.status, 422);
  assert.ok(minor.body.errors.some((e) => e.field === 'guardian'));

  const ok = await call('POST', '/v1/auth/register', { body: base_ });
  assert.equal(ok.status, 201);
  const mine = await call('GET', '/v1/me/communities', { token: ok.body.access_token });
  assert.equal(mine.body.general.membership_status, 'member');
  assert.equal(mine.body.specific, null);

  const dup = await call('POST', '/v1/auth/register', { body: base_ });
  assert.equal(dup.status, 409);
});

test('join flow: one specific community, super-mentor approval, locking', async () => {
  const student = await login('student@fcu.test');
  const sm = await login('super@fcu.test');
  const list = await call('GET', '/v1/communities?type=specific', { token: student });
  assert.equal(list.body.items.length, 3);
  const growth = list.body.items.find((c) => c.name === 'Growth Circle');

  const jr = await call('POST', `/v1/communities/${growth.id}/join-requests`, { token: student });
  assert.equal(jr.status, 201);
  assert.equal(jr.body.status, 'pending');

  const other = list.body.items.find((c) => c.name !== 'Growth Circle');
  const second = await call('POST', `/v1/communities/${other.id}/join-requests`, { token: student });
  assert.equal(second.status, 409);
  assert.equal(second.body.code, 'community_limit_reached');

  const locked = await call('GET', '/v1/communities?type=specific', { token: student });
  assert.ok(locked.body.items.every((c) => c.can_request === false));

  // Student cannot decide their own request; super-mentor can.
  assert.equal((await call('POST', `/v1/join-requests/${jr.body.id}/decision`, { token: student, body: { decision: 'approve' } })).status, 403);
  const pending = await call('GET', `/v1/communities/${growth.id}/join-requests`, { token: sm });
  assert.equal(pending.body.items.length, 1);
  const decided = await call('POST', `/v1/join-requests/${jr.body.id}/decision`, { token: sm, body: { decision: 'approve' } });
  assert.equal(decided.body.status, 'approved');

  const mine = await call('GET', '/v1/me/communities', { token: student });
  assert.equal(mine.body.specific.membership_status, 'member');
  assert.equal((await call('GET', `/v1/communities/${growth.id}/posts`, { token: student })).status, 200);
});

test('non-members cannot read a community feed', async () => {
  const outsider = await call('POST', '/v1/auth/login', { body: { identifier: 'david@fcu.test', password: DEMO_PASSWORD } });
  const lf = store.first('communities', (c) => c.name === 'Life & Faith Circle');
  const res = await call('GET', `/v1/communities/${lf.id}/posts`, { token: outsider.body.access_token });
  assert.equal(res.status, 403);
});

test('feed, like, comment, idempotent post creation', async () => {
  const token = await login('mentor@fcu.test');
  const key = { 'Idempotency-Key': '11111111-1111-4111-8111-111111111111' };
  const a = await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token, body: { text: 'Hello group' }, headers: key });
  const b = await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token, body: { text: 'Hello group' }, headers: key });
  assert.equal(a.status, 201);
  assert.equal(b.body.id, a.body.id);
  const like = await call('PUT', `/v1/posts/${a.body.id}/like`, { token });
  assert.equal(like.body.like_count, 1);
  const again = await call('PUT', `/v1/posts/${a.body.id}/like`, { token });
  assert.equal(again.body.like_count, 1);
  const c = await call('POST', `/v1/posts/${a.body.id}/comments`, { token, body: { text: 'Amen' } });
  assert.equal(c.status, 201);
});

test('prayer: anonymous hides author, "I prayed" is idempotent', async () => {
  const token = await login('mentor@fcu.test');
  const r = await call('POST', `/v1/communities/${ctx.growth.id}/prayer-requests`, { token, body: { text: 'Pray for me', anonymous: true } });
  assert.equal(r.body.author, null);
  const p1 = await call('PUT', `/v1/prayer-requests/${r.body.id}/prayed`, { token });
  const p2 = await call('PUT', `/v1/prayer-requests/${r.body.id}/prayed`, { token });
  assert.equal(p1.body.prayed_count, 1);
  assert.equal(p2.body.prayed_count, 1);
});

test('testimony is always pending_review and consent is required', async () => {
  const token = await login('mentor@fcu.test');
  const noConsent = await call('POST', `/v1/communities/${ctx.growth.id}/testimonies`, { token, body: { title: 't', body: 'b', consent: false } });
  assert.equal(noConsent.status, 422);
  const t = await call('POST', `/v1/communities/${ctx.growth.id}/testimonies`, { token, body: { title: 'My story', body: 'It changed', consent: true } });
  assert.equal(t.status, 201);
  assert.equal(t.body.status, 'pending_review');
  const list = await call('GET', `/v1/communities/${ctx.growth.id}/testimonies`, { token });
  assert.equal(list.body.has_my_pending, true);
  const friend = await login('david@fcu.test');
  const theirs = await call('GET', `/v1/communities/${ctx.growth.id}/testimonies`, { token: friend });
  assert.ok(!theirs.body.items.some((x) => x.id === t.body.id));
});

test('pathways: enroll, step completion, quiz gating, badges', async () => {
  const token = await login('david@fcu.test');
  const list = await call('GET', '/v1/pathways', { token });
  assert.equal(list.body.current, null);
  const first = list.body.items[0];
  assert.equal(list.body.items[2].status, 'locked');
  assert.equal((await call('PUT', `/v1/pathways/${list.body.items[2].id}/enrollment`, { token })).status, 403);

  assert.equal((await call('PUT', `/v1/pathways/${first.id}/enrollment`, { token })).status, 200);
  assert.equal((await call('PUT', `/v1/pathways/${first.id}/enrollment`, { token })).status, 409);
  const detail = await call('GET', `/v1/pathways/${first.id}`, { token });
  const [s1, , s3] = detail.body.steps;
  const done = await call('POST', `/v1/pathways/${first.id}/steps/${s1.id}/complete`, { token });
  assert.equal(done.body.pathway.steps_completed, 1);
  assert.equal(done.body.badges_awarded[0].name, 'First steps');
  assert.equal((await call('POST', `/v1/pathways/${first.id}/steps/${s3.id}/complete`, { token })).status, 422);

  const quiz = await call('GET', `/v1/quizzes/${s3.resource_id}`, { token });
  assert.equal(quiz.body.questions[0].correct, undefined);
  const attempt = await call('POST', `/v1/quizzes/${s3.resource_id}/attempts`, {
    token, body: { answers: quiz.body.questions.map((q) => ({ question_id: q.id, option_id: 'a' })) },
  });
  assert.equal(attempt.body.passed, true);
  const after = await call('GET', `/v1/pathways/${first.id}`, { token });
  assert.equal(after.body.steps_completed, 2);
});

test('resources filter by type and search', async () => {
  const token = await login('mentor@fcu.test');
  const vids = await call('GET', `/v1/communities/${ctx.growth.id}/resources?type=video`, { token });
  assert.ok(vids.body.items.length >= 2 && vids.body.items.every((r) => r.type === 'video'));
  const q = await call('GET', `/v1/communities/${ctx.growth.id}/resources?q=daniel`, { token });
  assert.equal(q.body.items.length, 1);
});

test('messages: send, unread, filters, block', async () => {
  const student = await login('student@fcu.test');
  const sm = await login('super@fcu.test');
  const conv = await call('POST', '/v1/conversations', { token: student, body: { user_id: ctx.superMentor.id } });
  assert.equal(conv.status, 201);
  const sent = await call('POST', `/v1/conversations/${conv.body.id}/messages`, { token: student, body: { text: 'Hi mentor' } });
  assert.equal(sent.status, 201);
  const inbox = await call('GET', '/v1/conversations', { token: sm });
  assert.equal(inbox.body.unread_total, 1);
  await call('POST', `/v1/conversations/${conv.body.id}/read`, { token: sm });
  assert.equal((await call('GET', '/v1/conversations', { token: sm })).body.unread_total, 0);
  const outsider = await login('david@fcu.test');
  assert.equal((await call('GET', `/v1/conversations/${conv.body.id}/messages`, { token: outsider })).status, 404);

  // report then block
  const rep = await call('POST', '/v1/reports', { token: student, body: { target_type: 'user', target_id: ctx.superMentor.id, reason: 'spam_or_fake_profile' } });
  assert.equal(rep.status, 201);
  assert.equal((await call('PUT', `/v1/users/${ctx.superMentor.id}/block`, { token: student })).status, 204);
  const blocked = await call('POST', `/v1/conversations/${conv.body.id}/messages`, { token: student, body: { text: 'still there?' } });
  assert.equal(blocked.status, 403);
  assert.equal(blocked.body.code, 'blocked');
});

test('minor awaiting consent cannot message unverified adults', async () => {
  const inst = store.first('institutions', (i) => i.name === 'Makerere University');
  const reg = await call('POST', '/v1/auth/register', {
    body: {
      full_name: 'Young One', username: 'youngone', birthdate: '2012-05-05', country: 'UG', email: 'young@fcu.test',
      institution_type: 'university', institution_id: inst.id, password: 'Sup3rSecret!',
      accepted_terms: true, accepted_code_of_conduct: true, guardian: { name: 'Parent', phone: '+256700111222' },
    },
  });
  assert.equal(reg.status, 201);
  assert.equal(reg.body.user.minor_status, 'pending_guardian_consent');
  // David is an unverified adult
  const res = await call('POST', '/v1/conversations', { token: reg.body.access_token, body: { user_id: ctx.friend.id } });
  assert.equal(res.status, 403);
  assert.equal(res.body.code, 'messaging_restricted');
  // A verified mentor is allowed
  const ok = await call('POST', '/v1/conversations', { token: reg.body.access_token, body: { user_id: ctx.mentor.id } });
  assert.equal(ok.status, 201);
});

test('media upload slot rejects bad type and oversize', async () => {
  const token = await login('student@fcu.test');
  assert.equal((await call('POST', '/v1/media', { token, body: { purpose: 'post_photo', content_type: 'application/pdf', size_bytes: 10 } })).status, 422);
  assert.equal((await call('POST', '/v1/media', { token, body: { purpose: 'post_photo', content_type: 'image/png', size_bytes: 99999999 } })).status, 422);
  const ok = await call('POST', '/v1/media', { token, body: { purpose: 'post_photo', content_type: 'image/png', size_bytes: 4 } });
  assert.equal(ok.status, 201);
  const up = await fetch(ok.body.upload_url.replace(/^https?:\/\/[^/]+/, base), { method: 'PUT', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'image/png' }, body: Buffer.from([1, 2, 3, 4]) });
  assert.equal(up.status, 204);
  const get = await fetch(`${base}/uploads/${ok.body.media_id}`);
  assert.equal(get.status, 200);
});

test('error shape and 404', async () => {
  assert.equal((await fetch(`${base}/v1/nope`)).status, 401); // auth wall precedes routing
  const r = await fetch(`${base}/nope`);
  assert.equal(r.status, 404);
  assert.match(r.headers.get('content-type'), /problem\+json/);
});
