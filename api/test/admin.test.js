process.env.NODE_ENV = 'test';

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createApp } = require('../src/app');
const { seed, DEMO_PASSWORD } = require('./helpers/seed');
const store = require('../src/db/store');
const contract = require('./helpers/contract');

let server, base, ctx;
let spec; // docs/api/openapi-admin.yaml: every response in this file is checked against it
const A = '/v1/admin';
const call = async (method, path, { token, body, raw } = {}) => {
  const res = await fetch(base + A + path, {
    method,
    headers: { 'Content-Type': raw || 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? (raw ? body : JSON.stringify(body)) : undefined, // raw = content type of a binary body
  });
  const text = await res.text();
  let json = null; try { json = text ? JSON.parse(text) : null; } catch { json = text; }
  if (spec) contract.check(spec, method, A + path, res.status, typeof json === 'string' ? null : json); // text bodies (CSV) have no JSON schema to check
  return { status: res.status, body: json, headers: res.headers };
};
// The proxy forwards Authorization from the httpOnly cookie, so tests use the cookie value as Bearer.
const login = async (email, extra = {}) => {
  const r = await call('POST', '/auth/login', { body: { email, password: DEMO_PASSWORD, ...extra } });
  const m = (r.headers.getSetCookie?.() || []).find((c) => c.startsWith('fcu_access='));
  return { ...r, token: m && decodeURIComponent(m.split(';')[0].slice('fcu_access='.length)) };
};

test.before(async () => {
  spec = await contract.load('openapi-admin.yaml', '/v1/admin');
  store.reset(); ctx = seed();
  server = http.createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => {
  server.close();
  console.log(`# contract (admin): ${spec.checked} responses checked; ${contract.unexercised(spec).length} documented operations not called by any test`);
  assert.deepEqual([...spec.violations], [], `responses that do not match docs/api/openapi-admin.yaml (${spec.checked} checked)`);
});

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

// Calls the remaining operations once so their responses are checked against the documented schemas too.
test('contract sweep: remaining staff operations return what the spec says', async () => {
  const ok = (r, ...codes) => assert.ok(codes.includes(r.status), `expected ${codes} got ${r.status} ${JSON.stringify(r.body)}`);
  const sys = (await login('admin@fcu.test')).token;
  const sm = (await login('super@fcu.test')).token;
  const ca = (await login('content@fcu.test')).token;
  const S = { token: sys };
  const inst = ctx.generalMak.institutionId;

  // members
  ok(await call('GET', '/members/inactive', S), 200);
  const member = await call('POST', '/members', { ...S, body: { fullName: 'Sweep Member', email: 'sweepm@fcu.test', institutionId: inst, role: 'STUDENT' } });
  ok(member, 201);
  ok(await call('GET', `/members/${member.body.id}`, S), 200);
  ok(await call('PATCH', `/members/${member.body.id}/community`, { ...S, body: { communityId: ctx.growth.id } }), 200);
  ok(await call('POST', `/members/${member.body.id}/remind`, S), 200, 204);
  ok(await call('GET', '/institutions', S), 200);

  // join requests: decline
  const jr = store.insert('joinRequests', { communityId: ctx.growth.id, userId: ctx.friend.id, status: 'pending', decidedAt: null });
  ok(await call('POST', `/join-requests/${jr.id}/decline`, { token: sm, body: { reason: 'Not this term' } }), 200);

  // staff role
  ok(await call('POST', '/roles/staff', { ...S, body: { fullName: 'Sweep Staff', email: 'sweepstaff@fcu.test', role: 'CONTENT_ADMIN', sendInviteEmail: false } }), 201);

  // content and pathways
  const c = await call('POST', '/content', { token: ca, body: { title: 'Sweep devotional', type: 'DEVOTIONAL', bibleLink: 'char-ruth' } });
  ok(c, 201);
  ok(await call('GET', `/content/${c.body.id}`, { token: ca }), 200);
  ok(await call('PATCH', `/content/${c.body.id}`, { token: ca, body: { title: 'Sweep devotional (edited)' } }), 200);
  ok(await call('GET', '/pathways', S), 200);
  const path = await call('POST', '/pathways', { token: ca, body: { name: 'Sweep path', theme: 'Faith', steps: [{ contentId: c.body.id, title: 'Sweep', contentType: 'devotional' }], published: false } });
  ok(path, 201);
  ok(await call('GET', `/pathways/${path.body.id}`, S), 200);
  ok(await call('PUT', `/pathways/${path.body.id}`, { token: ca, body: { name: 'Sweep path v2', theme: 'Faith', steps: [{ contentId: c.body.id, title: 'Sweep', contentType: 'devotional' }], published: false } }), 200);
  ok(await call('PATCH', `/pathways/${path.body.id}`, { token: ca, body: { theme: 'Hope' } }), 200);
  ok(await call('DELETE', `/pathways/${path.body.id}`, { token: ca }), 204);

  // badges, announcements, stories
  ok(await call('GET', '/badges', S), 200);
  const badge = await call('POST', '/badges', { ...S, body: { name: 'Sweep Badge', description: 'x', ruleType: 'pray_requests', ruleTargetCount: 3, icon: 'heart', status: 'active', visibleOnProfile: true } });
  ok(badge, 201);
  ok(await call('PATCH', `/badges/${badge.body.id}`, { ...S, body: { ruleTargetCount: 4 } }), 200);
  ok(await call('GET', '/announcements', S), 200);
  const ann = await call('POST', '/announcements', { ...S, body: { title: 'Sweep', message: 'Hello', audienceType: 'all', publishTiming: 'scheduled', scheduledFor: new Date(Date.now() + 7 * 86400000).toISOString() } });
  ok(ann, 201);
  ok(await call('PATCH', `/announcements/${ann.body.id}`, { ...S, body: { message: 'Hello again' } }), 200);
  ok(await call('GET', '/stories', S), 200);
  const story = await call('POST', '/stories', { ...S, body: { studentName: 'Sweep', institution: 'MAK', videoUrl: 'https://x/s.mp4', duration: '1:00', consentObtained: true } });
  ok(story, 201);
  ok(await call('PATCH', `/stories/${story.body.id}`, { ...S, body: { duration: '1:10' } }), 200);

  // moderation
  ok(await call('GET', '/moderation/testimonies', S), 200);
  ok(await call('GET', '/moderation/posts?all=true', S), 200);
  const post = store.insert('posts', { communityId: ctx.growth.id, authorId: ctx.friend.id, text: 'sweep spam', mediaIds: [], pinned: false });
  store.insert('reports', { reporterId: ctx.student.id, targetType: 'post', targetId: post.id, reason: 'spam', details: 'x', status: 'open' });
  ok(await call('POST', `/moderation/posts/${post.id}/action`, { token: sm, body: { action: 'WARN_AUTHOR', notes: 'Please keep it kind' } }), 200);
  const sanction = store.first('sanctions', (x) => x.userId === ctx.friend.id && x.active);
  if (sanction) ok(await call('POST', `/moderation/sanctions/${sanction.id}/reinstate`, { ...S, body: { reason: 'Reviewed and reinstated' } }), 200);

  // privacy, audit, reports
  const consent = store.first('guardianConsents', () => true);
  if (consent) ok(await call('POST', `/privacy/guardian-consents/${consent.id}/remind`, S), 200, 204);
  ok(await call('POST', '/audit-log/export', { ...S, body: {} }), 200);
  ok(await call('POST', '/reports/export', { ...S, body: { reportType: 'community_health', format: 'csv' } }), 200, 501);
  ok(await call('GET', '/reports/schedules', S), 200);
  const sch = await call('POST', '/reports/schedules', { ...S, body: { reportType: 'community_health', cadence: 'weekly', recipientEmail: 'sweep@fcu.test' } });
  ok(sch, 201);
  const paused = await call('PATCH', `/reports/schedules/${sch.body.id}`, { ...S, body: { active: false } });
  ok(paused, 200);
  assert.equal(paused.body.active, false);
  ok(await call('PATCH', `/reports/schedules/${sch.body.id}`, { ...S, body: {} }), 422);
  ok(await call('DELETE', `/reports/schedules/${sch.body.id}`, S), 204);

  // my community (super-mentor)
  const jr2 = store.insert('joinRequests', { communityId: ctx.growth.id, userId: ctx.mentor.id, status: 'pending', decidedAt: null });
  ok(await call('POST', `/my-community/join-requests/${jr2.id}/approve`, { token: sm }), 200, 409);
  const jr3 = store.insert('joinRequests', { communityId: ctx.growth.id, userId: member.body.id, status: 'pending', decidedAt: null });
  ok(await call('POST', `/my-community/join-requests/${jr3.id}/decline`, { token: sm, body: {} }), 200, 409);
  ok(await call('POST', `/my-community/members/${ctx.student.id}/remind`, { token: sm }), 200, 204);
  ok(await call('POST', '/my-community/announcements', { token: sm, body: { title: 'Sweep', message: 'Meeting moved' } }), 201, 200);
  const rep2 = store.insert('reports', { reporterId: ctx.student.id, targetType: 'post', targetId: store.insert('posts', { communityId: ctx.growth.id, authorId: ctx.friend.id, text: 'x', mediaIds: [], pinned: false }).id, reason: 'spam', status: 'open' });
  ok(await call('POST', `/my-community/moderation/${rep2.id}`, { token: sm, body: { decision: 'dismiss' } }), 200);

  // account
  ok(await call('PATCH', '/account/profile', { ...S, body: { fullName: 'Admin User' } }), 200);
  const sessions = await call('GET', '/account/sessions', S);
  ok(sessions, 200);
  const other = sessions.body.sessions.find((x) => !x.current);
  if (other) ok(await call('DELETE', `/account/sessions/${other.id}`, S), 204, 200);
  ok(await call('POST', '/auth/logout', S), 200, 204);
});

// Keeps the docs honest: an operation documented but never called by a test has an unchecked schema.
// ───────── staff file uploads ─────────
test('staff uploads: slot -> bytes -> complete -> permanent address that serves the file', async () => {
  const sys = (await login('admin@fcu.test')).token;
  const bytes = Buffer.from('fake-png-bytes');
  const slot = await call('POST', '/media', { token: sys, body: { purpose: 'cover_photo', content_type: 'image/png', size_bytes: bytes.length } });
  assert.equal(slot.status, 201);
  assert.equal(slot.body.direct, false);
  assert.match(slot.body.url, /\/uploads\/[0-9a-f-]{36}$/);

  // not complete until the bytes arrive
  assert.equal((await call('POST', `/media/${slot.body.media_id}/complete`, { token: sys })).status, 409);
  assert.equal((await call('PUT', `/media/${slot.body.media_id}/upload`, { token: sys, body: bytes, raw: 'image/png' })).status, 204);
  assert.equal((await call('PUT', `/media/${slot.body.media_id}/upload`, { token: sys, body: bytes, raw: 'image/png' })).status, 409, 'cannot be overwritten');
  const done = await call('POST', `/media/${slot.body.media_id}/complete`, { token: sys });
  assert.equal(done.status, 200);
  const served = await fetch(done.body.url.replace(/^https?:\/\/[^/]+/, base));
  assert.equal(served.status, 200);
  assert.equal(served.headers.get('content-type'), 'image/png');
  assert.deepEqual(Buffer.from(await served.arrayBuffer()), bytes);

  // rules per purpose, and one person cannot touch another's upload
  assert.equal((await call('POST', '/media', { token: sys, body: { purpose: 'cover_photo', content_type: 'image/gif', size_bytes: 10 } })).status, 422);
  assert.equal((await call('POST', '/media', { token: sys, body: { purpose: 'cover_photo', content_type: 'image/png', size_bytes: 6 * 1024 * 1024 } })).status, 422);
  assert.equal((await call('POST', '/media', { token: sys, body: { purpose: 'content_video', content_type: 'video/mp4', size_bytes: 400 * 1024 * 1024 } })).status, 201);
  assert.equal((await call('POST', '/media', { token: sys, body: { purpose: 'nope', content_type: 'image/png', size_bytes: 1 } })).status, 422);
  const other = (await login('content@fcu.test')).token;
  assert.equal((await call('POST', `/media/${slot.body.media_id}/complete`, { token: other })).status, 404);
  assert.equal((await call('POST', '/media', { body: { purpose: 'cover_photo', content_type: 'image/png', size_bytes: 1 } })).status, 401);
});

test('zz every documented staff operation is exercised by a test', async () => {
  assert.deepEqual(contract.unexercised(spec), []);
});

// ───────── server-side sessions ─────────
test('sessions live on the server: opaque cookie, logout/expiry/revocation end them immediately', async () => {
  const me = (headers) => fetch(base + A + '/auth/me', { headers }).then((r) => r.status);
  const a = await login('admin@fcu.test');
  assert.match(a.token, /^[0-9a-f]{64}$/, 'the cookie is an opaque random handle, not a JWT');
  assert.ok(!(a.headers.getSetCookie() || []).some((c) => c.startsWith('fcu_refresh=')), 'no client-held refresh token');

  // The browser path: the cookie alone is enough
  assert.equal(await me({ Cookie: `fcu_access=${a.token}` }), 200);

  // Two devices; each sees the other, and the current one is flagged
  const b = await login('admin@fcu.test');
  const list = (await call('GET', '/account/sessions', { token: a.token })).body.sessions;
  assert.ok(list.length >= 2);
  assert.equal(list.filter((s) => s.current).length, 1);

  // Revoking the other device ends it on its very next request
  const other = list.find((s) => !s.current);
  assert.equal((await call('DELETE', `/account/sessions/${other.id}`, { token: a.token })).status, 200);
  const statuses = await Promise.all([a.token, b.token].map((t) => me({ Authorization: `Bearer ${t}` })));
  assert.deepEqual(statuses.slice().sort(), [200, 401], 'exactly the revoked device is signed out');

  // Logout revokes server-side: replaying the old cookie fails
  const c = await login('admin@fcu.test');
  const out = await fetch(base + A + '/auth/logout', { method: 'POST', headers: { Cookie: `fcu_access=${c.token}` } });
  assert.equal(out.status, 200);
  assert.match(out.headers.getSetCookie().join(';'), /fcu_access=;/);
  assert.equal(await me({ Cookie: `fcu_access=${c.token}` }), 401);
});

test('sessions expire when idle or past the absolute limit, and activity slides a remembered cookie', async () => {
  const me = (t) => fetch(base + A + '/auth/me', { headers: { Authorization: `Bearer ${t}` } }).then((r) => r.status);
  const find = (t) => store.first('staffSessions', (s) => s.tokenHash === require('crypto').createHash('sha256').update(t).digest('hex'));

  const idle = await login('admin@fcu.test');
  find(idle.token).lastActiveAt = new Date(Date.now() - 9 * 3600e3).toISOString(); // default idle limit is 8 h
  assert.equal(await me(idle.token), 401);

  const remembered = await login('admin@fcu.test', { rememberMe: true });
  find(remembered.token).lastActiveAt = new Date(Date.now() - 9 * 3600e3).toISOString();
  assert.equal(await me(remembered.token), 200, 'a remembered session tolerates a longer idle period');
  find(remembered.token).lastActiveAt = new Date(Date.now() - 6 * 60e3).toISOString(); // stale enough to be re-recorded
  const res = await fetch(base + A + '/auth/me', { headers: { Cookie: `fcu_access=${remembered.token}` } });
  assert.match((res.headers.getSetCookie() || []).join(';'), /fcu_access=.*Max-Age=\d+/, 'activity re-issues the cookie (sliding expiry)');

  const old = await login('admin@fcu.test');
  find(old.token).expiresAt = Date.now() - 1000; // absolute limit
  assert.equal(await me(old.token), 401);
});

test('password change signs out other devices; suspension signs out everywhere', async () => {
  const me = (t) => fetch(base + A + '/auth/me', { headers: { Authorization: `Bearer ${t}` } }).then((r) => r.status);
  const phone = await login('content@fcu.test');
  const laptop = await login('content@fcu.test');
  const change = await call('POST', '/account/password', { token: laptop.token, body: { currentPassword: DEMO_PASSWORD, newPassword: 'NewPass123' } });
  assert.equal(change.status, 200);
  assert.equal(await me(phone.token), 401, 'the other device is signed out');
  assert.equal(await me(laptop.token), 200, 'the device that changed the password stays in');
  // put the password back for any later test
  await call('POST', '/account/password', { token: laptop.token, body: { currentPassword: 'NewPass123', newPassword: DEMO_PASSWORD + 'x' } });
  store.first('users', (u) => u.email === 'content@fcu.test').passwordHash = require('bcryptjs').hashSync(DEMO_PASSWORD, 4);

  const target = await login('content@fcu.test');
  const admin = await login('admin@fcu.test');
  const id = store.first('users', (u) => u.email === 'content@fcu.test').id;
  assert.equal((await call('POST', `/members/${id}/suspend`, { token: admin.token, body: { reason: 'testing sessions' } })).status, 200);
  assert.equal(await me(target.token), 401, 'suspension ends the session at once');
  store.first('users', (u) => u.id === id).suspended = false;
});

test('a person keeps at most 10 sessions (least recently used goes first) and expired ones are swept', async () => {
  const sessions = require('../src/admin/sessions');
  const email = 'content@fcu.test';
  const first = await login(email);
  const firstSession = store.first('staffSessions', (x) => x.tokenHash === require('crypto').createHash('sha256').update(first.token).digest('hex'));
  firstSession.lastActiveAt = new Date(Date.now() - 3600e3).toISOString(); // the oldest
  const tokens = [];
  for (let i = 0; i < sessions.MAX_PER_USER; i++) tokens.push((await login(email)).token);
  const status = (t) => fetch(base + A + '/auth/me', { headers: { Authorization: `Bearer ${t}` } }).then((r) => r.status);
  assert.equal(await status(first.token), 401, 'the oldest session was dropped');
  assert.equal(await status(tokens[tokens.length - 1]), 200, 'the newest one works');
  const id = store.first('users', (u) => u.email === email).id;
  assert.ok(sessions.active(id).length <= sessions.MAX_PER_USER);

  // sweep forgets expired sessions of everybody
  store.first('staffSessions', (x) => x.userId === id).expiresAt = Date.now() - 1000;
  const before = store.col('staffSessions').length;
  sessions.sweep();
  assert.equal(store.col('staffSessions').length, before - 1);
});
