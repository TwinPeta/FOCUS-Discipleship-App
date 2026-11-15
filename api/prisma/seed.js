/**
 * One-time setup of a real database:  npm run db:seed
 *   - the first system administrator from ADMIN_EMAIL / ADMIN_PASSWORD (10+ chars), if set and no admin exists
 *   - with --institutions: the schools in prisma/institutions.json (each with its General community), skipping any that exist
 * There is no demo data. Everything else (communities, content, people) is created through the back office.
 */
require('dotenv').config();
const store = require('../src/db/store');
const db = require('../src/db/prisma');
const { ensureAdmin } = require('../src/db/bootstrap');
const institutions = require('./institutions.json');

(async () => {
  if (!db.enabled()) throw new Error('DATABASE_URL is not set');
  await db.init();
  await db.load();

  const admin = ensureAdmin();
  if (admin) console.log(`System admin created: ${admin.email}`);

  if (process.argv.includes('--institutions')) {
    let added = 0;
    for (const { name, type, country } of institutions) {
      if (store.first('institutions', (i) => i.name.toLowerCase() === name.toLowerCase())) continue;
      const inst = store.insert('institutions', { name, type, country });
      store.insert('communities', { type: 'general', name: 'General community', initials: 'GE', institutionId: inst.id, description: `Everyone on the ${name} campus, open to all.` });
      added++;
    }
    console.log(`Institutions: ${added} added, ${institutions.length - added} already present.`);
  }

  await db.flush();
  const counts = Object.entries(store.db).filter(([, r]) => r.length).map(([c, r]) => `${c}=${r.length}`).join(' ');
  console.log(`Saved. ${counts || 'database is empty'}`);
  await db.close();
})().catch((e) => { console.error('Seed failed:', e.message); process.exit(1); });
