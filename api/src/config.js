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
  // Sliding: every refresh issues a new token with a fresh lifetime, so a student who opens the app stays signed in
  // until they log out. Only a year without opening it ends the session.
  refreshTtlDays: Number(process.env.REFRESH_TOKEN_TTL_DAYS || 365),
  // Back-office (staff) sessions live on the server: an opaque cookie, looked up on every request.
  // Idle timeout slides with activity; the absolute limit cannot be extended.
  staffSession: {
    idleHours: Number(process.env.STAFF_SESSION_IDLE_HOURS || 8),
    rememberDays: Number(process.env.STAFF_SESSION_REMEMBER_DAYS || 7),
    maxDays: Number(process.env.STAFF_SESSION_MAX_DAYS || 30),
  },

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
  // Optional: where replies go (the sender address is usually a no-reply one). Used by guardian consent emails.
  mailReplyTo: process.env.MAIL_REPLY_TO || '',
  // Resend allows about 2 requests a second; emails are sent one at a time at this pace, and retried when Resend says "slow down".
  mailGapMs: Number(process.env.MAIL_GAP_MS || 600),
  // NOTIFICATION_EMAILS=false stops notifications (replies, approvals, announcements...) from being emailed; in-app ones continue.
  notificationEmails: process.env.NOTIFICATION_EMAILS !== 'false',
  // Phone push (Firebase Cloud Messaging, which delivers to Android and, with an APNs key added in Firebase, to iPhones).
  // Give the service-account key as JSON in FCM_SERVICE_ACCOUNT_JSON, or as a file path in FCM_SERVICE_ACCOUNT_FILE.
  // Unset -> no push is sent (in-app and email continue). PUSH_ENABLED=false switches it off even when configured.
  fcm: {
    serviceAccountJson: process.env.FCM_SERVICE_ACCOUNT_JSON || '',
    serviceAccountFile: process.env.FCM_SERVICE_ACCOUNT_FILE || '',
    enabled: process.env.PUSH_ENABLED !== 'false',
  },
  // API documentation (Swagger UI at /docs, specs at /openapi.yaml and /openapi-admin.yaml).
  // DOCS_ENABLED=false removes them. DOCS_USERNAME + DOCS_PASSWORD put them behind HTTP Basic auth.
  // "Try it out" is on in development and off in production unless DOCS_TRY_IT_OUT=true.
  docsEnabled: process.env.DOCS_ENABLED !== 'false',
  docsUser: process.env.DOCS_USERNAME || '',
  docsPass: process.env.DOCS_PASSWORD || '',
  docsTryItOut: process.env.DOCS_TRY_IT_OUT ? process.env.DOCS_TRY_IT_OUT === 'true' : env !== 'production',
  backofficeUrl: (process.env.BACKOFFICE_URL || 'http://localhost:3000').replace(/\/$/, ''),
};
module.exports.r2Enabled = !!(module.exports.r2.accountId && module.exports.r2.accessKeyId && module.exports.r2.secretAccessKey && module.exports.r2.bucket);
