# FCU Student Community App – Mobile API

> **App developers:** start with [`MOBILE_API_GUIDE.md`](./MOBILE_API_GUIDE.md) (how to connect) and [`mobile-api-reference.md`](./mobile-api-reference.md) (every endpoint). Staff API: [`admin-api-reference.md`](./admin-api-reference.md).

Source of truth: [`openapi.yaml`](./openapi.yaml) (mobile) and [`openapi-admin.yaml`](./openapi-admin.yaml) (staff), both OpenAPI 3.1. The running API serves them with Swagger UI at `/docs`; `api/test/docs.test.js` and the contract checks in the API tests keep them in step with the code (see `api/README.md`).
Derived from the *FCU Student Community App – Mobile Design* (22 screens) and the *FOCUS Uganda BRD v0.4*.

## Conventions

| Topic | Rule |
|---|---|
| Base URL | `https://apis.focusuganda.org/v1` (production), `http://localhost:4000/v1` (local) |
| Auth | `Authorization: Bearer <JWT>`; access token 15 min, rotating refresh token |
| Pagination | `?limit=` (≤100) + `?cursor=`; response has `next_cursor` |
| Errors | RFC 7807 `application/problem+json` with a stable `code` |
| Idempotency | `Idempotency-Key` header on content-creating POSTs |
| Low connectivity | ETag / `If-None-Match` on lists; `offline_available` + `download_url` on resources |
| Realtime | WebSocket `/v1/realtime` (messages, presence, join-request decisions); push as fallback |

## Core business rules the API enforces

1. **Everyone joins the General community automatically** (by institution) at registration.
2. **Only one Specific community per user.** `POST /communities/{id}/join-requests` returns `409 community_limit_reached` if the user already has a pending or approved one. While pending, other communities are `can_request: false` (the "locked" state in the hub).
3. **Super-mentor approves join requests** (`POST /join-requests/{id}/decision`); the student is notified.
4. **Moderation before publication.** Testimonies are always `pending_review`; only `published` resources are returned to students.
5. **Minors** (`birthdate` < 18) register with `guardian` details, get `minor_status: pending_guardian_consent`, and are blocked from DMs with unverified adults (`403 messaging_restricted`).
6. **Anonymous prayer requests** return `author: null`; identity is only stored for moderators.
7. **My activity is private** – `/me/activity` is owner-only.
8. **Reports** can target a user, message, post, comment, testimony or prayer request; **block** is a separate call offered after "Report sent".

## Screen → endpoint map

| # | Screen | Endpoints |
|---|---|---|
| 1 | FCU landing | `GET /public/landing` |
| 2 | Join form (step 1/3) | `GET /lookups/countries`, `GET /lookups/institutions`, `GET /auth/username-available`, `POST /media` (photo), `POST /auth/register`, `POST /auth/otp/request` + `/verify` |
| 3 | Communities hub | `GET /me/communities`, `GET /communities?type=specific&q=` |
| 4 | Communities hub, request pending | `GET /me/communities` (`specific.membership_status = pending`), `GET /communities` (`can_request=false`), `DELETE /join-requests/{id}` |
| 5 | Community detail | `GET /communities/{id}`, `POST /communities/{id}/join-requests` |
| 6 | Community feed / 7. General community feed | `GET /communities/{id}/posts`, `PUT/DELETE /posts/{id}/like`, `GET/POST /posts/{id}/comments` |
| 8 | New post | `POST /media`, `POST /communities/{id}/posts` |
| 9 | Prayer wall | `GET /communities/{id}/prayer-requests`, `PUT/DELETE /prayer-requests/{id}/prayed`, `GET/POST /prayer-requests/{id}/responses` |
| 10 | New prayer request | `POST /communities/{id}/prayer-requests` (`anonymous`) |
| 11 | Testimonies | `GET /communities/{id}/testimonies`, `GET /testimonies/{id}` |
| 12 | Share your story | `POST /media`, `POST /communities/{id}/testimonies` |
| 13 | Pathways | `GET /pathways`, `PUT /pathways/{id}/enrollment` |
| 14 | Pathway detail | `GET /pathways/{id}`, `POST /pathways/{id}/steps/{stepId}/complete` |
| 15 | Community resources | `GET /communities/{id}/resources?type=&category=&q=`, `GET /resources/{id}`, `PUT /resources/{id}/progress`, `GET /quizzes/{id}`, `POST /quizzes/{id}/attempts` |
| 16 | Community info and members | `GET /communities/{id}`, `GET /communities/{id}/members` |
| 17 | Messages | `GET /conversations?filter=&q=` |
| 18 | Conversation | `GET/POST /conversations/{id}/messages`, `POST /conversations/{id}/read`, WebSocket |
| 19 | Report a user | `POST /media` (screenshot), `POST /reports` |
| 20 | Report sent | `PUT /users/{id}/block` |
| 21 | My profile | `GET/PATCH /me`, `GET /me/communities` |
| 22 | My activity | `GET /me/activity` |

## Example flows

**Onboarding**
```
GET  /lookups/institutions?type=university&country=UG&q=mak
POST /media                         -> upload photo, get media_id
POST /auth/register                 -> 201 { access_token, refresh_token, user }
POST /auth/otp/request              -> verify phone/email
GET  /communities?type=specific     -> hub
POST /communities/{id}/join-requests -> 201 { status: "pending" }
     ... super-mentor: POST /join-requests/{id}/decision {decision:"approve"}
     ... realtime event join_request.decided / push notification
```

**Share a testimony**
```
POST /media {purpose:"testimony_video", ...}  -> PUT bytes to upload_url
POST /communities/{id}/testimonies {title, body, media_ids, consent:true}
  -> 201 { status: "pending_review" }
GET  /communities/{id}/testimonies -> { has_my_pending: true, ... }
```

**Report then block**
```
POST /reports {target_type:"user", target_id, reason:"harassment_bullying", details, evidence_media_id}
PUT  /users/{id}/block
```

## Error codes (non-exhaustive)

`validation_failed` (422), `username_taken` / `email_taken` / `phone_taken` (409), `community_limit_reached` (409),
`already_enrolled` (409), `messaging_restricted` (403), `not_a_member` (403), `otp_invalid` (400), `rate_limited` (429).

## Assumptions and open questions

The design uses placeholder content, so these are inferred and should be confirmed:

- **Minor definition and guardian consent flow** (BRD §16) – modelled as `<18` with `guardian` fields.
- **Join form steps 2–3** are not drawn in detail; modelled as automatic General membership + separate join request.
- **Password vs OTP-only** – the form has no password field; the spec requires `password` for registration but BRD FR-16 (phone OTP, v2) could make it optional. Confirm.
- **Who can post / moderate** per the BRD roles matrix – mentor/leader moderation endpoints (hide message, warn member, approve testimonies, content approval workflow) are **not** in this mobile spec; they belong to the admin/web API.
- **Notifications inbox, calendar of events, Bible reading plan, mentor matching, search across library** are BRD items (v2/v3) with no screen yet; add endpoints when designed.
- **Meeting attendance** appears in *My activity* but no check-in screen exists; the event type is reserved (`meeting_attended`) with no write endpoint.
- Languages: English at launch; `language` field is present on resources for later localisation.
