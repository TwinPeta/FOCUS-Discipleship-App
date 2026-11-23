const http = require('http');
const config = require('./config');
const { createApp } = require('./app');
const realtime = require('./realtime/socket');
const store = require('./db/store');
const pg = require('./db/prisma');
const { ensureAdmin } = require('./db/bootstrap');

// Tokens are signed with JWT_SECRET (HS256): in production it must be set and
// long enough not to be guessed (the deploy scripts make a 96-character one).
if (config.env === 'production' && (config.jwtSecret === 'dev-only-change-me' || config.jwtSecret.length < 32)) {
  console.error('Refusing to start: set a strong JWT_SECRET (at least 32 characters) in production.');
  process.exit(1);
}

async function main() {
  if (pg.enabled()) {
    await pg.init();
    const n = await pg.load();
    console.log(`PostgreSQL connected; loaded ${n} records.`);
  } else {
    console.warn('DATABASE_URL not set: using the in-memory store (data is lost on restart).');
  }
  const healed = require('./utils/joinRequests').reconcile();
  if (healed) { console.log(`Repaired ${healed} join request/membership records that disagreed.`); await pg.flush(); }
  for (const problem of require('./services/mailer').configProblems()) console.warn(`[config] ${problem}`);
  if (config.env === 'production' && /localhost/.test(config.baseUrl)) console.warn(`[config] BASE_URL is ${config.baseUrl}: uploaded file links and error links would point at it. Set it to the public API address.`);
  if (config.env === 'production' && !config.r2Enabled) console.warn('R2_* not set: media is stored on local disk.');

  const admin = ensureAdmin();
  if (admin) { console.log(`System admin created: ${admin.email}`); await pg.flush(); }

  const server = http.createServer(createApp());
  realtime.attach(server);
  server.listen(config.port, () => console.log(`FCU API listening on ${config.baseUrl}/v1`));

  setInterval(() => require('./utils/inactivity').run(), 6 * 3600e3).unref(); // "we miss you" reminders
  setInterval(() => require('./utils/announcements').publishDue(), 60e3).unref(); // scheduled announcements go out on time
  setInterval(() => require('./admin/sessions').sweep(), 3600e3).unref(); // forget expired back-office sessions
  setInterval(() => pg.flush(), 15000).unref(); // safety net for changes made outside a request (e.g. websocket handlers)

  const shutdown = () => server.close(async () => { await pg.close().catch((e) => console.error(e.message)); process.exit(0); });
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}
main().catch((e) => { console.error('Startup failed:', e); process.exit(1); });
