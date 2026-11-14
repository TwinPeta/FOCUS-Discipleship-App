require('dotenv').config();

const port = Number(process.env.PORT || 4000);

const env = process.env.NODE_ENV || 'development';
const list = (v) => (v || '').split(',').map((s) => s.trim().replace(/\/$/, '')).filter(Boolean);

module.exports = {
  env,
  // Allowed browser origins. Non-production: any origin is reflected unless CORS_ORIGINS is set.
  // Production: only CORS_ORIGINS (+ BASE_URL's origin); requests without an Origin header always pass.
  corsOrigins: list(process.env.CORS_ORIGINS),
  corsOpen: env !== 'production' && list(process.env.CORS_ORIGINS).length === 0,
  port,
  baseUrl: process.env.BASE_URL || `http://localhost:${port}`,
  jwtSecret: process.env.JWT_SECRET || 'dev-only-change-me',
  accessTtl: process.env.ACCESS_TOKEN_TTL || '15m',
  accessTtlSeconds: 900,
  refreshTtlDays: Number(process.env.REFRESH_TOKEN_TTL_DAYS || 30),
  seedDemoData: process.env.SEED_DEMO_DATA !== 'false',

  // PostgreSQL. Unset -> in-memory only (dev/tests).
  databaseUrl: env === 'test' ? '' : process.env.DATABASE_URL || '', // tests never touch a real database

  // Cloudflare R2 (S3-compatible). Unset -> local disk ./uploads (dev/tests).
  r2: {
    accountId: process.env.R2_ACCOUNT_ID || '',
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || '',
    bucket: process.env.R2_BUCKET || '',
    // Public bucket domain / custom domain, e.g. https://cdn.example.com. Empty -> short-lived signed GET URLs.
    publicUrl: (process.env.R2_PUBLIC_URL || '').replace(/\/$/, ''),
  },

  // Resend. Unset -> emails are logged (dev) / captured (tests).
  resendApiKey: process.env.RESEND_API_KEY || '',
  mailFrom: process.env.MAIL_FROM || 'FCU Student Community <no-reply@localhost>',
  backofficeUrl: (process.env.BACKOFFICE_URL || 'http://localhost:3000').replace(/\/$/, ''),
};
module.exports.r2Enabled = !!(module.exports.r2.accountId && module.exports.r2.accessKeyId && module.exports.r2.secretAccessKey && module.exports.r2.bucket);
