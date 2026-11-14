# API needs (draft for the backend developer)

Proposed endpoints the back office screens will call. The OpenAPI spec is the source of truth. All calls go through `/api/proxy`. Every list supports search, filters, sort and pagination. Super-mentor requests are scope-filtered server-side.

| Area | Endpoint | Screens |
|---|---|---|
| Auth | `POST /auth/login`, `/auth/logout`, `/auth/refresh`, `/auth/forgot-password`, `/auth/reset-password` | B10, B27, B28 |
| Me | `GET /me` (role, scope, capabilities), `PATCH /me`, `POST /me/password`, `GET/DELETE /me/sessions` | B25 |
| Dashboard | `GET /stats/overview`, `/stats/weekly-activity`, `/stats/attention`, `/members/inactive`, `POST /members/:id/reminder` | B1, B29 |
| Reports | `GET /stats/report`, `POST /reports/export`, `GET/POST/PATCH/DELETE /reports/schedules` | B20 |
| Institutions | `GET/POST /institutions`, `PATCH /institutions/:id` | B15 |
| Communities | `GET/POST /communities`, `GET/PATCH /communities/:id`, `PUT /communities/:id/cover`, `PUT /communities/:id/team` | B3, B14 |
| Join requests | `GET /join-requests`, `POST /join-requests/:id/approve`, `/decline`, `POST /join-requests/bulk-approve` | B2, B29 |
| Members | `GET /members`, `GET /members/:id`, `POST /members`, `POST /members/:id/role`, `/move`, `/suspend`, `/reinstate` | B4, B11 |
| Import | `POST /members/import/preview`, `POST /members/import/run` | B24 |
| Content | `GET/POST /content`, `GET/PATCH /content/:id`, `POST /content/:id/submit`, `/approve`, `/request-changes`, `/archive` | B5, B12 |
| Uploads | resumable video upload endpoint (tus or S3 multipart), `POST /media/images` | B12, B3, B8 |
| Quizzes | `PUT /content/:id/quiz` (questions, options, pass mark, show-answers rule) | B13 |
| Bible links | `GET /bible-links?q=` | B5, B12, B13 |
| Pathways | `GET/POST /pathways`, `GET/PATCH /pathways/:id`, `PUT /pathways/:id/steps`, `POST /pathways/:id/publish` | B6 |
| Badges | `GET/POST /badges`, `PATCH /badges/:id` | B21 |
| Announcements | `GET/POST /announcements`, `PATCH /announcements/:id` | B8 |
| Stories | `GET/POST /stories`, `PATCH /stories/:id`, `PUT /stories/order` | B8 |
| Notifications | `GET /notification-rules`, `PATCH /notification-rules/:id`, `GET/PUT /notification-templates/:id` | B22 |
| Moderation | `GET /moderation/reports`, `/testimonies`, `/posts`, `/sanctions`; `POST /moderation/:type/:id/action` (dismiss, warn, hide, escalate, suspend, delete, approve, request-changes, reject, reinstate) | B7, B16-B18 |
| Privacy | `GET /guardian-consents`, `POST /guardian-consents/:id/reminder`, `GET /data-requests`, `POST /data-requests/:id/process` | B23 |
| Roles | `GET /roles/matrix`, `POST /staff` | B9 |
| Audit | `GET /audit-log`, `POST /audit-log/export` | B26, B9 |
| Settings | `GET/PUT /settings/charter`, `/settings/consent-texts`, `/settings/minors`, `/settings/retention` | B19 |

## Cross-cutting
- Error shape: `{ code, message, fieldErrors?, correlationId }`
- `/me` returns capabilities and scope so the UI does not guess permissions
- Every action listed as audited must write an audit entry on the server (the UI notice is not enough)
- Counts for tabs (all, pending, ...) returned with list responses
- Idempotent bulk operations (bulk approve, import run) with per-row results
- Content responses include `author`, `validator`, `validatedAt`, `version`
