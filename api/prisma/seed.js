/**
 * Seeds the database:  npm run db:seed        (or: npx prisma db seed)
 *   - demo data (institutions, communities, users, posts, pathways, resources, back-office content…) — only into an EMPTY database
 *   - first system admin from ADMIN_EMAIL / ADMIN_PASSWORD, if set and no admin exists
 * Demo accounts (password Password123!): admin@fcu.test, content@fcu.test, super@fcu.test, mentor@fcu.test, student@fcu.test, david@fcu.test
 * Never run the demo seed against production data. Use `node prisma/seed.js --admin-only` to skip demo data. (SEED_DEMO_DATA only affects the server's auto-seed.)
 */
require('dotenv').config();
const store = require('../src/db/store');
const db = require('../src/db/prisma');
const { seed, DEMO_PASSWORD } = require('../src/db/seed');
const { ensureAdmin } = require('../src/db/bootstrap');

(async () => {
  if (!db.enabled()) throw new Error('DATABASE_URL is not set');
  await db.init();
  const existing = await db.load();
  // Explicitly running the seed command means "seed": SEED_DEMO_DATA only controls the server's own auto-seed.
  const demo = !process.argv.includes('--admin-only');
  if (demo && existing === 0) {
    seed();
    console.log(`Demo data created. Sign in as admin@fcu.test / ${DEMO_PASSWORD}`);
  } else if (demo) {
    console.log(`Database already has ${existing} records; demo data skipped.`);
  }
  const admin = ensureAdmin();
  if (admin) console.log(`System admin created: ${admin.email}`);
  await db.flush();
  const counts = Object.entries(store.db).filter(([, r]) => r.length).map(([c, r]) => `${c}=${r.length}`).join(' ');
  console.log(`Saved. ${counts}`);
  await db.close();
})().catch((e) => { console.error('Seed failed:', e.message); process.exit(1); });
