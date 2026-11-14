process.env.NODE_ENV = 'test';
process.env.SEED_DEMO_DATA = 'false';

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('../src/db/seed');
const store = require('../src/db/store');

let server, base, ctx;
const A = '/v1/admin';
const call = async (method, path, { token, body } = {}) => {
  const res = await fetch(base + A + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json = null; try { json = text ? JSON.parse(text) : null; } catch { json = text; }
  return { status: res.status, body: json, headers: res.headers };
};
// The proxy forwards Authorization from the httpOnly cookie, so tests use the cookie value as Bearer.
const login = async (email, extra = {}) => {
  const r = await call('POST', '/auth/login', { body: { email, password: DEMO_PASSWORD, ...extra } });
  const m = (r.headers.getSetCookie?.() || []).find((c) => c.startsWith('fcu_access='));
  return { ...r, token: m && decodeURIComponent(m.split(';')[0].slice('fcu_access='.length)) };
};

test.before(async () => {
  store.reset(); ctx = seed();
  server = http.createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => server.close());

test('staff login: cookie set, roles resolved, students/suspended refused', async () => {
  const sys = await login('admin@fcu.test', { rememberMe: true });
  assert.equal(sys.status, 200);
  assert.equal(sys.body.user.role, 'SYSTEM_ADMIN');
  assert.ok(sys.token, 'access cookie issued');
  assert.match(sys.headers.getSetCookie().join(';'), /HttpOnly/i);
  assert.equal((await login('content@fcu.test')).body.user.role, 'CONTENT_ADMIN');
  const sm = await login('super@fcu.test');
  assert.equal(sm.body.user.role, 'SUPER_MENTOR');
  assert.ok(sm.body.user.communityId);
  assert.equal((await login('student@fcu.test')).status, 403);
  assert.equal((await call('POST', '/auth/login', { body: { email: 'admin@fcu.test', password: 'bad' } })).status, 401);
  assert.equal((await call('GET', '/auth/me')).status, 401);
  assert.equal((await call('GET', '/auth/me', { token: sys.token })).body.user.email, 'admin@fcu.test');
  // a mobile-app token must not open the back office
  const mobile = (await fetch(base + '/v1/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ identifier: 'admin@fcu.test', password: DEMO_PASSWORD }) }).then((r) => r.json())).access_token;
  assert.equal((await call('GET', '/members', { token: mobile })).status, 401);
});

test('role guard and super-mentor scoping', async () => {
  const sm = (await login('super@fcu.test')).token;
  const ca = (await login('content@fcu.test')).token;
  assert.equal((await call('GET', '/audit-log', { token: sm })).status, 403);
  assert.equal((await call('POST', '/institutions', { token: ca, body: {} })).status, 403);
  const comms = (await call('GET', '/communities', { token: sm })).body.items;
  assert.ok(comms.length >= 1 && comms.every((c) => c.kind === 'SPECIFIC'));
  const sys = (await login('admin@fcu.test')).token;
  const all = (await call('GET', '/communities', { token: sys })).body.items;
  assert.ok(all.length > comms.length);
  const foreign = all.find((c) => !comms.some((x) => x.id === c.id));
  assert.equal((await call('GET', `/communities/${foreign.id}`, { token: sm })).status, 404);
});

test('members: list, create (minor consent), role change, suspend', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const list = await call('GET', '/members', { token: sys });
  assert.equal(list.status, 200);
  assert.ok(list.body.items.some((m) => m.email === 'student@fcu.test'));
  const inst = ctx.generalMak.institutionId;
  const bad = await call('POST', '/members', { token: sys, body: { fullName: 'X', email: 'nope' } });
  assert.equal(bad.status, 422);
  const created = await call('POST', '/members', { token: sys, body: { fullName: 'Tina Minor', email: 'tina@fcu.test', birthdate: '2012-05-01', institutionId: inst, role: 'STUDENT' } });
  assert.equal(created.status, 201);
  assert.equal(created.body.isMinor, true);
  assert.equal(created.body.guardianConsentStatus, 'PENDING');
  assert.equal(created.body.status, 'INVITED');
  assert.equal((await call('POST', '/members', { token: sys, body: { fullName: 'Tina Minor', email: 'tina@fcu.test', institutionId: inst } })).status, 409);
  const id = created.body.id;
  assert.equal((await call('PATCH', `/members/${id}/role`, { token: sys, body: { role: 'MENTOR' } })).body.role, 'MENTOR');
  assert.equal((await call('POST', `/members/${id}/suspend`, { token: sys, body: { reason: 'no' } })).status, 422);
  const sus = await call('POST', `/members/${id}/suspend`, { token: sys, body: { reason: 'Repeated misconduct' } });
  assert.equal(sus.body.status, 'SUSPENDED');
  assert.equal((await call('GET', '/moderation/sanctions', { token: sys })).body.items[0].active, true);
  const log = await call('GET', '/audit-log?action=role_changed', { token: sys });
  assert.equal(log.body.items.length, 1);
});

test('import reports created / skipped / failed rows', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const inst = ctx.generalMak.institutionId;
  const r = await call('POST', '/members/import', { token: sys, body: { rows: [
    { fullName: 'Imp One', email: 'imp1@fcu.test', institutionId: inst },
    { fullName: 'Imp One', email: 'imp1@fcu.test', institutionId: inst },
    { fullName: 'Bad', email: 'bad', institutionId: inst },
  ] } });
  assert.equal(r.status, 200);
  assert.deepEqual([r.body.createdCount, r.body.skippedCount, r.body.failedRows.length], [1, 1, 1]);
  assert.equal(r.body.failedRows[0].rowNumber, 3);
});

test('institutions & communities CRUD', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const inst = await call('POST', '/institutions', { token: sys, body: { name: 'Gulu University', type: 'UNIVERSITY', country: 'Uganda', city: 'Gulu' } });
  assert.equal(inst.status, 201);
  assert.equal(inst.body.communityCount, 1); // auto General community
  assert.equal((await call('POST', '/institutions', { token: sys, body: { name: 'Gulu University', type: 'UNIVERSITY', country: 'Uganda', city: 'Gulu' } })).status, 409);
  assert.equal((await call('PATCH', `/institutions/${inst.body.id}`, { token: sys, body: { city: 'Gulu City' } })).body.city, 'Gulu City');
  const c = await call('POST', '/communities', { token: sys, body: { institutionId: inst.body.id, name: 'Gulu Fellowship', meetingDay: 'Wednesday', meetingTime: '17:00', meetingPlace: 'Hall A', superMentorId: ctx.mentor.id } });
  assert.equal(c.status, 201);
  assert.equal(c.body.superMentorId, ctx.mentor.id);
  assert.equal(c.body.meetingDay, 'Wednesday');
  const upd = await call('PATCH', `/communities/${c.body.id}`, { token: sys, body: { status: 'CLOSED', openForJoinRequests: false } });
  assert.equal(upd.body.status, 'CLOSED');
});

test('join requests: approve, conflict, bulk skips conflicts', async () => {
  const sm = (await login('super@fcu.test')).token;
  const pending = store.col('joinRequests');
  const growth = ctx.growth;
  // student joins Growth Circle (mobile flow), another student already in a different community
  const mk = (userId, communityId) => { store.insert('memberships', { communityId, userId, role: 'member', status: 'pending', joinedAt: null }); return store.insert('joinRequests', { communityId, userId, status: 'pending', decidedAt: null }); };
  const j1 = mk(ctx.student.id, growth.id);
  const list = await call('GET', '/join-requests', { token: sm });
  assert.ok(list.body.items.some((j) => j.id === j1.id && j.status === 'PENDING'));
  const bulk = await call('POST', '/join-requests/bulk-approve', { token: sm, body: { ids: [j1.id, 'missing'] } });
  assert.deepEqual(bulk.body.approved, [j1.id]);
  assert.equal(bulk.body.skipped[0].reason, 'not_found');
  assert.equal((await call('POST', `/join-requests/${j1.id}/approve`, { token: sm })).status, 409); // already decided
  assert.ok(pending.length > 0);
});

test('content workflow: submit, self-validation blocked, publish, pathway needs published content', async () => {
  const ca = (await login('content@fcu.test')).token;
  const sys = (await login('admin@fcu.test')).token;
  const bad = await call('POST', '/content', { token: ca, body: { title: 'x' } });
  assert.equal(bad.status, 422);
  const c = await call('POST', '/content', { token: ca, body: { title: 'Faith of Ruth', type: 'DEVOTIONAL', bibleLink: 'char-ruth', submitForReview: true } });
  assert.equal(c.body.status, 'IN_REVIEW');
  const own = await call('POST', `/content/${c.body.id}/transition`, { token: ca, body: { action: 'APPROVE_AND_PUBLISH' } });
  assert.equal(own.status, 403);
  const draftPath = await call('POST', '/pathways', { token: ca, body: { name: 'Ruth path', theme: 'Faith', steps: [{ contentId: c.body.id, title: 'Faith of Ruth', contentType: 'devotional' }], published: true } });
  assert.equal(draftPath.status, 409); // unpublished content
  const pub = await call('POST', `/content/${c.body.id}/transition`, { token: sys, body: { action: 'APPROVE_AND_PUBLISH' } });
  assert.equal(pub.body.status, 'PUBLISHED');
  assert.ok(pub.body.validatedAt);
  assert.equal(pub.body.approvalTrail.at(-1).action, 'APPROVE_AND_PUBLISH');
  assert.equal((await call('POST', `/content/${c.body.id}/transition`, { token: sys, body: { action: 'SUBMIT_FOR_REVIEW' } })).status, 409);
  const ok = await call('POST', '/pathways', { token: ca, body: { name: 'Ruth path', theme: 'Faith', steps: [{ contentId: c.body.id, title: 'Faith of Ruth', contentType: 'devotional' }], published: true } });
  assert.equal(ok.status, 201);
  const picker = await call('GET', '/content?status=published', { token: ca });
  assert.ok(Array.isArray(picker.body) && picker.body.every((x) => x.published));
});

test('badges, announcements, stories, notification rules, settings', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const b = await call('POST', '/badges', { token: sys, body: { name: 'Prayer Warrior', description: 'Prayed a lot', ruleType: 'pray_requests', ruleTargetCount: 10, icon: 'heart', status: 'active', visibleOnProfile: true } });
  assert.equal(b.status, 201);
  assert.match(b.body.ruleDescription, /10 community prayer/);
  assert.equal((await call('PUT', `/badges/${b.body.id}`, { token: sys, body: { ruleTargetCount: 0 } })).status, 422);
  assert.equal((await call('DELETE', `/badges/${b.body.id}`, { token: sys })).status, 204);

  const past = await call('POST', '/announcements', { token: sys, body: { title: 'Hi', message: 'Hello all', audienceType: 'all', publishTiming: 'scheduled', scheduledFor: '2020-01-01T00:00:00Z' } });
  assert.equal(past.status, 422);
  const ann = await call('POST', '/announcements', { token: sys, body: { title: 'Hi', message: 'Hello all', audienceType: 'all', publishTiming: 'now' } });
  assert.equal(ann.body.status, 'published');
  assert.equal(ann.body.communityName, 'All Communities');

  assert.equal((await call('POST', '/stories', { token: sys, body: { studentName: 'Ann', institution: 'MAK', videoUrl: 'https://x/y.mp4', duration: '1:45' } })).status, 422); // no consent
  const s1 = await call('POST', '/stories', { token: sys, body: { studentName: 'Ann', institution: 'MAK', videoUrl: 'https://x/y.mp4', duration: '1:45', consentObtained: true } });
  const s2 = await call('POST', '/stories', { token: sys, body: { studentName: 'Bob', institution: 'KYU', videoUrl: 'https://x/z.mp4', duration: '2:00', consentObtained: true } });
  const re = await call('PUT', '/stories/reorder', { token: sys, body: { stories: [{ id: s2.body.id, order: 0 }, { id: s1.body.id, order: 1 }] } });
  assert.equal(re.body.items[0].studentName, 'Bob');

  const rules = await call('GET', '/notifications/rules', { token: sys });
  assert.equal(rules.body.items.length, 7);
  const r0 = rules.body.items[0];
  assert.equal((await call('PATCH', `/notifications/rules/${r0.id}`, { token: sys, body: { channels: { inApp: false, email: false, sms: false } } })).status, 422);
  assert.equal((await call('PATCH', `/notifications/rules/${r0.id}`, { token: sys, body: { enabled: false } })).body.enabled, false);

  assert.equal((await call('PATCH', '/settings/minors', { token: sys, body: { ageThreshold: 99 } })).status, 422);
  assert.equal((await call('PATCH', '/settings/minors', { token: sys, body: { ageThreshold: 16 } })).body.ageThreshold, 16);
  assert.equal((await call('PUT', '/settings/inactivity-threshold', { token: sys, body: { days: 21 } })).body.days, 21);
  assert.equal((await call('GET', '/settings/inactivity-threshold', { token: sys })).body.days, 21);
  assert.equal((await call('GET', '/settings/nope', { token: sys })).status, 404);
});

test('moderation: report actions respect role, testimonies, privacy requests', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const sm = (await login('super@fcu.test')).token;
  const post = store.insert('posts', { communityId: ctx.growth.id, authorId: ctx.friend.id, text: 'buy cheap stuff', mediaIds: [], pinned: false });
  const rep = store.insert('reports', { reporterId: ctx.student.id, targetType: 'post', targetId: post.id, reason: 'spam', details: 'x', status: 'open' });
  const q = await call('GET', '/moderation/reports', { token: sm });
  assert.ok(q.body.items.some((r) => r.id === rep.id));
  assert.equal((await call('POST', `/moderation/reports/${rep.id}/action`, { token: sm, body: { action: 'SUSPEND', notes: 'bad' } })).status, 403);
  assert.equal((await call('POST', `/moderation/reports/${rep.id}/action`, { token: sm, body: { action: 'HIDE' } })).status, 422); // note required
  const hid = await call('POST', `/moderation/reports/${rep.id}/action`, { token: sm, body: { action: 'HIDE', notes: 'violates charter' } });
  assert.equal(hid.body.status, 'RESOLVED');
  assert.equal(store.get('posts', post.id).hidden, true);

  const t = store.first('testimonies', () => true) || store.insert('testimonies', { communityId: ctx.growth.id, authorId: ctx.student.id, title: 't', body: 'story', status: 'pending_review' });
  t.status = 'pending_review';
  assert.equal((await call('POST', `/moderation/testimonies/${t.id}/review`, { token: sm, body: { action: 'REJECT' } })).status, 422);
  assert.equal((await call('POST', `/moderation/testimonies/${t.id}/review`, { token: sm, body: { action: 'APPROVE' } })).body.status, 'APPROVED');
  assert.ok(store.get('testimonies', t.id).publishedAt);

  const me = (await fetch(base + '/v1/auth/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ identifier: 'david@fcu.test', password: DEMO_PASSWORD }) }).then((r) => r.json())).access_token;
  await fetch(base + '/v1/me/export', { method: 'POST', headers: { Authorization: `Bearer ${me}` } });
  const reqs = await call('GET', '/privacy/data-requests', { token: sys });
  assert.equal(reqs.body.items[0].type, 'EXPORT');
  assert.equal((await call('POST', `/privacy/data-requests/${reqs.body.items[0].id}/process`, { token: sys })).body.status, 'DONE');
  assert.equal((await call('POST', `/privacy/data-requests/${reqs.body.items[0].id}/process`, { token: sys })).status, 409);
  assert.equal((await call('GET', '/privacy/guardian-consents', { token: sys })).status, 200);
});

test('dashboard, reports, my-community, account', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const sm = (await login('super@fcu.test')).token;
  const d = await call('GET', '/dashboard', { token: sys });
  assert.equal(d.body.kpis.length, 4);
  assert.equal(d.body.weeklyActivity.length, 7);
  const rep = await call('GET', '/reports?range=30d&campus=all&community=all', { token: sys });
  assert.equal(rep.body.membersOverTime.length, 6);
  const sch = await call('POST', '/reports/schedules', { token: sys, body: { reportType: 'community_health', cadence: 'weekly', recipientEmail: 'ops@fcu.test' } });
  assert.equal(sch.body.reportLabel, 'Community health & attendance');
  const csv = await fetch(base + A + '/reports/export', { method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${sys}` }, body: JSON.stringify({ format: 'csv', filters: {} }) });
  assert.match(csv.headers.get('content-type'), /csv/);

  const mine = await call('GET', '/my-community', { token: sm });
  assert.equal(mine.status, 200);
  assert.ok(mine.body.communityId);
  assert.equal((await call('GET', '/my-community', { token: sys })).status, 403);
  const mt = await call('PATCH', '/my-community/meeting', { token: sm, body: { day: 'Friday', time: '16:30', place: 'Chapel' } });
  assert.deepEqual(mt.body, { day: 'Friday', time: '16:30', place: 'Chapel' });

  assert.equal((await call('POST', '/account/password', { token: sys, body: { currentPassword: 'wrong', newPassword: 'NewPassw0rd' } })).status, 422);
  assert.equal((await call('POST', '/account/password', { token: sys, body: { currentPassword: DEMO_PASSWORD, newPassword: 'short' } })).status, 422);
  assert.equal((await call('GET', '/account/sessions', { token: sys })).body.sessions.length > 0, true);
  const fp = await call('POST', '/auth/forgot-password', { body: { email: 'nobody@x.test' } });
  assert.equal(fp.status, 200); // no account enumeration
  assert.equal((await call('POST', '/auth/reset-password', { body: { token: 'bogus', password: 'Newpass123' } })).status, 410);
  assert.equal((await call('GET', '/bible-links?q=ps', { token: sys })).body.items.length, 1);
});
