# FCU Mobile API (Node.js / Express)

Implements every endpoint in [`../docs/api/openapi.yaml`](../docs/api/openapi.yaml) for the FCU Student Community mobile app.

## Run

```bash
cd backend
npm install
cp .env.example .env     # optional; defaults work for local dev
npm run dev              # http://localhost:4000/v1  (npm start for no file-watching)
npm test                 # integration tests, no external services needed
```

There is no demo data in the app. Locally the API starts empty (in memory): create the first admin with
`ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='a-long-password' npm run dev`, sign in to the back office, and add institutions,
communities and content there. The integration tests build their own fixture world in `test/helpers/seed.js`
(accounts such as `super@fcu.test`, test password `Password123!`); it is never loaded by the server.

## Layout

```
backend/
├── package.json
├── .env.example
├── uploads/                  # local media storage (git-ignored)
├── src/
│   ├── server.js             # http server + WebSocket
│   ├── app.js                # express app, security headers, /uploads, error handling
│   ├── config.js             # env config
│   ├── db/
│   │   ├── store.js          # in-memory store (swap for a real DB)
│   ├── middleware/
│   │   ├── auth.js           # JWT auth, community membership + role checks
│   │   ├── error.js          # RFC 7807 problem+json
│   │   ├── rateLimit.js      # login / OTP / register throttling
│   │   └── idempotency.js    # Idempotency-Key replay
│   ├── realtime/socket.js    # /v1/realtime WebSocket, presence
│   ├── routes/               # one module per API area
│   │   ├── auth.js  lookups.js  landing.js  me.js
│   │   ├── communities.js  posts.js  prayer.js  testimonies.js
│   │   ├── pathways.js  resources.js  messages.js
│   │   └── safety.js  media.js  devices.js
│   └── utils/                # errors, validate, pagination, serialize, activity/badges, pathways
└── test/api.test.js
```

## What is real vs. a stand-in

Implemented and tested: auth + token rotation, minors/guardian rule, auto General membership, one-specific-community rule with super-mentor approval, feed/likes/comments, anonymous prayer requests, moderated testimonies, pathways with quiz gating and badges, resources/quizzes, messaging with unread counts, minor-messaging restriction and blocking, reports, media upload, push-token registration, WebSocket presence and message events.

**Stand-ins to replace before production:**

1. **Storage (PostgreSQL via Prisma)** – set `DATABASE_URL` (add `?sslmode=require` for hosted databases), then:
   ```bash
   npm run db:deploy   # create the 44 tables (prisma/migrations) — needs an EMPTY database or schema
   npm run db:seed     # first admin from ADMIN_EMAIL / ADMIN_PASSWORD (add -- --institutions to load the school list in prisma/institutions.json)
   ```
   Tables are real relational tables: typed columns, foreign keys (cascade / set null), unique constraints and indexes. Their layout lives in `prisma/spec.js`; `npm run prisma:schema` regenerates `prisma/schema.prisma` from it, and `npx prisma migrate dev --name <change>` creates the migration. Fields with no column are kept in each table's `extra` jsonb column, so nothing is lost. On boot the API loads the tables into memory and writes changes back within ~150 ms of any write request, every 5 s, and on shutdown (parents before children). Without `DATABASE_URL` it stays in-memory (tests/dev). Limits: single API instance only, the dataset must fit in RAM, a crash can lose the last ~150 ms, and statuses/roles are plain text columns (validated by the API, not DB enums). Next step as data grows: query the tables directly instead of the in-memory copy.
   **First admin in production:** set `ADMIN_EMAIL`, `ADMIN_PASSWORD` (10+ chars) and optionally `ADMIN_NAME`; the API creates a system admin on boot if none exists (never changes an existing account). Remove the password from the env afterwards.
2. **Email (Resend)** – set `RESEND_API_KEY` and `MAIL_FROM` (an address on a domain verified in Resend), and `BACKOFFICE_URL` (the back office address: reset and invite emails link to it). Optional `MAIL_REPLY_TO`. Sent: email OTP codes, staff password resets, staff invites, "check in" reminders, guardian consent reminders (when the minor gave a guardian email), and notifications (replies, approvals, warnings, announcements...) to people who chose email in their settings. Staff control each trigger in the back office (Notifications): on or off, in-app and/or email, and the wording, using `{{member_name}}`, `{{community_name}}`, `{{item_title}}` and `{{message_preview}}`. The triggers that fire: join request approved or declined, new announcement, prayer received (email off by default), testimony reviewed (published, or what to change), new report (emailed to the community's super-mentor), and an automatic "we miss you" for people away longer than the inactivity threshold (checked every 6 hours; only people who switched inactivity reminders on, since they are muted by default). `NOTIFICATION_EMAILS=false` switches all notification emails off. Emails go out one at a time (`MAIL_GAP_MS`, default 600 ms, to respect Resend's rate limit) and are retried on rate limits and server errors. Without a key emails are logged (dev) or dropped with an error (production); at startup the API warns about settings that would break emails. **Still not emailed:** the data-export copy ("we will email you a copy" is a manual process), meeting reminders, scheduled report emails and SMS OTP (stand-ins).
3. **Media (Cloudflare R2)** – set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` (and `R2_PUBLIC_URL` for a public bucket/custom domain; otherwise 1-hour signed URLs are used). `POST /v1/media` then returns a signed R2 URL to `PUT` to directly (headers: `Content-Type` only). The API confirms the upload with R2 when the media is used, or via the optional `POST /v1/media/:id/complete`. Set a CORS rule on the bucket allowing `PUT` from your app origins. Still missing: malware scanning and video transcoding.
4. **Rate limiting / idempotency cache** – in-process; use Redis when running more than one instance.
5. **Phone push (Firebase)** – set `FCM_SERVICE_ACCOUNT_FILE` (path to the Firebase service-account key) or `FCM_SERVICE_ACCOUNT_JSON`. Every notification that lands in a person's inbox is also pushed to their registered phones (`POST /v1/devices`); dead tokens are removed automatically. Without a key nothing is sent. `PUSH_ENABLED=false` switches it off. System admins can check status and send a test from Settings in the back office. Full setup, including the iPhone steps: `docs/push-notifications.md`.
6. **Secrets** – set a strong `JWT_SECRET`; the server refuses to start in production with the default.
7. **Guardian consent confirmation, admin/moderator endpoints, testimony approval** – not in the mobile spec; testimonies stay `pending_review` until an admin API exists.

Notes: a request to an unknown `/v1/...` path returns 401 without a token (the auth wall precedes routing).

## Back-office (staff) API

Mounted at `/v1/admin` (spec: `docs/api/openapi-admin.yaml`, Swagger UI at `/docs`). It serves every endpoint the
Next.js back office calls through `/api/proxy`, so point the back office at it with:

```
API_BASE_URL=http://localhost:4000/v1/admin
```

- Login: `POST /v1/admin/auth/login {email,password,rememberMe}` creates a server-side session and sets one httpOnly `fcu_access` cookie (opaque id, looked up on every request; see `src/admin/sessions.js`)
  (the proxy passes `Set-Cookie` through). Staff accounts are created in the back office (the first admin comes from `ADMIN_EMAIL` / `ADMIN_PASSWORD`).
- Uploads: `POST /v1/admin/media` -> file goes to R2 (signed URL) or, in local dev, through the API -> `POST /v1/admin/media/{id}/complete` returns the permanent `/uploads/<id>` address that content records store.
  With R2, add a CORS rule on the bucket allowing `PUT` from the back-office origin (e.g. `https://backoffice.focusuganda.org`) with the `Content-Type` header, or browser uploads are blocked.
- Roles are enforced server-side; super-mentors are scoped to their own communities (out of scope = 404).
- Staff actions that matter (role changes, publishing, moderation, privacy requests, settings) are written to the audit log.
- Same in-memory store as the mobile API; data resets on restart.

## API documentation

| URL | What |
|---|---|
| `/docs` | Swagger UI (assets are bundled, nothing loads from a CDN; strict CSP) with a selector for both APIs |
| `/openapi.yaml` | Mobile API, OpenAPI 3.1, base path `/v1` |
| `/openapi-admin.yaml` | Staff (back office) API, base path `/v1/admin` |

The specs live in [`../docs/api`](../docs/api) and are the source of truth for both clients. The server points the first
`servers` entry at itself, so "Try it out" always hits the environment you are reading.

**Production settings** (`.env`):

| Variable | Effect |
|---|---|
| `DOCS_ENABLED=false` | Remove `/docs` and both spec files |
| `DOCS_USERNAME` + `DOCS_PASSWORD` | Put all three behind HTTP Basic auth (compared in constant time). The API itself is unaffected. The server warns at start-up if production runs without them |
| `DOCS_TRY_IT_OUT=true` | Allow "Try it out" in production (off by default there: it sends real requests) |

**The docs cannot drift from the code.** `npm test` fails when:
- a spec is not valid OpenAPI,
- a route exists that is not documented, or a documented operation does not exist,
- an operation has no `operationId`, summary, declared tag or success response, or a tag has no description,
- any response a test receives has an undocumented success status or does not match its documented schema,
- a documented operation is never called by a test.

When you add an endpoint: add it to the spec, call it from a test (`test/api.test.js` or `test/admin.test.js`), and `npm test`.
`CONTRACT_SAMPLES=/tmp/samples.json npm test` also saves every JSON response, which is handy for writing schemas from real data.
