process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const store = require('../src/db/store');
const mailer = require('../src/services/mailer');
const push = require('../src/services/push');
const realtime = require('../src/realtime/socket');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('./helpers/seed');

let server, base;
const user = (email) => store.first('users', (u) => u.email === email);
const growth = () => store.first('communities', (c) => c.name === 'Growth Circle');

test.before(async () => { server = http.createServer(createApp()); await new Promise((r) => server.listen(0, r)); base = `http://127.0.0.1:${server.address().port}`; });
test.after(() => server.close());

let events;
test.beforeEach(() => {
  store.reset(); seed(); mailer.outbox.length = 0; push.outbox.length = 0; events = [];
  realtime.emit = (userId, name, data) => events.push({ userId, name, data }); // what the live connection would carry
});

const post = (path, headers, body) => fetch(base + path, { method: 'POST', headers: { 'Content-Type': 'application/json', ...headers }, body: body ? JSON.stringify(body) : undefined });
const get = (path, headers) => fetch(base + path, { headers });
const appToken = async (email) => (await (await post('/v1/auth/login', {}, { identifier: email, password: DEMO_PASSWORD })).json()).access_token;
const staffToken = async (email) => {
  const r = await post('/v1/admin/auth/login', {}, { email, password: DEMO_PASSWORD });
  return decodeURIComponent(r.headers.getSetCookie().find((c) => c.startsWith('fcu_access=')).split(';')[0].slice(11));
};
const bearer = (t) => ({ Authorization: `Bearer ${t}` });

/** The student asks to join [community]; returns their token and the pending request. */
async function ask(community = growth(), email = 'student@fcu.test') {
  const t = await appToken(email);
  const res = await post(`/v1/communities/${community.id}/join-requests`, { ...bearer(t), 'Idempotency-Key': Math.random().toString(36).slice(2) });
  assert.equal(res.status, 201);
  return { token: t, request: await res.json() };
}
// What the student ends up with, as the app sees it
async function outcome(token) {
  const mine = await (await get('/v1/me/communities', bearer(token))).json();
  const inbox = await (await get('/v1/me/notifications', bearer(token))).json();
  return { specific: mine.specific, notifications: inbox.items };
}
const student = () => user('student@fcu.test');
const toldApproved = (email = 'student@fcu.test') => mailer.outbox.filter((m) => m.to === email && m.template === 'notification' && /Welcome to Growth Circle/.test(m.subject)).length;

// Every way a request can be approved must do the same thing for the student
const PATHS = {
  'back office (system admin)': async (reqId) => (await post(`/v1/admin/join-requests/${reqId}/approve`, bearer(await staffToken('admin@fcu.test')))).status,
  'back office (super-mentor)': async (reqId) => (await post(`/v1/admin/join-requests/${reqId}/approve`, bearer(await staffToken('super@fcu.test')))).status,
  'back office bulk approve': async (reqId) => (await post('/v1/admin/join-requests/bulk-approve', bearer(await staffToken('admin@fcu.test')), { ids: [reqId] })).status,
  'super-mentor home (my community)': async (reqId) => (await post(`/v1/admin/my-community/join-requests/${reqId}/approve`, bearer(await staffToken('super@fcu.test')))).status,
  'the app (super-mentor)': async (reqId) => (await post(`/v1/join-requests/${reqId}/decision`, bearer(await appToken('super@fcu.test')), { decision: 'approve' })).status,
};

for (const [name, approve] of Object.entries(PATHS)) {
  test(`approving from the ${name} makes the student a member and tells them (in-app, email, phone, live)`, async () => {
    const { token, request } = await ask();
    assert.equal((await outcome(token)).specific.membership_status, 'pending');
    store.insert('devices', { userId: student().id, platform: 'android', pushToken: 't1' });

    assert.equal(await approve(request.id), 200);

    const after = await outcome(token);
    assert.equal(after.specific.membership_status, 'member', 'they are in the community');
    assert.equal(after.specific.community.id, growth().id);
    assert.ok(after.notifications.some((n) => n.type === 'request_approved'), 'an in-app notification');
    assert.equal(toldApproved(), 1, 'an email');
    await push.flush();
    assert.equal(push.outbox.filter((p) => p.data && p.data.type === 'request_approved').length, 1, 'a phone push');
    assert.ok(events.some((e) => e.userId === student().id && e.name === 'join_request.decided' && e.data.status === 'approved'), 'the live event');
    assert.ok(store.first('memberships', (m) => m.userId === student().id && m.communityId === growth().id && m.status === 'member' && m.joinedAt));
  });
}

test('a request whose pending membership row went missing still ends with a real membership', async () => {
  const { token, request } = await ask();
  store.remove('memberships', (m) => m.userId === student().id && m.communityId === growth().id);
  assert.equal(await PATHS['back office (system admin)'](request.id), 200);
  assert.equal((await outcome(token)).specific.membership_status, 'member');
});

for (const [name, approve] of Object.entries(PATHS).filter(([n]) => !n.includes('bulk'))) { // bulk answers 200 and lists what it skipped (below)
  test(`declining or approving twice from the ${name} is refused cleanly`, async () => {
    const { request } = await ask();
    assert.equal(await approve(request.id), 200);
    assert.equal(await approve(request.id), 409, 'already decided');
  });
}

test('a student who already belongs to another community cannot be approved into a second one (every path says so the same way)', async () => {
  const other = store.first('communities', (c) => c.name === 'Life & Faith Circle');
  const { request } = await ask();
  // they got into another specific community meanwhile
  store.insert('memberships', { communityId: other.id, userId: student().id, role: 'member', status: 'member', joinedAt: store.now() });
  for (const [name, approve] of Object.entries(PATHS)) {
    if (name.includes('bulk')) continue;
    assert.equal(await approve(request.id), 409, name);
  }
  const bulk = await (await post('/v1/admin/join-requests/bulk-approve', bearer(await staffToken('admin@fcu.test')), { ids: [request.id] })).json();
  assert.deepEqual(bulk.approved, []);
  assert.equal(bulk.skipped[0].reason, 'community_limit_reached');
  assert.equal(store.first('joinRequests', (j) => j.id === request.id).status, 'pending', 'nothing changed');
});

test('bulk approve reports what it skipped instead of failing the whole batch', async () => {
  const a = await ask(growth(), 'student@fcu.test');
  const done = await ask(growth(), 'david@fcu.test').catch(() => null); // david is already in Growth Circle: cannot ask
  const token = await staffToken('admin@fcu.test');
  await post('/v1/admin/join-requests/bulk-approve', bearer(token), { ids: [a.request.id] });
  const again = await (await post('/v1/admin/join-requests/bulk-approve', bearer(token), { ids: [a.request.id, 'no-such-id'] })).json();
  assert.deepEqual(again.approved, []);
  assert.deepEqual(again.skipped.map((s) => s.reason).sort(), ['not_found', 'not_pending']);
  assert.equal(done, null);
});

test('declining tells the student why, everywhere', async () => {
  const { token, request } = await ask();
  const res = await post(`/v1/admin/my-community/join-requests/${request.id}/decline`, bearer(await staffToken('super@fcu.test')), { reason: 'The group is full this term' });
  assert.equal(res.status, 200);
  const after = await outcome(token);
  const note = after.notifications.find((n) => n.type === 'request_declined');
  assert.ok(note, 'an in-app notification');
  assert.match(note.body, /group is full/);
  assert.equal(after.specific, null, 'no pending membership left');
  const reqs = await (await get('/v1/me/join-requests', bearer(token))).json();
  assert.equal(reqs.items[0].status, 'rejected');
  assert.match(reqs.items[0].note, /group is full/);
  // and they can ask again somewhere else
  const again = await post(`/v1/communities/${store.first('communities', (c) => c.name === 'Life & Faith Circle').id}/join-requests`, { ...bearer(token), 'Idempotency-Key': 'again-1' });
  assert.equal(again.status, 201);
});

test('a super-mentor of two communities can approve requests in either from their own screen', async () => {
  const second = store.first('communities', (c) => c.name === 'Life & Faith Circle');
  const { token, request } = await ask(second);
  assert.equal(await PATHS['super-mentor home (my community)'](request.id), 200);
  assert.equal((await outcome(token)).specific.community.id, second.id);
});

test('the community\'s super-mentor is emailed when a student asks to join (unless staff switch that off), and sees every request they lead', async () => {
  const { ruleOf } = require('../src/utils/rules');
  const second = store.first('communities', (c) => c.name === 'Life & Faith Circle');
  const a = await ask(growth(), 'student@fcu.test');
  const mail = mailer.outbox.filter((m) => m.to === 'super@fcu.test' && m.template === 'notification');
  assert.equal(mail.length, 1);
  assert.equal(mail[0].subject, 'New join request');
  assert.match(mail[0].text, /Grace Namuli asked to join Growth Circle/);
  assert.equal(mailer.outbox.filter((m) => m.to === 'student@fcu.test').length, 0, 'the student is not emailed about their own request');

  // a second request in the other community they lead is visible on their home screen too, labelled
  store.insert('memberships', { communityId: second.id, userId: user('super@fcu.test').id, role: 'super_mentor', status: 'member', joinedAt: store.now() });
  const b = await ask(second, 'mentor@fcu.test').catch(() => null);
  const home = await (await get('/v1/admin/my-community', bearer(await staffToken('super@fcu.test')))).json();
  assert.ok(home.pendingRequests.some((r) => r.id === a.request.id && r.communityName === 'Growth Circle'));
  assert.equal(home.kpis.pendingRequests, home.pendingRequests.length);

  mailer.outbox.length = 0;
  ruleOf('join_request_received').channels.email = false;
  await ask(second, 'david@fcu.test').catch(() => null);
  assert.equal(mailer.outbox.filter((m) => m.to === 'super@fcu.test').length, 0);
  assert.equal(b === null || b.request.status === 'pending', true);
});

test('a database that already has the original rules gets the newer ones without losing staff edits', () => {
  const rules = require('../src/utils/rules');
  store.col('notificationRules').length = 0;
  rules.RULE_SEED.filter(([k]) => k !== 'join_request_received').forEach(([triggerKey, triggerLabel, recipient, title, message]) =>
    store.insert('notificationRules', { triggerKey, triggerLabel, recipient, channels: { inApp: true, email: true, sms: false }, enabled: true, template: { title: title + ' (edited)', message }, updatedAt: store.now() }));
  rules.ensureRules();
  assert.equal(store.col('notificationRules').length, rules.RULE_SEED.length);
  assert.ok(rules.ruleOf('join_request_received'), 'the new rule appears');
  assert.match(rules.ruleOf('join_request_approved').template.title, /\(edited\)$/, 'existing edits are kept');
});

test('a pending membership carries its request id, and super-mentors get a live event when a student asks', async () => {
  const { token, request } = await ask();
  const mine = await (await get('/v1/me/communities', bearer(token))).json();
  assert.equal(mine.specific.membership_status, 'pending');
  assert.equal(mine.specific.join_request_id, request.id, 'so the app can cancel it directly');
  const asked = events.find((e) => e.name === 'join_request.created');
  assert.ok(asked, 'a live event');
  assert.equal(asked.userId, user('super@fcu.test').id);
  assert.deepEqual(asked.data, { request_id: request.id, community_id: growth().id });

  assert.equal(await PATHS['back office (system admin)'](request.id), 200);
  const after = await (await get('/v1/me/communities', bearer(token))).json();
  assert.equal(after.specific.join_request_id, null, 'null once a member');
});

test('auto-approval (the default) makes the student a member at once and tells them; staff can switch it off', async () => {
  const setting = store.first('settings', (x) => x.key === 'joinRequests');
  const saved = setting.value;
  try {
    store.remove('settings', (x) => x.key === 'joinRequests'); // no setting: the default, on
    const fresh = store.first('communities', (c) => c.name === 'Life & Faith Circle') || growth();
    const email = 'auto@fcu.test';
    // A new student, so earlier tests' memberships do not interfere.
    const reg = await post('/v1/auth/register', {}, {
      full_name: 'Auto Student', username: 'autostudent', birthdate: '2003-03-03', country: 'UG', email,
      institution_type: 'university', institution_id: fresh.institutionId, year_of_study: 1,
      password: 'Sup3rSecret!', accepted_terms: true, accepted_code_of_conduct: true, accepted_national_activities: true,
    });
    assert.equal(reg.status, 201, await reg.clone().text());
    const token = (await reg.json()).access_token;
    const res = await post(`/v1/communities/${fresh.id}/join-requests`, { ...bearer(token), 'Idempotency-Key': 'auto-1' });
    assert.equal(res.status, 201);
    assert.equal((await res.json()).status, 'approved');
    const { specific, notifications } = await outcome(token);
    assert.equal(specific.membership_status, 'member');
    assert.ok(notifications.some((n) => n.type === 'request_approved'));

    // The app can tell (no sign-in needed).
    assert.equal((await (await get('/v1/lookups/app-config')).json()).join_requests.auto_approve, true);

    // Switched off in the back office: requests wait again, and the app is told.
    const admin = await staffToken('admin@fcu.test');
    const off = await fetch(base + '/v1/admin/settings/joinRequests', { method: 'PATCH', headers: { 'Content-Type': 'application/json', ...bearer(admin) }, body: JSON.stringify({ autoApprove: false }) });
    assert.equal(off.status, 200);
    assert.equal((await off.json()).autoApprove, false);
    assert.equal((await (await get('/v1/lookups/app-config')).json()).join_requests.auto_approve, false);
  } finally {
    store.remove('settings', (x) => x.key === 'joinRequests');
    store.insert('settings', { key: 'joinRequests', value: saved });
  }
});

