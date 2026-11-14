// PM2 process file for the API (Express).  https://apis.focusuganda.org -> 127.0.0.1:4000
//
// Secrets do NOT go in this file. Put them in api/.env on the server (it is git-ignored and read by the app):
//   JWT_SECRET, DATABASE_URL, R2_*, RESEND_API_KEY, MAIL_FROM, ADMIN_EMAIL, ADMIN_PASSWORD (first boot only)
//
//   cd <repo>/api
//   npm ci --omit=dev               # also runs `prisma generate`
//   npm run db:deploy               # apply database migrations (first deploy and after schema changes)
//   pm2 start ecosystem.config.js
//   pm2 save
module.exports = {
  apps: [
    {
      name: "focus-api",
      cwd: __dirname,
      script: "src/server.js",
      // MUST stay a single process: the API keeps its working data and WebSocket state in memory and is the
      // only writer to the database. Cluster mode / multiple instances would corrupt data.
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      max_memory_restart: "800M",
      kill_timeout: 10000, // lets the API flush pending changes to PostgreSQL on SIGTERM
      time: true,
      env: {
        NODE_ENV: "production",
        PORT: 4000,
        BASE_URL: "https://apis.focusuganda.org",
        // Browsers allowed to call the API (CORS)
        CORS_ORIGINS: "https://backoffice.focusuganda.org,https://discipleship.focusuganda.org",
        // Used in password-reset and invite emails
        BACKOFFICE_URL: "https://backoffice.focusuganda.org",
        // Demo data is for development only
        SEED_DEMO_DATA: "false",
      },
    },
  ],
};
