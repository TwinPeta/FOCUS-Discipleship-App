// PM2 process file for the back office (Next.js).  https://backoffice.focusuganda.org -> 127.0.0.1:3001
//
//   cd <repo>/backoffice
//   pnpm install --frozen-lockfile
//   pnpm build                      # must be re-run whenever code or NEXT_PUBLIC_* values change
//   pm2 start ecosystem.config.js
//   pm2 save
module.exports = {
  apps: [
    {
      name: "focus-backoffice",
      cwd: __dirname,
      script: "pnpm",
      args: "run start",
      interpreter: "none",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      max_memory_restart: "700M",
      kill_timeout: 5000,
      time: true,
      env: {
        NODE_ENV: "production",
        PORT: 3001,
        HOSTNAME: "127.0.0.1", // only nginx talks to it
        NEXT_TELEMETRY_DISABLED: "1",
        // Server-side (read at runtime)
        API_BASE_URL: "https://apis.focusuganda.org/v1/admin",
        AUTH_ACCESS_COOKIE: "fcu_access",
        AUTH_REFRESH_COOKIE: "fcu_refresh",
        // Public values are baked in at BUILD time: export the same value when running `pnpm build`
        NEXT_PUBLIC_API_MOCKING: "disabled",
        NEXT_PUBLIC_APP_NAME: "FCU Backoffice",
      },
    },
  ],
};
