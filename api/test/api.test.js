process.env.NODE_ENV = 'test';

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('./helpers/seed');
const store = require('../src/db/store');
const contract = require('./helpers/contract');

// Sign-up fields added with the complete-profile form (home church, year of
// study, national activities); every registration sends them.
const SIGNUP_EXTRAS = {
  year_of_study: 2,
  home_church: { name: 'Watoto Church', location: 'Kampala', pastor: 'Pastor John' },
  accepted_national_activities: true,
};

let server;
let base;
let ctx;
let spec; // the mobile OpenAPI document: every response in this file is checked against it

const call = async (method, path, { token, body, headers } = {}) => {
  const res = await fetch(base + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const out = { status: res.status, body: text ? JSON.parse(text) : null };
  if (spec) contract.check(spec, method, path, out.status, out.body);
  return out;
};
const login = async (email) =>
  (await call('POST', '/v1/auth/login', { body: { identifier: email, password: DEMO_PASSWORD } })).body.access_token;

test.before(async () => {
  spec = await contract.load('openapi.yaml', '/v1');
  store.reset();
  ctx = seed();
  server = http.createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => {
  server.close();
  console.log(`# contract (mobile): ${spec.checked} responses checked; ${contract.unexercised(spec).length} documented operations not called by any test`);
  // Fails the run if any response drifted from docs/api/openapi.yaml.
  assert.deepEqual([...spec.violations], [], `responses that do not match docs/api/openapi.yaml (${spec.checked} checked)`);
});

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
    password: 'Sup3rSecret!', accepted_terms: true, accepted_code_of_conduct: true, ...SIGNUP_EXTRAS,
  };
  const noConduct = await call('POST', '/v1/auth/register', { body: { ...base_, accepted_code_of_conduct: false } });
  assert.equal(noConduct.status, 422);

  const badGuardian = await call('POST', '/v1/auth/register', { body: { ...base_, birthdate: '2012-01-01', guardian: { name: 'P' } } });
  assert.equal(badGuardian.status, 422);
  assert.ok(badGuardian.body.errors.some((e) => e.field === 'guardian'));

  // A minor may register first and add the guardian afterwards; the account is restricted meanwhile.
  const minor = await call('POST', '/v1/auth/register', { body: { ...base_, username: 'minorkid', email: 'minor@fcu.test', birthdate: '2012-01-01' } });
  assert.equal(minor.status, 201);
  assert.equal(minor.body.user.minor_status, 'pending_guardian_consent');
  const tk = minor.body.access_token;
  assert.equal((await call('GET', '/v1/me/guardian', { token: tk })).body.guardian, null);
  assert.equal((await call('PUT', '/v1/me/guardian', { token: tk, body: { name: 'Parent' } })).status, 422);
  assert.equal((await call('PUT', '/v1/me/guardian', { token: tk, body: { name: 'Parent', email: 'minor@fcu.test' } })).status, 422);
  const put = await call('PUT', '/v1/me/guardian', { token: tk, body: { name: 'Parent', relationship: 'Mother', email: 'mum@fcu.test' } });
  assert.equal(put.status, 200);
  assert.equal(put.body.guardian.status, 'pending');
  assert.equal((await call('GET', '/v1/me/guardian', { token: tk })).body.guardian.name, 'Parent');

  const ok = await call('POST', '/v1/auth/register', { body: base_ });
  assert.equal(ok.status, 201);
  const mine = await call('GET', '/v1/me/communities', { token: ok.body.access_token });
  assert.equal(mine.body.general.membership_status, 'member');
  assert.equal(mine.body.specific, null);

  const dup = await call('POST', '/v1/auth/register', { body: base_ });
  assert.equal(dup.status, 409);
});

test('register: home church, year of study, national activities, institutes', async () => {
  const uni = store.first('institutions', (i) => i.name === 'Makerere University');
  const base_ = {
    full_name: 'Profile Student', username: 'profilestudent', birthdate: '2003-03-03', country: 'UG',
    email: 'profile@fcu.test', institution_type: 'university', institution_id: uni.id,
    password: 'Sup3rSecret!', accepted_terms: true, accepted_code_of_conduct: true, ...SIGNUP_EXTRAS,
  };
  const fields = (r) => r.body.errors.map((e) => e.field);

  // The home church may be added later, but when sent it must be complete.
  const later = await call('POST', '/v1/auth/register', { body: { ...base_, username: 'churchlater', email: 'later@fcu.test', home_church: undefined } });
  assert.equal(later.status, 201);
  assert.equal(later.body.user.home_church, null);
  const noPastor = await call('POST', '/v1/auth/register', { body: { ...base_, home_church: { name: 'Watoto', location: 'Kampala', pastor: ' ' } } });
  assert.equal(noPastor.status, 422);
  assert.ok(fields(noPastor).includes('home_church.pastor'));

  const noYear = await call('POST', '/v1/auth/register', { body: { ...base_, year_of_study: undefined } });
  assert.ok(fields(noYear).includes('year_of_study'));
  const badYear = await call('POST', '/v1/auth/register', { body: { ...base_, year_of_study: 1.5 } });
  assert.ok(fields(badYear).includes('year_of_study'));

  const noNational = await call('POST', '/v1/auth/register', { body: { ...base_, accepted_national_activities: false } });
  assert.equal(noNational.status, 422);
  assert.ok(fields(noNational).includes('accepted_national_activities'));

  const ok = await call('POST', '/v1/auth/register', { body: base_ });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.user.year_of_study, 2);
  assert.deepEqual(ok.body.user.home_church, SIGNUP_EXTRAS.home_church);
  assert.equal(ok.body.user.accepted_national_activities, true);

  // The profile can be updated later.
  const tk = ok.body.access_token;
  const upd = await call('PATCH', '/v1/me', { token: tk, body: { year_of_study: 3, home_church: { name: 'New Life', location: 'Gulu', pastor: 'Rev. Okello' } } });
  assert.equal(upd.status, 200);
  assert.equal(upd.body.year_of_study, 3);
  assert.equal(upd.body.home_church.location, 'Gulu');
  assert.equal((await call('PATCH', '/v1/me', { token: tk, body: { home_church: { name: 'X' } } })).status, 422);

  // An institute that is not listed: typed in, added hidden with its General community, reused by the next student.
  const inst = { ...base_, institution_type: 'institute', institution_id: undefined, institution_name: 'Kampala  Technical Institute', year_of_study: undefined };
  const a = await call('POST', '/v1/auth/register', { body: { ...inst, username: 'institutea', email: 'ia@fcu.test' } });
  assert.equal(a.status, 201);
  assert.equal(a.body.user.institution.name, 'Kampala Technical Institute');
  assert.equal(a.body.user.year_of_study, null);
  const mine = await call('GET', '/v1/me/communities', { token: a.body.access_token });
  assert.equal(mine.body.general.membership_status, 'member');
  const b = await call('POST', '/v1/auth/register', { body: { ...inst, username: 'instituteb', email: 'ib@fcu.test', institution_name: 'kampala technical institute' } });
  assert.equal(b.status, 201);
  assert.equal(b.body.user.institution.id, a.body.user.institution.id);
  const listed = await call('GET', '/v1/lookups/institutions?type=institute&country=UG');
  assert.ok(!listed.body.items.some((i) => i.id === a.body.user.institution.id), 'hidden until staff review');

  // A typed name is only for institutes; universities pick from the list.
  const uniTyped = await call('POST', '/v1/auth/register', { body: { ...base_, username: 'unityped', email: 'ut@fcu.test', institution_id: undefined, institution_name: 'Some University' } });
  assert.equal(uniTyped.status, 422);
  assert.ok(fields(uniTyped).includes('institution_id'));
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

test('questions: follow, helpful votes on answers, post search', async () => {
  const asker = await login('david@fcu.test');
  const follower = await login('super@fcu.test');
  const answerer = await login('mentor@fcu.test');
  // Someone outside Growth Circle (an earlier test may have let the student join it).
  const outsider = await login('student@fcu.test');
  const studentId = store.first('users', (u) => u.email === 'student@fcu.test').id;
  const outsiderRows = store.where('memberships', (m) => m.userId === studentId && m.communityId === ctx.growth.id);
  const keep = outsiderRows.map((m) => m.status);
  outsiderRows.forEach((m) => { m.status = 'left'; });
  const followerId = store.first('users', (u) => u.email === 'super@fcu.test').id;
  const askerId = store.first('users', (u) => u.email === 'david@fcu.test').id;
  const q = (await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token: asker, body: { text: 'Where do you find quiet places to pray on campus?', kind: 'question' } })).body;
  assert.equal(q.follower_count, 0);
  assert.equal(q.following, false);

  // Follow (idempotent), and only questions can be followed.
  let f = await call('PUT', `/v1/posts/${q.id}/follow`, { token: follower });
  assert.equal(f.status, 200);
  f = await call('PUT', `/v1/posts/${q.id}/follow`, { token: follower });
  assert.deepEqual(f.body, { follower_count: 1, following: true });
  const plain = (await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token: asker, body: { text: 'Just a plain post' } })).body;
  assert.equal((await call('PUT', `/v1/posts/${plain.id}/follow`, { token: follower })).status, 422);
  assert.equal(plain.following, undefined, 'plain posts carry no follow state');

  // A new answer tells the follower and the asker.
  const before = store.where('notifications', (n) => n.userId === followerId).length;
  const answer = (await call('POST', `/v1/posts/${q.id}/comments`, { token: answerer, body: { text: 'The chapel garden is quiet before 8.' } })).body;
  assert.equal(answer.vote_count, 0);
  const told = store.where('notifications', (n) => n.userId === followerId);
  assert.equal(told.length, before + 1);
  assert.match(told[told.length - 1].title, /question you follow/);
  assert.ok(store.where('notifications', (n) => n.userId === askerId).some((n) => /answered your question/.test(n.title)));

  // Helpful votes: one per member, not on your own answer.
  let v = await call('PUT', `/v1/comments/${answer.id}/vote`, { token: follower });
  assert.deepEqual(v.body, { vote_count: 1, voted_by_me: true });
  v = await call('PUT', `/v1/comments/${answer.id}/vote`, { token: follower });
  assert.equal(v.body.vote_count, 1, 'idempotent');
  assert.equal((await call('PUT', `/v1/comments/${answer.id}/vote`, { token: answerer })).status, 403);
  assert.equal((await call('PUT', `/v1/comments/${answer.id}/vote`, { token: outsider })).status, 404);
  const listed = (await call('GET', `/v1/posts/${q.id}/comments`, { token: follower })).body.items.find((c) => c.id === answer.id);
  assert.equal(listed.vote_count, 1);
  assert.equal(listed.voted_by_me, true);
  v = await call('DELETE', `/v1/comments/${answer.id}/vote`, { token: follower });
  assert.deepEqual(v.body, { vote_count: 0, voted_by_me: false });
  const onPlain = (await call('POST', `/v1/posts/${plain.id}/comments`, { token: answerer, body: { text: 'Nice' } })).body;
  assert.equal((await call('PUT', `/v1/comments/${onPlain.id}/vote`, { token: follower })).status, 422);

  // Unfollow.
  f = await call('DELETE', `/v1/posts/${q.id}/follow`, { token: follower });
  assert.deepEqual(f.body, { follower_count: 0, following: false });

  // Search: members find it by its words; too short is refused; outsiders see nothing.
  const found = await call('GET', '/v1/search/posts?q=QUIET%20places', { token: answerer });
  assert.equal(found.status, 200);
  assert.ok(found.body.items.some((x) => x.id === q.id));
  const onlyQuestions = await call('GET', '/v1/search/posts?q=plain&kind=question', { token: answerer });
  assert.ok(!onlyQuestions.body.items.some((x) => x.id === plain.id));
  assert.equal((await call('GET', '/v1/search/posts?q=a', { token: answerer })).status, 422);
  const outside = await call('GET', '/v1/search/posts?q=quiet%20places', { token: outsider });
  assert.ok(!outside.body.items.some((x) => x.id === q.id));
  outsiderRows.forEach((m, i) => { m.status = keep[i]; });
});

test('posts: questions and anonymous posts (author hidden, still marked as mine)', async () => {
  const token = await login('mentor@fcu.test');
  const other = await login('student@fcu.test');
  const q = await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token, body: { text: 'How do you keep a quiet time?', kind: 'question', anonymous: true } });
  assert.equal(q.status, 201);
  assert.equal(q.body.kind, 'question');
  assert.equal(q.body.anonymous, true);
  assert.equal(q.body.author, null);
  assert.equal(q.body.is_mine, true);
  const seen = await call('GET', `/v1/posts/${q.body.id}`, { token: other });
  assert.equal(seen.body.author, null);
  assert.equal(seen.body.is_mine, false);
  // Moderators can still act: the author is kept on the record.
  assert.ok(store.get('posts', q.body.id).authorId);

  const plain = await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token, body: { text: 'Just a post' } });
  assert.equal(plain.body.kind, 'post');
  assert.equal(plain.body.anonymous, false);
  assert.ok(plain.body.author);

  const questions = await call('GET', `/v1/communities/${ctx.growth.id}/posts?kind=question`, { token: other });
  assert.ok(questions.body.items.length >= 1);
  assert.ok(questions.body.items.every((p) => p.kind === 'question'));
  assert.equal((await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token, body: { text: 'x', kind: 'poll' } })).status, 422);
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
  // "other" needs details (blank does not count); the other reasons and the screenshot are optional.
  const other = (details) => call('POST', '/v1/reports', { token: student, body: { target_type: 'user', target_id: ctx.superMentor.id, reason: 'other', details } });
  assert.equal((await other(undefined)).status, 422);
  assert.equal((await other('   ')).status, 422);
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
      accepted_terms: true, accepted_code_of_conduct: true, ...SIGNUP_EXTRAS, guardian: { name: 'Parent', phone: '+256700111222' },
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
  // Photos are capped at 2 MB (the app compresses to WebP first).
  assert.equal((await call('POST', '/v1/media', { token, body: { purpose: 'post_photo', content_type: 'image/webp', size_bytes: 2 * 1024 * 1024 + 1 } })).status, 422);
  assert.equal((await call('POST', '/v1/media', { token, body: { purpose: 'post_photo', content_type: 'image/webp', size_bytes: 2 * 1024 * 1024 } })).status, 201);
  // Story videos: at most 2 minutes, and the length must be given.
  const video = (seconds) => call('POST', '/v1/media', { token, body: { purpose: 'testimony_video', content_type: 'video/mp4', size_bytes: 1000, duration_seconds: seconds } });
  assert.equal((await video(150)).status, 422);
  assert.equal((await video(undefined)).status, 422);
  assert.equal((await video(95)).status, 201);
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

test('leave a specific community; note is returned on a declined request', async () => {
  const inst = store.first('institutions', (i) => i.name === 'Makerere University');
  const reg = await call('POST', '/v1/auth/register', {
    body: { full_name: 'Leaver One', username: 'leaverone', birthdate: '2001-01-01', country: 'UG', email: 'leaver@fcu.test',
      institution_type: 'university', institution_id: inst.id, password: 'Sup3rSecret!', accepted_terms: true, accepted_code_of_conduct: true, ...SIGNUP_EXTRAS },
  });
  const tk = reg.body.access_token;
  const spec = store.first('communities', (c) => c.type === 'specific' && c.institutionId === inst.id);
  const general = store.first('communities', (c) => c.type === 'general' && c.institutionId === inst.id);
  assert.equal((await call('DELETE', `/v1/communities/${general.id}/membership`, { token: tk })).status, 409);
  const jr = await call('POST', `/v1/communities/${spec.id}/join-requests`, { token: tk });
  assert.equal(jr.status, 201);
  // pending is not a membership yet
  assert.equal((await call('DELETE', `/v1/communities/${spec.id}/membership`, { token: tk })).status, 404);
  const rec = store.get('joinRequests', jr.body.id);
  const m = store.first('memberships', (x) => x.communityId === spec.id && x.userId === rec.userId);
  m.status = 'member';
  assert.equal((await call('DELETE', `/v1/communities/${spec.id}/membership`, { token: tk })).status, 204);
  const mine = await call('GET', '/v1/me/communities', { token: tk });
  assert.equal(mine.body.specific, null);
  assert.ok('note' in jr.body);
});

test('prayer: single request, and the owner replying on an anonymous request stays anonymous', async () => {
  const spec = store.first('communities', (c) => c.type === 'specific');
  const mem = store.first('memberships', (m) => m.communityId === spec.id && m.role === 'member' && m.status === 'member');
  const jwt = require('jsonwebtoken');
  const config = require('../src/config');
  const tk = jwt.sign({ sub: mem.userId }, config.jwtSecret, { expiresIn: 600 });
  const made = await call('POST', `/v1/communities/${spec.id}/prayer-requests`, { token: tk, body: { text: 'Pray for exams', anonymous: true } });
  assert.equal(made.status, 201);
  const one = await call('GET', `/v1/prayer-requests/${made.body.id}`, { token: tk });
  assert.equal(one.status, 200);
  assert.equal(one.body.author, null);
  const reply = await call('POST', `/v1/prayer-requests/${made.body.id}/responses`, { token: tk, body: { text: 'Thank you all' } });
  assert.equal(reply.body.author, null);
  assert.equal(reply.body.anonymous, true);
});

test('members last-active is for the super-mentor only', async () => {
  const spec = store.first('communities', (c) => c.type === 'specific');
  const sm = store.first('memberships', (m) => m.communityId === spec.id && m.role === 'super_mentor' && m.status === 'member');
  const mem = store.first('memberships', (m) => m.communityId === spec.id && m.role === 'member' && m.status === 'member');
  const jwt = require('jsonwebtoken');
  const config = require('../src/config');
  const tok = (id) => jwt.sign({ sub: id }, config.jwtSecret, { expiresIn: 600 });
  assert.equal((await call('GET', `/v1/communities/${spec.id}/members/last-active`, { token: tok(mem.userId) })).status, 403);
  const ok = await call('GET', `/v1/communities/${spec.id}/members/last-active`, { token: tok(sm.userId) });
  assert.equal(ok.status, 200);
  assert.ok(Array.isArray(ok.body.items));
});

test('GET /me/blocks lists who I blocked', async () => {
  const a = store.first('users', (u) => u.email === 'student@fcu.test');
  const b = store.first('users', (u) => u.email === 'david@fcu.test');
  const jwt = require('jsonwebtoken');
  const config = require('../src/config');
  const tk = jwt.sign({ sub: a.id }, config.jwtSecret, { expiresIn: 600 });
  assert.equal((await call('PUT', `/v1/users/${b.id}/block`, { token: tk })).status, 204);
  const list = await call('GET', '/v1/me/blocks', { token: tk });
  assert.equal(list.status, 200);
  assert.ok(list.body.items.some((u) => u.id === b.id));
  await call('DELETE', `/v1/users/${b.id}/block`, { token: tk });
  assert.ok(!(await call('GET', '/v1/me/blocks', { token: tk })).body.items.some((u) => u.id === b.id));
});

test('notifications: created by actions, listed, read, and muted by preferences', async () => {
  const spec = store.first('communities', (c) => c.type === 'specific');
  const post = store.first('posts', (p) => p.communityId === spec.id);
  const author = store.get('users', post.authorId);
  const other = store.first('memberships', (m) => m.communityId === spec.id && m.status === 'member' && m.userId !== post.authorId);
  const jwt = require('jsonwebtoken');
  const config = require('../src/config');
  const tok = (id) => jwt.sign({ sub: id }, config.jwtSecret, { expiresIn: 600 });
  const before = (await call('GET', '/v1/me/notifications', { token: tok(author.id) })).body.items.length;
  const c = await call('POST', `/v1/posts/${post.id}/comments`, { token: tok(other.userId), body: { text: 'Nice one' } });
  assert.equal(c.status, 201);
  const list = await call('GET', '/v1/me/notifications', { token: tok(author.id) });
  assert.equal(list.body.items.length, before + 1);
  const n = list.body.items[0];
  assert.equal(n.type, 'comment_reply');
  assert.equal(n.target_route, `/post/${post.id}`);
  assert.equal((await call('POST', `/v1/me/notifications/${n.id}/read`, { token: tok(author.id) })).status, 204);
  assert.ok((await call('GET', '/v1/me/notifications', { token: tok(author.id) })).body.items.find((x) => x.id === n.id).read_at);
  assert.equal((await call('POST', `/v1/me/notifications/${n.id}/read`, { token: tok(other.userId) })).status, 404);

  assert.deepEqual((await call('GET', '/v1/me/notification-preferences', { token: tok(author.id) })).body.muted, ['inactivityReminders']);
  const put = await call('PUT', '/v1/me/notification-preferences', { token: tok(author.id), body: { channels: ['inApp'], muted: ['replies'] } });
  assert.equal(put.status, 200);
  await call('POST', `/v1/posts/${post.id}/comments`, { token: tok(other.userId), body: { text: 'Again' } });
  assert.equal((await call('GET', '/v1/me/notifications', { token: tok(author.id) })).body.items.length, before + 1);
  assert.equal((await call('PUT', '/v1/me/notification-preferences', { token: tok(author.id), body: { channels: ['sms'], muted: [] } })).status, 422);
  assert.equal((await call('POST', '/v1/me/notifications/read-all', { token: tok(author.id) })).status, 204);
});

const tokenFor = (id) => require('jsonwebtoken').sign({ sub: id }, require('../src/config').jwtSecret, { expiresIn: 600 });

test('meetings: derived schedule, RSVP, and check-in only inside the window', async () => {
  const spec = store.first('communities', (c) => c.type === 'specific' && c.name === 'Growth Circle');
  const mem = store.first('memberships', (m) => m.communityId === spec.id && m.role === 'member' && m.status === 'member');
  const tk = tokenFor(mem.userId);
  // Meet today (Kampala time) in 10 minutes, so check-in is open right now.
  const local = new Date(Date.now() + 3 * 3600000 + 10 * 60000);
  spec.meeting = { ...spec.meeting, weekday: ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'][local.getUTCDay()],
    start_time: `${String(local.getUTCHours()).padStart(2, '0')}:${String(local.getUTCMinutes()).padStart(2, '0')}`, timezone: 'Africa/Kampala' };

  const sched = await call('GET', `/v1/communities/${spec.id}/meetings`, { token: tk });
  assert.equal(sched.status, 200);
  assert.equal(sched.body.past.length, 3);
  const next = sched.body.next;
  assert.ok(Date.parse(next.starts_at) > Date.now());
  assert.equal(next.room, spec.meeting.location);
  assert.equal(next.attended, false);

  const going = await call('PUT', `/v1/meetings/${encodeURIComponent(next.id)}/going`, { token: tk, body: { going: true } });
  assert.equal(going.body.going, true);

  const closed = await call('POST', `/v1/meetings/${encodeURIComponent(sched.body.past[0].id)}/check-in`, { token: tk });
  assert.equal(closed.status, 409);
  assert.equal(closed.body.code, 'check_in_closed');

  const ok = await call('POST', `/v1/meetings/${encodeURIComponent(next.id)}/check-in`, { token: tk });
  assert.equal(ok.status, 200);
  assert.equal(ok.body.attended, true);
  assert.equal((await call('POST', `/v1/meetings/${encodeURIComponent(next.id)}/check-in`, { token: tk })).body.code, 'already_checked_in');

  assert.equal((await call('GET', `/v1/communities/${spec.id}/meetings`, { token: tk })).body.next.attended, true);
  const outsider = store.first('users', (u) => u.email === 'david@fcu.test');
  const notMember = store.first('memberships', (m) => m.communityId === spec.id && m.userId === outsider.id);
  if (!notMember) assert.equal((await call('PUT', `/v1/meetings/${encodeURIComponent(next.id)}/going`, { token: tokenFor(outsider.id), body: { going: true } })).status, 404);
});

test('mentor moderation: reports form a case; warning hides, warns and notifies', async () => {
  const spec = store.first('communities', (c) => c.type === 'specific' && c.name === 'Growth Circle');
  const sm = store.first('memberships', (m) => m.communityId === spec.id && m.role === 'super_mentor' && m.status === 'member');
  const members = store.where('memberships', (m) => m.communityId === spec.id && m.role === 'member' && m.status === 'member');
  const author = members[0].userId;
  const reporterA = members[1] ? members[1].userId : sm.userId;
  const post = store.insert('posts', { communityId: spec.id, authorId: author, text: 'Rude post for the test', pinned: false, mediaIds: [] });

  const report = (uid, reason) => call('POST', '/v1/reports', { token: tokenFor(uid), body: { target_type: 'post', target_id: post.id, reason } });
  assert.equal((await report(reporterA, 'harassment_bullying')).status, 201);
  assert.equal((await report(sm.userId, 'harassment_bullying')).status, 201);

  assert.equal((await call('GET', `/v1/communities/${spec.id}/moderation/cases`, { token: tokenFor(author) })).status, 403);
  const list = await call('GET', `/v1/communities/${spec.id}/moderation/cases`, { token: tokenFor(sm.userId) });
  const c = list.body.items.find((x) => x.target_id === post.id);
  assert.ok(c);
  assert.equal(c.content, 'post');
  assert.equal(c.report_count, 2);
  assert.equal(c.reason, 'harassment_bullying');
  assert.equal(c.author.id, author);

  const act = await call('POST', `/v1/communities/${spec.id}/moderation/cases/${encodeURIComponent(c.id)}/action`, { token: tokenFor(sm.userId), body: { action: 'warn' } });
  assert.equal(act.status, 200);
  assert.equal(act.body.outcome, 'warned');
  assert.equal(store.get('posts', post.id).hidden, true);
  assert.equal((await call('POST', `/v1/communities/${spec.id}/moderation/cases/${encodeURIComponent(c.id)}/action`, { token: tokenFor(sm.userId), body: { action: 'keep' } })).status, 409);

  const warnings = await call('GET', '/v1/me/warnings', { token: tokenFor(author) });
  const w = warnings.body.items.find((x) => x.preview.startsWith('Rude post'));
  assert.ok(w);
  assert.equal(w.acknowledged, false);
  assert.equal((await call('POST', `/v1/me/warnings/${w.id}/acknowledge`, { token: tokenFor(author) })).body.acknowledged, true);
  const notes = await call('GET', '/v1/me/notifications', { token: tokenFor(author) });
  assert.ok(notes.body.items.some((n) => n.type === 'moderator_warning' && n.target_route === `/warning/${w.id}`));
});

test('suspension: read-only while active, lifted when it ends', async () => {
  const u = store.first('users', (x) => x.email === 'david@fcu.test');
  u.suspended = true;
  const s = store.insert('sanctions', { userId: u.id, communityId: null, type: 'SUSPENSION', reason: 'Breaking the rules', issuedBy: 'Admin', issuedAt: store.now(), active: true,
    until: new Date(Date.now() + 3 * 86400000).toISOString() });
  const tk = tokenFor(u.id);
  const sus = await call('GET', '/v1/me/suspension', { token: tk });
  assert.equal(sus.body.suspension.reason, 'Breaking the rules');
  assert.equal(sus.body.suspension.until, s.until);
  assert.equal((await call('GET', '/v1/me', { token: tk })).status, 200);
  const blocked = await call('POST', '/v1/me/notifications/read-all', { token: tk });
  assert.equal(blocked.status, 403);
  assert.equal(blocked.body.code, 'account_suspended');

  s.until = new Date(Date.now() - 1000).toISOString();
  assert.equal((await call('GET', '/v1/me/suspension', { token: tk })).body.suspension, null);
  assert.equal(u.suspended, false);
  assert.equal((await call('POST', '/v1/me/notifications/read-all', { token: tk })).status, 204);
});

// Calls the remaining operations once so their responses are checked against the documented schemas too.
test('personal marks: hide a post from my feed, pass on a question', async () => {
  const me = await login('mentor@fcu.test');
  const other = await login('super@fcu.test');
  const author = await login('david@fcu.test');
  const feed = async (token) => (await call('GET', `/v1/communities/${ctx.growth.id}/posts?limit=100`, { token })).body.items.map((p) => p.id);
  const post = (await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token: author, body: { text: 'A post someone will hide xyzzy' } })).body;

  // Hidden only for the person who hid it (idempotent), in the feed and in search; undone by DELETE.
  assert.equal((await call('PUT', `/v1/posts/${post.id}/hide`, { token: me })).status, 204);
  assert.equal((await call('PUT', `/v1/posts/${post.id}/hide`, { token: me })).status, 204);
  assert.ok(!(await feed(me)).includes(post.id), 'gone from my feed');
  assert.ok((await feed(other)).includes(post.id), 'still in everyone else\'s');
  assert.equal((await call('GET', '/v1/search/posts?q=xyzzy', { token: me })).body.items.length, 0);
  assert.equal((await call('GET', '/v1/search/posts?q=xyzzy', { token: other })).body.items.length, 1);
  assert.equal(store.where('postMarks', (m) => m.postId === post.id).length, 1);
  assert.equal((await call('DELETE', `/v1/posts/${post.id}/hide`, { token: me })).status, 204);
  assert.ok((await feed(me)).includes(post.id), 'back after unhide');

  // Pass: questions only; the question stays in the feed and carries passed_by_me for that person only.
  const q = (await call('POST', `/v1/communities/${ctx.growth.id}/posts`, { token: author, body: { text: 'Who can I talk to about my course?', kind: 'question' } })).body;
  assert.equal(q.passed_by_me, false);
  assert.equal((await call('PUT', `/v1/posts/${post.id}/pass`, { token: me })).status, 422, 'only questions');
  assert.equal((await call('PUT', `/v1/posts/${q.id}/pass`, { token: me })).status, 204);
  assert.equal((await call('GET', `/v1/posts/${q.id}`, { token: me })).body.passed_by_me, true);
  assert.equal((await call('GET', `/v1/posts/${q.id}`, { token: other })).body.passed_by_me, false);
  assert.ok((await feed(me)).includes(q.id), 'a passed question stays in the feed');
  assert.equal((await call('DELETE', `/v1/posts/${q.id}/pass`, { token: me })).status, 204);
  assert.equal((await call('GET', `/v1/posts/${q.id}`, { token: me })).body.passed_by_me, false);

  // Non-members cannot mark; deleting the post removes its marks.
  const outsider = await login('student@fcu.test');
  const studentId = store.first('users', (u) => u.email === 'student@fcu.test').id;
  if (!store.first('memberships', (m) => m.userId === studentId && m.communityId === ctx.growth.id && m.status === 'member')) {
    assert.equal((await call('PUT', `/v1/posts/${post.id}/hide`, { token: outsider })).status, 404);
  }
  await call('PUT', `/v1/posts/${q.id}/pass`, { token: me });
  assert.equal((await call('DELETE', `/v1/posts/${q.id}`, { token: author })).status, 204);
  assert.equal(store.where('postMarks', (m) => m.postId === q.id).length, 0);
});

test('testimonies: "Encouraged" is one per member, on published stories only', async () => {
  const me = await login('mentor@fcu.test');
  const other = await login('super@fcu.test');
  const published = store.first('testimonies', (t) => t.communityId === ctx.growth.id && t.status === 'published');
  assert.ok(published, 'the fixture has a published story');
  const before = (await call('GET', `/v1/testimonies/${published.id}`, { token: me })).body;
  assert.equal(before.encouraged_by_me, false);
  let r = await call('PUT', `/v1/testimonies/${published.id}/encourage`, { token: me });
  assert.equal(r.status, 200);
  r = await call('PUT', `/v1/testimonies/${published.id}/encourage`, { token: me });
  assert.deepEqual(r.body, { encouraged_count: before.encouraged_count + 1, encouraged_by_me: true });
  const seen = (await call('GET', `/v1/communities/${ctx.growth.id}/testimonies`, { token: other })).body.items.find((t) => t.id === published.id);
  assert.equal(seen.encouraged_count, before.encouraged_count + 1);
  assert.equal(seen.encouraged_by_me, false, 'per viewer');
  r = await call('DELETE', `/v1/testimonies/${published.id}/encourage`, { token: me });
  assert.deepEqual(r.body, { encouraged_count: before.encouraged_count, encouraged_by_me: false });

  const pending = (await call('POST', `/v1/communities/${ctx.growth.id}/testimonies`, { token: me, body: { title: 'Not yet', body: 'Waiting', consent: true } })).body;
  assert.equal((await call('PUT', `/v1/testimonies/${pending.id}/encourage`, { token: me })).status, 422);
  assert.equal((await call('PUT', `/v1/testimonies/${pending.id}/encourage`, { token: other })).status, 404, 'others cannot see it');
});

test('resources: a private reflection, and the last quiz attempt with my own answers', async () => {
  const me = await login('mentor@fcu.test');
  const other = await login('super@fcu.test');
  const devotional = store.first('resources', (r) => r.communityId === ctx.growth.id && r.type === 'devotional' && r.status === 'published');
  const empty = await call('GET', `/v1/resources/${devotional.id}/reflection`, { token: me });
  assert.deepEqual(empty.body, { text: '', updated_at: null });
  const saved = await call('PUT', `/v1/resources/${devotional.id}/reflection`, { token: me, body: { text: 'Remain in him.' } });
  assert.equal(saved.status, 200);
  assert.equal(saved.body.text, 'Remain in him.');
  assert.equal((await call('GET', `/v1/resources/${devotional.id}/reflection`, { token: me })).body.text, 'Remain in him.');
  assert.equal((await call('GET', `/v1/resources/${devotional.id}/reflection`, { token: other })).body.text, '', 'private to its author');
  assert.equal((await call('PUT', `/v1/resources/${devotional.id}/reflection`, { token: me, body: { text: 'x'.repeat(5001) } })).status, 422);
  assert.equal((await call('PUT', `/v1/resources/${devotional.id}/reflection`, { token: me, body: {} })).status, 422);
  const cleared = await call('PUT', `/v1/resources/${devotional.id}/reflection`, { token: me, body: { text: '' } });
  assert.equal(cleared.status, 200, 'clearing is allowed');
  assert.equal((await call('GET', `/v1/resources/${devotional.id}/reflection`, { token: me })).body.text, '');
  await call('PUT', `/v1/resources/${devotional.id}/reflection`, { token: me, body: { text: 'Remain in him.' } });
  // Saving a reflection does not mark the devotional done.
  assert.equal(store.first('resourceProgress', (p) => p.resourceId === devotional.id && p.userId === store.first('users', (u) => u.email === 'mentor@fcu.test').id).completed, false);

  const quizRes = store.first('resources', (r) => r.communityId === ctx.growth.id && r.type === 'quiz' && r.status === 'published');
  const fresh = await call('GET', `/v1/quizzes/${quizRes.id}`, { token: other });
  assert.equal(fresh.body.my_last_attempt, null);
  const answers = fresh.body.questions.map((q, i) => ({ question_id: q.id, option_id: q.options[i % q.options.length].id }));
  const scored = (await call('POST', `/v1/quizzes/${quizRes.id}/attempts`, { token: other, body: { answers } })).body;
  const last = (await call('GET', `/v1/quizzes/${quizRes.id}`, { token: other })).body.my_last_attempt;
  assert.equal(last.score, scored.score);
  assert.equal(last.passed, scored.passed);
  assert.deepEqual(last.answers, answers, 'my own choices, as given');
  assert.equal(last.answers[0].correct, undefined, 'never the correct answers');
  assert.equal((await call('GET', `/v1/quizzes/${quizRes.id}`, { token: me })).body.my_last_attempt, null, 'per member');
});

test('refresh: parallel refreshes both work, an old token does not, logout ends it all', async () => {
  const login = await call('POST', '/v1/auth/login', { body: { identifier: 'student@fcu.test', password: DEMO_PASSWORD } });
  assert.equal(login.status, 200);
  const rt = login.body.refresh_token;
  // two tabs refresh with the same token at once
  const [a, b] = await Promise.all([1, 2].map(() => call('POST', '/v1/auth/refresh', { body: { refresh_token: rt } })));
  assert.equal(a.status, 200);
  assert.equal(b.status, 200);
  assert.notEqual(a.body.refresh_token, b.body.refresh_token);
  // the new tokens carry on
  assert.equal((await call('POST', '/v1/auth/refresh', { body: { refresh_token: a.body.refresh_token } })).status, 200);
  // outside the grace window the replaced token is refused
  store.col('refreshTokens').filter((t) => t.usedAt).forEach((t) => { t.usedAt -= 120000; });
  assert.equal((await call('POST', '/v1/auth/refresh', { body: { refresh_token: rt } })).status, 401);
  // logging out also ends the token that was just replaced
  const c = await call('POST', '/v1/auth/login', { body: { identifier: 'student@fcu.test', password: DEMO_PASSWORD } });
  const d = await call('POST', '/v1/auth/refresh', { body: { refresh_token: c.body.refresh_token } });
  assert.equal((await call('POST', '/v1/auth/logout', { token: d.body.access_token, body: { refresh_token: d.body.refresh_token } })).status, 204);
  assert.equal((await call('POST', '/v1/auth/refresh', { body: { refresh_token: c.body.refresh_token } })).status, 401);
});

test('contract sweep: remaining operations return what the spec says', async () => {
  const ok = (r, ...codes) => assert.ok(codes.includes(r.status), `expected ${codes} got ${r.status} ${JSON.stringify(r.body)}`);
  const token = await login('student@fcu.test');
  const t = { token };
  const gid = ctx.growth.id;

  ok(await call('GET', '/v1/health'), 200);
  ok(await call('GET', '/v1/public/landing'), 200);
  ok(await call('GET', '/v1/lookups/countries'), 200);
  const appConfig = await call('GET', '/v1/lookups/app-config');
  ok(appConfig, 200);
  assert.equal(typeof appConfig.body.join_requests.auto_approve, 'boolean');
  ok(await call('GET', '/v1/lookups/institutions?type=university'), 200);
  ok(await call('GET', '/v1/auth/username-available?username=somebody_new'), 200);
  const free = await call('GET', '/v1/auth/email-available?email=brand.new@fcu.test');
  ok(free, 200);
  assert.equal(free.body.available, true);
  const taken = await call('GET', '/v1/auth/email-available?email=Student@FCU.test');
  assert.equal(taken.body.available, false); // case does not matter
  ok(await call('GET', '/v1/auth/email-available?email=not-an-email'), 422);
  ok(await call('POST', '/v1/auth/otp/request', { body: { channel: 'email', destination: 'x@fcu.test', purpose: 'verify_contact' } }), 202);
  ok(await call('POST', '/v1/auth/otp/verify', { body: { destination: 'x@fcu.test', code: '000000', purpose: 'verify_contact' } }), 400);
  ok(await call('POST', '/v1/auth/password/reset', { body: { destination: 'x@fcu.test', code: '000000', new_password: 'A-brand-new-pass-1' } }), 400); // success: password-reset.test.js

  const session = await call('POST', '/v1/auth/login', { body: { identifier: 'david@fcu.test', password: DEMO_PASSWORD } });
  const refreshed = await call('POST', '/v1/auth/refresh', { body: { refresh_token: session.body.refresh_token } });
  ok(refreshed, 200);
  ok(await call('POST', '/v1/auth/logout', { token: refreshed.body.access_token, body: { refresh_token: refreshed.body.refresh_token } }), 204);

  ok(await call('PATCH', '/v1/me', { ...t, body: { full_name: 'Grace Namuli' } }), 200);
  ok(await call('GET', '/v1/me/activity', t), 200);
  ok(await call('GET', '/v1/me/join-requests', t), 200);
  ok(await call('POST', '/v1/me/export', t), 202);

  ok(await call('GET', `/v1/communities/${gid}`, t), 200);
  ok(await call('GET', `/v1/communities/${gid}/members`, t), 200);

  // posts: create, read, edit, like, unlike, comments, delete
  const post = await call('POST', `/v1/communities/${gid}/posts`, { ...t, body: { text: 'Sweep post' } });
  ok(post, 201);
  const pid = post.body.id;
  ok(await call('GET', `/v1/posts/${pid}`, t), 200);
  ok(await call('PATCH', `/v1/posts/${pid}`, { ...t, body: { text: 'Sweep post (edited)' } }), 200);
  ok(await call('PUT', `/v1/posts/${pid}/like`, t), 200);
  ok(await call('DELETE', `/v1/posts/${pid}/like`, t), 200);
  ok(await call('GET', `/v1/posts/${pid}/comments`, t), 200);
  ok(await call('DELETE', `/v1/posts/${pid}`, t), 204);

  // prayer
  const prayer = await call('POST', `/v1/communities/${gid}/prayer-requests`, { ...t, body: { text: 'Sweep prayer' } });
  ok(prayer, 201);
  ok(await call('GET', `/v1/communities/${gid}/prayer-requests`, t), 200);
  ok(await call('GET', `/v1/prayer-requests/${prayer.body.id}/responses`, t), 200);
  ok(await call('PUT', `/v1/prayer-requests/${prayer.body.id}/prayed`, t), 200);
  ok(await call('DELETE', `/v1/prayer-requests/${prayer.body.id}/prayed`, t), 200);

  // testimony (the author sees their own pending story)
  const story = await call('POST', `/v1/communities/${gid}/testimonies`, { ...t, body: { title: 'Sweep story', body: 'God was good.', consent: true } });
  ok(story, 201);
  ok(await call('GET', `/v1/testimonies/${story.body.id}`, t), 200);

  // resources
  const res = store.first('resources', (r) => r.communityId === gid && r.status === 'published');
  if (res) {
    ok(await call('GET', `/v1/resources/${res.id}`, t), 200);
    ok(await call('PUT', `/v1/resources/${res.id}/progress`, { ...t, body: { position_seconds: 12 } }), 204);
  }

  // join request: a fresh student asks, then cancels
  const inst = store.get('institutions', ctx.student.institutionId);
  const fresh = await call('POST', '/v1/auth/register', { body: { full_name: 'Sweep Student', username: 'sweepstudent', birthdate: '2002-02-02', country: 'UG', email: 'sweep@fcu.test',
    institution_type: inst.type, institution_id: inst.id, password: 'Sup3rSecret!', accepted_terms: true, accepted_code_of_conduct: true, ...SIGNUP_EXTRAS } });
  ok(fresh, 201);
  const other = store.first('communities', (c) => c.type === 'specific' && c.institutionId === inst.id);
  const jr = await call('POST', `/v1/communities/${other.id}/join-requests`, { token: fresh.body.access_token });
  ok(jr, 201);
  ok(await call('DELETE', `/v1/join-requests/${jr.body.id}`, { token: fresh.body.access_token }), 204);

  // media: slot, bytes, confirm
  const slot = await call('POST', '/v1/media', { ...t, body: { purpose: 'post_photo', content_type: 'image/jpeg', size_bytes: 4 } });
  ok(slot, 201);
  const put = await fetch(`${base}/v1/media/${slot.body.media_id}/upload`, { method: 'PUT', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'image/jpeg' }, body: Buffer.from([1, 2, 3, 4]) });
  assert.equal(put.status, 204);
  contract.check(spec, 'PUT', `/v1/media/${slot.body.media_id}/upload`, put.status, null);
  ok(await call('POST', `/v1/media/${slot.body.media_id}/complete`, t), 200);

  // devices
  const dev = await call('POST', '/v1/devices', { ...t, body: { platform: 'android', push_token: 'sweep-token-1' } });
  ok(dev, 201);
  ok(await call('DELETE', `/v1/devices/${dev.body.id}`, t), 204);

  // account deletion last, on the throwaway student
  ok(await call('DELETE', '/v1/me', { token: fresh.body.access_token }), 202);
});

// Keeps the docs honest: an operation documented but never called by a test has an unchecked schema.
test('zz every documented operation is exercised by a test (WebSocket aside)', async () => {
  assert.deepEqual(contract.unexercised(spec), ['GET /realtime']);
});
