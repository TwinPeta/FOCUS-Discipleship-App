const http = require('http');
const config = require('./config');
const { createApp } = require('./app');
const realtime = require('./realtime/socket');
const { seed, DEMO_PASSWORD } = require('./db/seed');
const store = require('./db/store');
const pg = require('./db/prisma');
const { ensureAdmin } = require('./db/bootstrap');

if (config.env === 'production' && config.jwtSecret === 'dev-only-change-me') {
  console.error('Refusing to start: set JWT_SECRET in production.');
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
  if (config.env === 'production' && !config.resendApiKey) console.warn('RESEND_API_KEY not set: emails will not be delivered.');
  if (config.env === 'production' && !config.r2Enabled) console.warn('R2_* not set: media is stored on local disk.');

  // With a database, demo data is loaded only into an empty database (never on top of real data).
  if (config.seedDemoData && !store.col('users').length) {
    seed();
    await pg.flush();
    console.log(`Demo data loaded. Test accounts: student@fcu.test, mentor@fcu.test, super@fcu.test (password: ${DEMO_PASSWORD})`);
  }

  const admin = ensureAdmin();
  if (admin) { console.log(`System admin created: ${admin.email}`); await pg.flush(); }

  const server = http.createServer(createApp());
  realtime.attach(server);
  server.listen(config.port, () => console.log(`FCU API listening on ${config.baseUrl}/v1`));

  setInterval(() => pg.flush(), 5000).unref(); // safety net for changes made outside a request (e.g. websocket handlers)

  const shutdown = () => server.close(async () => { await pg.close().catch((e) => console.error(e.message)); process.exit(0); });
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}
main().catch((e) => { console.error('Startup failed:', e); process.exit(1); });
