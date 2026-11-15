# FCU Mobile API — guide for app developers

How the Flutter app (`mobile/`) talks to the backend at **https://apis.focusuganda.org**. Read this first; then use the generated reference for exact fields.

| Document | What it is |
|---|---|
| **This guide** | How to connect: auth, tokens, errors, uploads, realtime, rules, and what the app uses today |
| [`mobile-api-reference.md`](./mobile-api-reference.md) | **Every** Mobile API endpoint (85) with parameters, request fields, responses, schemas, and whether the app calls it. Generated. |
| [`admin-api-reference.md`](./admin-api-reference.md) | Every Back Office (staff) API endpoint (87). Generated. Not used by the app. |
| [`openapi.yaml`](./openapi.yaml), [`openapi-admin.yaml`](./openapi-admin.yaml) | Source of truth (OpenAPI 3.1) |
| Live docs | https://apis.focusuganda.org/docs (Swagger UI; pick **Mobile API** or **Back Office (staff) API**) |
| [`README.md`](./README.md) | Business rules and the screen-to-endpoint map |

Regenerate the two references after any spec change:
```bash
npm install --prefix /tmp/oa js-yaml
NODE_PATH=/tmp/oa/node_modules node docs/api/tools/openapi_to_markdown.js docs/api/openapi.yaml docs/api/mobile-api-reference.md --app-src mobile/lib
NODE_PATH=/tmp/oa/node_modules node docs/api/tools/openapi_to_markdown.js docs/api/openapi-admin.yaml docs/api/admin-api-reference.md
```

---

## 1. Servers and environments

| Environment | Base URL | Notes |
|---|---|---|
| Production / staging | `https://apis.focusuganda.org/v1` | `GET /v1/health` returns `{"status":"ok"}` (checked 2026-11-15) |
| Local backend | `http://localhost:4000/v1` | `cd api && npm run dev`; demo accounts below |
| Android emulator → local | `http://10.0.2.2:4000/v1` | the emulator's alias for your computer |
| Staff API | `<base>/admin` | Back Office only |

### Choosing the backend in the app
The base URL is set **at build time** (`mobile/lib/core/config/api_config.dart`). With no value, the app runs on its built-in fake data (tests and the offline demo).
```bash
flutter run --dart-define=API_BASE_URL=https://apis.focusuganda.org/v1          # real backend
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1                 # local backend, Android emulator
flutter run                                                                    # fake data, no backend
flutter build apk --debug --dart-define=API_BASE_URL=https://apis.focusuganda.org/v1
```
CI: set the GitHub repository **variable** `API_BASE_URL` to build the APK against the real backend; leave it unset for the offline demo (`.github/workflows/mobile-apk.yml`).

### Demo accounts (local backend seed; password `Password123!`)
| Account | Role |
|---|---|
| `student@fcu.test` | Student without a specific community (try joining) |
| `david@fcu.test` | Student in Growth Circle |
| `mentor@fcu.test` | Mentor in Growth Circle |
| `super@fcu.test` | Super-mentor of Growth Circle (approves join requests) |

These exist when the server runs with demo data (`SEED_DEMO_DATA`, on by default locally). Ask the backend owner which accounts exist on production before testing there.

---

## 2. Authentication and sessions

```
POST /auth/register  or  POST /auth/login   ->  { access_token (JWT, 15 min), refresh_token }
every call:  Authorization: Bearer <access_token>
on 401:      POST /auth/refresh { refresh_token }  ->  new access_token AND new refresh_token
refresh 401: sign the user out
sign out:    POST /auth/logout
```
- **Refresh tokens rotate:** each one works once, so always store the new one.
- **Email verification:** `POST /auth/otp/request` then `POST /auth/otp/verify`.
- **Username check:** `GET /auth/username-available?username=`.
- **Minors:** send `guardian` at register or later with `PUT /me/guardian`. Until confirmed, messaging adults is blocked (`403 messaging_restricted`).

**In the app** (`mobile/lib/core/network/api_client.dart`): `ApiClient` adds the bearer token, refreshes once on a `401` (concurrent `401`s share one refresh), then retries. Requests time out after **20 s**. `TokenStore` keeps tokens **in memory only**, so closing the app signs the user out. Persisting them in `flutter_secure_storage` is on the backlog (needs package approval).

---

## 3. Request conventions

| Topic | Rule | App status |
|---|---|---|
| Format | JSON over HTTPS, UTF-8, `/v1` | done |
| Times / ids | ISO-8601 UTC; ids are opaque strings, never parse them | done |
| Pagination | cursor: `?limit=` (default 20, max 100) + `?cursor=`; response `next_cursor` (`null` = last page) | `ApiClient.getAllItems` follows cursors |
| Caching | `GET` returns a weak `ETag`; send `If-None-Match` → `304` | not used yet (helps slow connections) |
| Idempotency | `Idempotency-Key: <uuid>` on POSTs that create posts, prayer requests, messages and reports. A retry with the same key returns the original (`Idempotent-Replay: true`); keys last 24 h | sent on all four; the message key includes the current time, so a retry gets a new key (see section 9) |
| Uploads | see section 5 | done (photos) |
| Realtime | optional WebSocket, section 6 | not used yet |

---

## 4. Errors

Errors are RFC 7807 `application/problem+json` with a stable **`code`**. Branch on `code`, not on the text.
```json
{ "type": "https://apis.focusuganda.org/errors/validation_failed", "title": "Validation failed",
  "status": 422, "code": "validation_failed", "detail": "One or more fields are invalid",
  "errors": [ { "field": "password", "message": "must be at least 8 characters" } ] }
```

| Status | Meaning | Codes |
|---|---|---|
| 400 | malformed request | `invalid_json`, `otp_invalid`, `empty_body` |
| 401 | missing, invalid or expired token | `unauthorized` |
| 403 | signed in, but not allowed | `forbidden`, `account_suspended`, `messaging_restricted`, `blocked`, `wrong_institution`, `pathway_locked`, `direct_upload_required` |
| 404 | not found, or not a member of that community | `not_found`, `route_not_found` |
| 409 | conflicts with current state | `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`, `not_enrolled`, `not_pending`, `not_joinable`, `not_leavable`, `super_mentor_cannot_leave`, `already_checked_in`, `check_in_closed`, `case_closed`, `no_target`, `upload_incomplete`, `already_uploaded` |
| 413 | body or file too large | `payload_too_large` |
| 422 | validation; `errors[]` lists `{field, message}` | `validation_failed` |
| 429 | too many requests; wait `Retry-After` seconds | `rate_limited` |
| 500 | server error; reads are safe to retry | `internal_error` |

**In the app:** `ApiClient` turns these into `ApiException` (`status`, `code`, `detail`); network failures (offline, DNS, timeout) are also an `ApiException` without a status.

**Rate limits** (per IP, and per identifier where noted): register 20/hour; login 20 per 15 min per identifier; OTP request 5 per 10 min per destination; OTP verify 20 per 10 min. Honour `Retry-After` on sign-in screens.

**Account states:** suspended accounts are read-only (`GET` works, changes return `403 account_suspended`); deleted accounts cannot sign in.

---

## 5. Uploading photos

```
1. POST /media { purpose, content_type, size_bytes }  -> { media_id, upload_url, upload_headers }
2. PUT  <upload_url>  (file bytes, with upload_headers)
3. POST /media/{media_id}/complete
4. attach media_id: post (media_ids, max 4), testimony, report, or profile photo
```
- `purpose`: `profile_photo`, `post_photo`, `testimony_photo`, `testimony_video`, `report_evidence`.
- Accepted: JPEG, PNG, WebP, HEIC, server limit **10 MB**. The app compresses to quality 80, ≤ 1600 px and refuses anything over **2 MB** first (`mobile/lib/core/media/upload_policy.dart`).
- `PUT /media/{mediaId}/upload` is the server's own upload target (what `upload_url` points to locally); the app always uses the returned `upload_url`.
- In the app: `mobile/lib/core/network/media_uploader.dart`.

---

## 6. Realtime

`GET /v1/realtime?token=<access_token>` upgraded to a WebSocket. The server pushes JSON events:

| Event | Use |
|---|---|
| `message.created`, `message.read` | live chat and unread counts |
| `presence.updated` | community `online_count` |
| `join_request.decided` | show the approved/declined screen without polling |
| `notification.created` | bell dot |

Everything is also available by polling REST, so the socket is an optimisation. **The app uses it** (`mobile/lib/core/realtime/`): it connects while signed in (`wss://<host>/v1/realtime?token=<access_token>`, built from `API_BASE_URL`), reconnects with 1, 2, 5, 10, 30 s backoff, refreshes the token once on a `4401` close, and disconnects on sign-out. `notification.created` refreshes the bell (the 60 s poll stays as a fallback) and shows a phone notification; `message.created`/`message.read` refresh the inbox and the open conversation; `join_request.decided` (and a `request_approved`/`request_declined` `notification.created`) refreshes the membership, which is also re-read on the 60 s poll interval while a request is pending; `DELETE /join-requests/{requestId}` backs "Cancel request" on the community detail screen; `presence.updated` is stored per community but not shown yet (the header still shows a placeholder count).

---

## 7. Rules the server enforces (do not duplicate them as the only check)

1. Everyone is put in their institution's **General community** at registration.
2. **One specific community** per user (`409 community_limit_reached`); the super-mentor approves (`POST /join-requests/{id}/decision`).
3. **Testimonies** start `pending_review`; only published resources reach students.
4. **Minors** can't message unverified adults (`403 messaging_restricted`).
5. **Anonymous prayer requests** return `author: null`.
6. **My activity** (`GET /me/activity`) is private to its owner.
7. **Blocking** hides people everywhere; **reports** can target a user, message, post, comment, testimony or prayer request.

---

## 8. Endpoint map by area (85 operations)

Full detail for each: [`mobile-api-reference.md`](./mobile-api-reference.md). App repositories live in `mobile/lib/features/*/data/remote_*_repository.dart`.

| Area | Endpoints | App repository |
|---|---|---|
| System | `GET /health` | — |
| Landing | `GET /public/landing` | `remote_stories_repository` |
| Auth | `GET /auth/username-available`, `POST /auth/register`, `/login`, `/otp/request`, `/otp/verify`, `/refresh`, `/logout` | `remote_auth_repository`, `api_client` (refresh) |
| Lookups | `GET /lookups/countries`, `/lookups/institutions` | `remote_profile_repository` |
| Profile (`/me`) | profile get/update/delete, export, guardian, communities, notifications + read, preferences, warnings + acknowledge, suspension, activity | profile, privacy, notification, warning, suspension, activity repositories |
| Communities | list, detail, members, meetings, going, check-in, join request, leave, cancel request, my join requests | community, membership, member, meeting repositories |
| Mentor tools | moderation cases + action, members last-active, join requests + decision | join-request, moderation-queue, activity repositories |
| Feed | posts list/create/get/edit/delete, like/unlike, comments list/create | `remote_post_repository` |
| Prayer | requests list/create/get, prayed/unprayed, responses list/create | `remote_prayer_repository` |
| Testimonies | list/create/get | `remote_testimony_repository` |
| Pathways | list/get, enrollment, complete step | `remote_pathway_repository` |
| Resources | list/get, progress, quiz get, quiz attempt | resource, learning repositories |
| Messages | conversations list/create, messages list/send, read, realtime | `remote_messaging_repository` |
| Safety | reports, my blocks, block/unblock | report, moderation repositories |
| Media | create slot, complete, direct upload | `media_uploader` |
| Devices | register / remove push token | — (push not built) |

**Not called by the app today (3):** `GET /health`, `GET /lookups/countries` (the app uses its own country list), `PUT /media/{mediaId}/upload` (by design; the app uses `upload_url`). `POST /devices` + `DELETE /devices/{deviceId}` are wired (`core/push/device_registration.dart`) but only fire once a push token source exists (Firebase); today the app has none.

---

## 9. Gaps and mismatches found while writing this (2026-11-15)

| # | Finding | Who | Suggested fix |
|---|---|---|---|
| 1 | The **live** spec lists `http://localhost:4000/v1` as "This server (production)", so Swagger's "Try it" server list points at localhost | backend | serve the public URL as the production server entry |
| 2 | Upload limits disagree: conventions say photos only, 10 MB; `POST /media` says images ≤ 10 MB and **video ≤ 200 MB**. The roadmap wants documents ≤ 10 MB (review item 5) | backend + B1.4 | one rule: photos ≤ 10 MB server-side (app sends ≤ 2 MB), documents (PDF/DOC/PPT) ≤ 10 MB, no video for now |
| 3 | Password minimum: server **8**, app **10** characters | product | pick one; the app being stricter is safe for now |
| 4 | Text limits: server allows posts up to 5000 characters, the app stops at 2000 | product | fine (app stricter); align if longer posts are wanted |
| 5 | Tokens are in memory only, so users sign in again after closing the app | app | `flutter_secure_storage` (needs approval) |
| 6 | ETag/`If-None-Match` is supported by the server but not used by the app. Realtime is now used (section 6) | app | add ETags when tuning for slow connections |
| 6b | The message `Idempotency-Key` is built from the current time (`remote_messaging_repository.dart`), so a retried send gets a new key and can create a duplicate | app | generate the key once per message (like posts and prayer requests do) |
| 7 | Roadmap v2 needs new endpoints that don't exist yet: questions and answers, search, resources in the General community, notification delivery (J1–J5). Push: the server stores device tokens but has no sender and there is no Firebase project, so phone notifications are local (from the socket, while the app runs) | backend | see `mobile/docs/roadmap_v2.md`; for push add a Firebase project, a sender, and a `FirebasePushTokenSource` in the app |

### Join requests: backend gaps found 2026-11-15 (app side fixed in `8d63c87`)
| # | Finding | Suggested fix |
|---|---|---|
| B1 | `POST /communities/:id/join-requests` does not notify the community's super-mentor at all (no notification type, no socket event). The app polls the pending list while Manage or Join requests is open, as a stopgap | add a `join_request_created` notification (+ socket event) to the super-mentor |
| B2 | Back-office decisions (`api/src/admin/people.js` `decide`, including bulk approve) send the socket event but never call `notify()`: the student gets no notification or email | call the same notify as `POST /join-requests/:id/decision` |
| B3 | `join_request.decided` goes only to a connected socket and is never replayed | fine as an optimisation; the app now also polls membership while pending |
| B4 | A student who muted "join request updates" or turned in-app off gets no record of the decision (the socket event still arrives) | consider always recording decisions, or document it |
| B5 | `GET /me/communities` gives a pending membership only as `membership_status`, without the request id; the app must call `GET /me/join-requests` to cancel | include `join_request_id` |

