process.env.NODE_ENV = 'test';
const test = require('node:test');
const assert = require('node:assert/strict');
const store = require('../src/db/store');
const prisma = require('../src/db/prisma');
const mailer = require('../src/services/mailer');

// Minimal stand-in for the generated Prisma client: one Map of rows per model, with the calls prisma.js uses.
function fakePrisma() {
  const tables = {};
  const t = (m) => (tables[m] ||= new Map());
  const client = new Proxy({}, {
    get(_, k) {
      if (k === '$transaction') return async (ops) => { for (const op of ops) await op(); };
      if (k === '$disconnect') return async () => {};
      return {
        findMany: async () => [...t(k).values()].map((r) => structuredClone(r)),
        count: async () => t(k).size,
        // deferred, so $transaction runs them in order like real Prisma promises
        upsert: ({ where, create, update }) => async () => { t(k).set(where.id, structuredClone(t(k).has(where.id) ? { ...t(k).get(where.id), ...update } : create)); },
        deleteMany: ({ where }) => async () => { for (const id of where.id.in) t(k).delete(id); },
      };
    },
  });
  return { client, tables };
}
const norm = (o) => JSON.parse(JSON.stringify(o)); // drops undefined, like a JSON round trip

test('prisma persistence: flush writes changes and load restores them', async () => {
  const { client, tables } = fakePrisma();
  prisma.useClient(client);
  store.reset();

  const inst = store.insert('institutions', { name: 'Makerere', type: 'university', country: 'UG' });
  const u = store.insert('users', { fullName: 'Ada', email: 'ada@example.com', institutionId: inst.id, passwordHash: 'x', emailVerified: false, phoneVerified: false, verifiedMentor: false, weird: { a: 1 } });
  const c = store.insert('communities', { type: 'specific', name: 'Circle', institutionId: inst.id });
  const p = store.insert('posts', { communityId: c.id, authorId: u.id, text: 'hello', pinned: false, mediaIds: [] });
  await prisma.flush();
  assert.ok(tables.user.has(u.id) && tables.post.has(p.id));
  assert.equal(tables.user.get(u.id).email, 'ada@example.com');          // real column, not a JSON blob
  assert.deepEqual(tables.user.get(u.id).extra.weird, { a: 1 });         // unknown fields are kept, not dropped

  // direct mutation (not via store.update), a delete, and an orphan row
  u.fullName = 'Ada L.';
  store.remove('posts', (x) => x.id === p.id);
  const orphan = store.insert('posts', { communityId: 'missing', authorId: u.id, text: 'x', pinned: false, mediaIds: [] });
  await prisma.flush();
  assert.equal(tables.user.get(u.id).fullName, 'Ada L.');
  assert.ok(!tables.post.has(p.id));
  assert.ok(!tables.post.has(orphan.id), 'rows whose required parent is missing are not written');

  // simulate a restart
  store.reset();
  assert.equal(await prisma.load(), 3);
  assert.deepEqual(norm(store.get('users', u.id)), norm({ ...u, fullName: 'Ada L.' }));
  prisma.useClient(null);
  store.reset();
});

test('every demo record survives a trip through the relational mapping unchanged', async () => {
  const { seed } = require('../src/db/seed');
  const M = require('../src/db/mapping');
  const { client, tables } = fakePrisma();
  prisma.useClient(client);
  store.reset(); seed();
  const original = norm(store.db);
  const total = Object.values(original).reduce((n, r) => n + r.length, 0);
  assert.ok(total > 50);
  await prisma.flush();
  const stored = Object.values(tables).reduce((n, m) => n + m.size, 0);
  assert.equal(stored, total, 'no seed record was skipped (all foreign keys resolve)');
  store.reset();
  assert.equal(await prisma.load(), total);
  assert.deepEqual(norm(store.db), original);
  // a second flush has nothing to do
  assert.equal(await prisma.flush().then(() => Object.values(tables).reduce((n, m) => n + m.size, 0)), total);
  assert.ok(M.order().indexOf('users') < M.order().indexOf('memberships'), 'parents are written before children');
  prisma.useClient(null);
  store.reset();
});

test('seed script helper: first admin is created once and never overwrites', () => {
  const { ensureAdmin } = require('../src/db/bootstrap');
  store.reset();
  assert.equal(ensureAdmin({}), null);
  assert.throws(() => ensureAdmin({ ADMIN_EMAIL: 'a@x.com', ADMIN_PASSWORD: 'short' }), /at least 10/);
  const a = ensureAdmin({ ADMIN_EMAIL: 'Root@Example.com', ADMIN_PASSWORD: 'a-long-password' });
  assert.equal(a.email, 'root@example.com');
  assert.equal(a.platformRole, 'system_admin');
  assert.equal(ensureAdmin({ ADMIN_EMAIL: 'other@example.com', ADMIN_PASSWORD: 'a-long-password' }), null);
  assert.equal(store.col('users').length, 1);
  store.reset();
});

test('mailer: templates render and are captured in the test outbox', async () => {
  mailer.outbox.length = 0;
  await mailer.send('a@example.com', 'otp', { code: '123456', purpose: 'login' });
  await mailer.send('b@example.com', 'staffReset', { name: '<b>Eve</b>', link: 'https://x.test/reset?token=t' });
  assert.equal(mailer.outbox.length, 2);
  assert.match(mailer.outbox[0].subject, /123456/);
  assert.ok(!mailer.outbox[1].html.includes('<b>Eve</b>'), 'user text must be HTML-escaped');
});

test('emails are sent for email OTP and staff password reset', async () => {
  const { createApp } = require('../src/app');
  const { seed } = require('../src/db/seed');
  store.reset(); seed();
  const server = require('http').createServer(createApp());
  await new Promise((r) => server.listen(0, r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (path, body) => fetch(base + path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  mailer.outbox.length = 0;
  assert.equal((await post('/v1/auth/otp/request', { channel: 'email', destination: 'student@fcu.test', purpose: 'login' })).status, 202);
  assert.equal((await post('/v1/admin/auth/forgot-password', { email: 'admin@fcu.test' })).status, 200);
  await new Promise((r) => setTimeout(r, 50));
  const kinds = mailer.outbox.map((m) => m.template);
  assert.deepEqual(kinds.sort(), ['otp', 'staffReset']);
  assert.match(mailer.outbox.find((m) => m.template === 'staffReset').text, /reset-password\?token=[0-9a-f]{48}/);
  // unknown / non-staff accounts get no email (and no different response)
  mailer.outbox.length = 0;
  assert.equal((await post('/v1/admin/auth/forgot-password', { email: 'student@fcu.test' })).status, 200);
  assert.equal(mailer.outbox.length, 0);
  server.close();
});

test('R2 storage: signed upload slot, lazy confirmation, redirect on read', async () => {
  const config = require('../src/config');
  const storage = require('../src/services/storage');
  const { confirm } = require('../src/routes/media');
  config.r2 = { accountId: 'acct', accessKeyId: 'k', secretAccessKey: 's', bucket: 'b', publicUrl: 'https://cdn.example.com' };
  config.r2Enabled = true;
  try {
    const m = store.insert('media', { ownerId: 'u', purpose: 'post_photo', contentType: 'image/png', sizeBytes: 10, status: 'pending' });
    const url = await storage.signedPutUrl(m);
    assert.match(url, /^https:\/\/acct\.r2\.cloudflarestorage\.com\/b\/media\/post_photo\//);
    assert.match(url, /X-Amz-Signature=/);
    assert.ok(!/checksum/i.test(url), 'no checksum params in the signed URL');
    assert.equal(await storage.readUrl(m), `https://cdn.example.com/media/post_photo/${m.id}`);

    let size = null;
    storage.useClient({ send: async (cmd) => { if (size === null) { const e = new Error('nf'); e.name = 'NotFound'; throw e; } return { ContentLength: size }; } });
    assert.equal(await confirm(m), false);       // not uploaded yet
    size = 10;
    assert.equal(await confirm(m), true);        // landed
    assert.equal(m.status, 'ready');

    const big = store.insert('media', { ownerId: 'u', purpose: 'post_photo', contentType: 'image/png', sizeBytes: 10, status: 'pending' });
    size = 99;
    assert.equal(await confirm(big), false);     // bigger than declared
    assert.equal(big.status, 'rejected');
  } finally {
    config.r2Enabled = false;
    storage.useClient(null);
  }
});
