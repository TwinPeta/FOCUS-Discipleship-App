# FCU Mobile API (Node.js / Express)

Implements every endpoint in [`../docs/api/openapi.yaml`](../docs/api/openapi.yaml) for the FCU Student Community mobile app.

## Run

```bash
cd backend
npm install
cp .env.example .env     # optional; defaults work for local dev
npm run dev              # http://localhost:4000/v1  (npm start for no file-watching)
npm test                 # 13 integration tests, no external services needed
```

Demo data is loaded on start (`SEED_DEMO_DATA=false` to disable). All demo accounts use the **test** password `Password123!`:

| Account | Role |
|---|---|
| `student@fcu.test` | Student with no specific community yet (try the join flow) |
| `david@fcu.test` | Student, already in Growth Circle |
| `mentor@fcu.test` | Mentor in Growth Circle |
| `super@fcu.test` | Super-mentor of Growth Circle (approves join requests) |

## Layout

```
backend/
├── package.json
├── .env.example
├── uploads/                  # local media storage (git-ignored)
├── src/
│   ├── server.js             # http server + WebSocket + demo seed
│   ├── app.js                # express app, security headers, /uploads, error handling
│   ├── config.js             # env config
│   ├── db/
│   │   ├── store.js          # in-memory store (swap for a real DB)
│   │   └── seed.js           # demo data
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
   npm run db:seed     # demo data (only into an empty database) + first admin from ADMIN_EMAIL / ADMIN_PASSWORD
   ```
   Tables are real relational tables: typed columns, foreign keys (cascade / set null), unique constraints and indexes. Their layout lives in `prisma/spec.js`; `npm run prisma:schema` regenerates `prisma/schema.prisma` from it, and `npx prisma migrate dev --name <change>` creates the migration. Fields with no column are kept in each table's `extra` jsonb column, so nothing is lost. On boot the API loads the tables into memory and writes changes back within ~150 ms of any write request, every 5 s, and on shutdown (parents before children). Without `DATABASE_URL` it stays in-memory (tests/dev). Limits: single API instance only, the dataset must fit in RAM, a crash can lose the last ~150 ms, and statuses/roles are plain text columns (validated by the API, not DB enums). Next step as data grows: query the tables directly instead of the in-memory copy.
   **First admin in production:** set `ADMIN_EMAIL`, `ADMIN_PASSWORD` (10+ chars) and optionally `ADMIN_NAME`; the API creates a system admin on boot if none exists (never changes an existing account). Remove the password from the env afterwards.
2. **Email (Resend)** – set `RESEND_API_KEY` and `MAIL_FROM` (verified domain). Sent: email OTP codes, staff password resets, staff invites (set-password link), check-in reminders. Without a key emails are logged (dev) or dropped with an error (production). **SMS OTP is still a stand-in** (logged in dev). Scheduled report emails and notification rules are not sent yet.
3. **Media (Cloudflare R2)** – set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET` (and `R2_PUBLIC_URL` for a public bucket/custom domain; otherwise 1-hour signed URLs are used). `POST /v1/media` then returns a signed R2 URL to `PUT` to directly (headers: `Content-Type` only). The API confirms the upload with R2 when the media is used, or via the optional `POST /v1/media/:id/complete`. Set a CORS rule on the bucket allowing `PUT` from your app origins. Still missing: malware scanning and video transcoding.
4. **Rate limiting / idempotency cache** – in-process; use Redis when running more than one instance.
5. **Push notifications** – device tokens are stored but nothing sends pushes yet (FCM/APNs).
6. **Secrets** – set a strong `JWT_SECRET`; the server refuses to start in production with the default.
7. **Guardian consent confirmation, admin/moderator endpoints, testimony approval** – not in the mobile spec; testimonies stay `pending_review` until an admin API exists.

Notes: a request to an unknown `/v1/...` path returns 401 without a token (the auth wall precedes routing).

## Back-office (staff) API

Mounted at `/v1/admin` (spec: `docs/api/openapi-admin.yaml`, Swagger UI at `/docs`). It serves every endpoint the
Next.js back office calls through `/api/proxy`, so point the back office at it with:

```
API_BASE_URL=http://localhost:4000/v1/admin
NEXT_PUBLIC_API_MOCKING=disabled
```

- Login: `POST /v1/admin/auth/login {email,password,rememberMe}` sets httpOnly `fcu_access` / `fcu_refresh` cookies
  (the proxy passes `Set-Cookie` through). Demo staff (password `Password123!`): `admin@fcu.test` (system admin),
  `content@fcu.test` (content admin), `super@fcu.test` (super-mentor of Growth Circle + Life & Faith Circle).
- Roles are enforced server-side; super-mentors are scoped to their own communities (out of scope = 404).
- Staff actions that matter (role changes, publishing, moderation, privacy requests, settings) are written to the audit log.
- Same in-memory store as the mobile API; data resets on restart.
