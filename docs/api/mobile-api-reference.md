# FCU Student Community – Mobile API — endpoint reference

> Generated from `openapi.yaml` (OpenAPI 3.1.0, API version 1.0.0) by `docs/api/tools/openapi_to_markdown.js`. Do not edit by hand; regenerate.

**Servers:** `https://apis.focusuganda.org/v1` (Production), `http://localhost:4000/v1` (Local development)

**100 operations** in 16 groups. The "App" column says whether the Flutter app's code calls the path today.

## Index

### Auth

Registration, login, OTP, tokens (Landing, Join form)

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/auth/username-available`](#get-auth-username-available) | Check username availability | none (public) | yes |
| `POST` | [`/auth/register`](#post-auth-register) | Create account (Join form, step 1 of 3) | none (public) | yes |
| `POST` | [`/auth/login`](#post-auth-login) | Password login | none (public) | yes |
| `POST` | [`/auth/otp/request`](#post-auth-otp-request) | Send a one-time SMS/email code | none (public) | yes |
| `POST` | [`/auth/otp/verify`](#post-auth-otp-verify) | Verify a code | none (public) | yes |
| `POST` | [`/auth/password/reset`](#post-auth-password-reset) | Set a new password with an emailed code | none (public) | yes |
| `POST` | [`/auth/refresh`](#post-auth-refresh) | Rotate tokens | none (public) | yes |
| `POST` | [`/auth/logout`](#post-auth-logout) | Revoke refresh token | bearerAuth | yes |

### Lookups

Reference data for the Join form

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/lookups/app-config`](#get-lookups-app-config) | How the back office is set up, for the app | none (public) | yes |
| `GET` | [`/lookups/countries`](#get-lookups-countries) | Countries (Uganda, Kenya, Rwanda) | none (public) | — |
| `GET` | [`/lookups/institutions`](#get-lookups-institutions) | Universities / high schools ("Select your university") | none (public) | yes |

### Profile

My profile, activity and badges

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/me`](#get-me) | My profile | bearerAuth | yes |
| `PATCH` | [`/me`](#patch-me) | Update profile | bearerAuth | yes |
| `DELETE` | [`/me`](#delete-me) | Request account deletion | bearerAuth | yes |
| `POST` | [`/me/export`](#post-me-export) | Request an export of my personal data | bearerAuth | yes |
| `GET` | [`/me/guardian`](#get-me-guardian) | My guardian (minors) | bearerAuth | yes |
| `PUT` | [`/me/guardian`](#put-me-guardian) | Record my guardian (users under 18) | bearerAuth | yes |
| `GET` | [`/me/communities`](#get-me-communities) | My communities (General + at most one Specific) | bearerAuth | yes |
| `GET` | [`/me/notifications`](#get-me-notifications) | My in-app notifications (newest first) | bearerAuth | yes |
| `POST` | [`/me/notifications/read-all`](#post-me-notifications-read-all) | Mark every notification read | bearerAuth | yes |
| `POST` | [`/me/notifications/{notificationId}/read`](#post-me-notifications-notificationid-read) | Mark one notification read | bearerAuth | yes |
| `GET` | [`/me/notification-preferences`](#get-me-notification-preferences) | My notification settings | bearerAuth | yes |
| `PUT` | [`/me/notification-preferences`](#put-me-notification-preferences) | Save my notification settings | bearerAuth | yes |
| `GET` | [`/me/warnings`](#get-me-warnings) | Warnings I received | bearerAuth | yes |
| `POST` | [`/me/warnings/{warningId}/acknowledge`](#post-me-warnings-warningid-acknowledge) | Mark a warning as read and understood | bearerAuth | yes |
| `GET` | [`/me/suspension`](#get-me-suspension) | My current suspension, if any | bearerAuth | yes |
| `GET` | [`/me/activity`](#get-me-activity) | My activity & badges (private) | bearerAuth | yes |

### Communities

Communities hub, detail, info & members, join requests

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/me/join-requests`](#get-me-join-requests) | My join requests | bearerAuth | yes |
| `GET` | [`/communities`](#get-communities) | Browse / search communities | bearerAuth | yes |
| `GET` | [`/communities/{communityId}`](#get-communities-communityid) | Community detail / info | bearerAuth | yes |
| `GET` | [`/communities/{communityId}/members`](#get-communities-communityid-members) | Members list | bearerAuth | yes |
| `GET` | [`/communities/{communityId}/meetings`](#get-communities-communityid-meetings) | The next weekly meeting and the last three | bearerAuth | yes |
| `PUT` | [`/meetings/{meetingId}/going`](#put-meetings-meetingid-going) | RSVP to a meeting | bearerAuth | yes |
| `POST` | [`/meetings/{meetingId}/check-in`](#post-meetings-meetingid-check-in) | Record "I am here" | bearerAuth | yes |
| `POST` | [`/communities/{communityId}/join-requests`](#post-communities-communityid-join-requests) | Request to join a specific community | bearerAuth | yes |
| `DELETE` | [`/communities/{communityId}/membership`](#delete-communities-communityid-membership) | Leave my specific community | bearerAuth | yes |
| `DELETE` | [`/join-requests/{requestId}`](#delete-join-requests-requestid) | Cancel my pending request | bearerAuth | — |

### Feed

Posts, likes, comments (Community feed, New post)

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/communities/{communityId}/posts`](#get-communities-communityid-posts) | Community feed | bearerAuth | yes |
| `POST` | [`/communities/{communityId}/posts`](#post-communities-communityid-posts) | Create a post (New post screen) | bearerAuth | yes |
| `GET` | [`/posts/{postId}`](#get-posts-postid) | Get a post | bearerAuth | yes |
| `PATCH` | [`/posts/{postId}`](#patch-posts-postid) | Edit my post | bearerAuth | yes |
| `DELETE` | [`/posts/{postId}`](#delete-posts-postid) | Delete my post (or hide, for community leaders) | bearerAuth | yes |
| `PUT` | [`/posts/{postId}/like`](#put-posts-postid-like) | Like | bearerAuth | yes |
| `DELETE` | [`/posts/{postId}/like`](#delete-posts-postid-like) | Remove like | bearerAuth | yes |
| `GET` | [`/posts/{postId}/comments`](#get-posts-postid-comments) | Comments on a post | bearerAuth | yes |
| `POST` | [`/posts/{postId}/comments`](#post-posts-postid-comments) | Comment | bearerAuth | yes |
| `PUT` | [`/posts/{postId}/follow`](#put-posts-postid-follow) | Follow a question (be told about new answers) | bearerAuth | yes |
| `DELETE` | [`/posts/{postId}/follow`](#delete-posts-postid-follow) | Stop following a question | bearerAuth | yes |
| `PUT` | [`/posts/{postId}/hide`](#put-posts-postid-hide) | Hide a post from my own feed | bearerAuth | yes |
| `DELETE` | [`/posts/{postId}/hide`](#delete-posts-postid-hide) | Show a post I hid again | bearerAuth | yes |
| `PUT` | [`/posts/{postId}/pass`](#put-posts-postid-pass) | Pass on answering a question | bearerAuth | yes |
| `DELETE` | [`/posts/{postId}/pass`](#delete-posts-postid-pass) | Undo a pass | bearerAuth | yes |
| `PUT` | [`/comments/{commentId}/vote`](#put-comments-commentid-vote) | Mark an answer as helpful | bearerAuth | yes |
| `DELETE` | [`/comments/{commentId}/vote`](#delete-comments-commentid-vote) | Remove your helpful vote | bearerAuth | yes |
| `GET` | [`/search/posts`](#get-search-posts) | Search posts and questions in your communities | bearerAuth | yes |

### Prayer

Prayer wall

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/communities/{communityId}/prayer-requests`](#get-communities-communityid-prayer-requests) | Prayer wall | bearerAuth | yes |
| `POST` | [`/communities/{communityId}/prayer-requests`](#post-communities-communityid-prayer-requests) | Share a request (New prayer request) | bearerAuth | yes |
| `GET` | [`/prayer-requests/{prayerRequestId}`](#get-prayer-requests-prayerrequestid) | One prayer request | bearerAuth | yes |
| `PUT` | [`/prayer-requests/{prayerRequestId}/prayed`](#put-prayer-requests-prayerrequestid-prayed) | Mark "I prayed" (idempotent) | bearerAuth | yes |
| `DELETE` | [`/prayer-requests/{prayerRequestId}/prayed`](#delete-prayer-requests-prayerrequestid-prayed) | Undo "I prayed" | bearerAuth | yes |
| `GET` | [`/prayer-requests/{prayerRequestId}/responses`](#get-prayer-requests-prayerrequestid-responses) | Responses to a prayer request | bearerAuth | yes |
| `POST` | [`/prayer-requests/{prayerRequestId}/responses`](#post-prayer-requests-prayerrequestid-responses) | Respond | bearerAuth | yes |

### Testimonies

Testimonies and Share your story

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/communities/{communityId}/testimonies`](#get-communities-communityid-testimonies) | Testimonies list | bearerAuth | yes |
| `POST` | [`/communities/{communityId}/testimonies`](#post-communities-communityid-testimonies) | Share your story | bearerAuth | yes |
| `GET` | [`/testimonies/{testimonyId}`](#get-testimonies-testimonyid) | Read story | bearerAuth | yes |
| `PUT` | [`/testimonies/{testimonyId}/encourage`](#put-testimonies-testimonyid-encourage) | Say "Encouraged" on a story | bearerAuth | yes |
| `DELETE` | [`/testimonies/{testimonyId}/encourage`](#delete-testimonies-testimonyid-encourage) | Take back "Encouraged" | bearerAuth | yes |

### Pathways

Discipleship pathways

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/pathways`](#get-pathways) | All pathways + my current one | bearerAuth | yes |
| `GET` | [`/pathways/{pathwayId}`](#get-pathways-pathwayid) | Pathway detail with ordered steps | bearerAuth | yes |
| `PUT` | [`/pathways/{pathwayId}/enrollment`](#put-pathways-pathwayid-enrollment) | Start a pathway | bearerAuth | yes |
| `POST` | [`/pathways/{pathwayId}/steps/{stepId}/complete`](#post-pathways-pathwayid-steps-stepid-complete) | Mark a video/devotional step complete | bearerAuth | yes |

### Resources

Videos, devotionals, quizzes, documents

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/communities/{communityId}/resources`](#get-communities-communityid-resources) | Community resources library | bearerAuth | yes |
| `GET` | [`/resources/{resourceId}`](#get-resources-resourceid) | Resource detail (stream URL, text body or document URL) | bearerAuth | yes |
| `PUT` | [`/resources/{resourceId}/progress`](#put-resources-resourceid-progress) | Record watch/read progress or completion | bearerAuth | yes |
| `GET` | [`/resources/{resourceId}/reflection`](#get-resources-resourceid-reflection) | My private reflection on a devotional | bearerAuth | yes |
| `PUT` | [`/resources/{resourceId}/reflection`](#put-resources-resourceid-reflection) | Save my private reflection | bearerAuth | yes |
| `GET` | [`/quizzes/{quizId}`](#get-quizzes-quizid) | Quiz questions (correct answers withheld) | bearerAuth | yes |
| `POST` | [`/quizzes/{quizId}/attempts`](#post-quizzes-quizid-attempts) | Submit answers | bearerAuth | yes |

### Messages

Direct conversations (Messages, Conversation)

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/conversations`](#get-conversations) | Messages inbox | bearerAuth | yes |
| `POST` | [`/conversations`](#post-conversations) | Start (or get existing) 1:1 conversation | bearerAuth | yes |
| `GET` | [`/conversations/{conversationId}/messages`](#get-conversations-conversationid-messages) | Conversation history | bearerAuth | yes |
| `POST` | [`/conversations/{conversationId}/messages`](#post-conversations-conversationid-messages) | Send a message | bearerAuth | yes |
| `POST` | [`/conversations/{conversationId}/read`](#post-conversations-conversationid-read) | Mark read up to a message | bearerAuth | yes |
| `GET` | [`/realtime`](#get-realtime) | WebSocket for live updates | bearerAuth | — |

### Safety

Report a user, block

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `POST` | [`/reports`](#post-reports) | Report a user or content | bearerAuth | yes |
| `GET` | [`/me/blocks`](#get-me-blocks) | People I have blocked | bearerAuth | yes |
| `PUT` | [`/users/{userId}/block`](#put-users-userid-block) | Block a user ("Block this user" on Report sent) | bearerAuth | yes |
| `DELETE` | [`/users/{userId}/block`](#delete-users-userid-block) | Unblock | bearerAuth | yes |

### Media

Uploads

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `POST` | [`/media`](#post-media) | Create a direct-upload slot | bearerAuth | yes |
| `POST` | [`/media/{mediaId}/complete`](#post-media-mediaid-complete) | Confirm a direct (R2) upload finished | bearerAuth | yes |
| `PUT` | [`/media/{mediaId}/upload`](#put-media-mediaid-upload) | Upload file bytes to the slot (local/dev storage) | bearerAuth | — |

### Devices

Push notifications

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `POST` | [`/devices`](#post-devices) | Register a push token | bearerAuth | yes |
| `DELETE` | [`/devices/{deviceId}`](#delete-devices-deviceid) | Remove a push token (on logout) | bearerAuth | yes |

### Landing

Public marketing content (no auth)

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/public/landing`](#get-public-landing) | Landing screen content | none (public) | yes |

### Mentor tools

Super-mentor / mentor actions

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/communities/{communityId}/moderation/cases`](#get-communities-communityid-moderation-cases) | Open reports on content in my community (super-mentor only) | bearerAuth | yes |
| `POST` | [`/communities/{communityId}/moderation/cases/{caseId}/action`](#post-communities-communityid-moderation-cases-caseid-action) | Keep, hide, warn the author, or escalate to the FCU team | bearerAuth | yes |
| `GET` | [`/communities/{communityId}/members/last-active`](#get-communities-communityid-members-last-active) | When each member last did anything (super-mentor only) | bearerAuth | yes |
| `GET` | [`/communities/{communityId}/join-requests`](#get-communities-communityid-join-requests) | Pending requests for my community (super-mentor only) | bearerAuth | yes |
| `POST` | [`/join-requests/{requestId}/decision`](#post-join-requests-requestid-decision) | Approve or reject a join request (super-mentor) | bearerAuth | yes |

### System

Service health

| Method | Path | Summary | Auth | App |
|---|---|---|---|---|
| `GET` | [`/health`](#get-health) | Liveness check | none (public) | — |

## Endpoints

## Auth

<a id="get-auth-username-available"></a>
### `GET /auth/username-available`

**Check username availability**

Live validation for the `@username` field on the Join form.

- **Auth:** none (public)
- **Operation id:** `checkUsername`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `username` | query | string | yes | pattern `^[a-z0-9_.]{3,30}$` |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="post-auth-register"></a>
### `POST /auth/register`

**Create account (Join form, step 1 of 3)**

Creates the profile and the user is **automatically added to the General community** of their
university (landing step 2). Step 3 (choosing one specific community) is a separate call
(`POST /communities/{id}/join-requests`).

Minors (age < 18 from `birthdate`) must supply `guardian` details; the account is created with
`minor_status: pending_guardian_consent` and restricted (no direct messaging with unverified adults)
until the guardian confirms (BRD §7, FR-10). Phone or email must be provided; at least one is verified by OTP.
Photo is uploaded first via `POST /media` and referenced by `photo_media_id`.

- **Auth:** none (public)
- **Operation id:** `register`
- **Called by the app:** yes

**Request body** (`application/json`, required): [RegisterRequest](#schema-registerrequest)

| Field | Type | Required | Notes |
|---|---|---|---|
| `photo_media_id` | string |  |  |
| `full_name` | string | yes |  |
| `username` | string | yes |  |
| `birthdate` | string · date | yes |  |
| `country` | string | yes | ISO 3166-1 alpha-2 (UG, KE, RW) |
| `email` | string · email |  |  |
| `phone` | string |  | E.164 |
| `institution_type` | string (`university`, `institute`, `high_school`) | yes |  |
| `institution_id` | string |  |  |
| `institution_name` | string |  | Institutes only: a name typed because it is not listed — min 2 chars, max 120 chars |
| `year_of_study` | integer |  | Required for university students — ≥ 1, ≤ 7 |
| `home_church` | object |  | Optional at sign-up (can be added later with `PATCH /me`); when sent, all three are required. |
| `accepted_national_activities` | boolean | yes | Agrees to take part in FOCUS national activities (must be true) |
| `password` | string · password | yes | min 8 chars |
| `accepted_terms` | boolean | yes |  |
| `accepted_code_of_conduct` | boolean | yes | Community guidelines shown at sign-up (BRD §8.2) |
| `guardian` | object |  | Optional. Minors can send it now or later via `PUT /me/guardian` (x-open-question - exact definition of minor and consent mechanism TBD with FOCUS Uganda) |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Account created | [AuthSession](#schema-authsession) |
| `409` | State conflict. Codes include `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`. | [Problem](#schema-problem) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="post-auth-login"></a>
### `POST /auth/login`

**Password login**

- **Auth:** none (public)
- **Operation id:** `login`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `identifier` | string | yes | Email |
| `password` | string · password | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [AuthSession](#schema-authsession) |
| `401` | Missing/invalid credentials | [Problem](#schema-problem) |
| `429` | Too many requests; see `Retry-After` | [Problem](#schema-problem) |

<a id="post-auth-otp-request"></a>
### `POST /auth/otp/request`

**Send a one-time SMS/email code**

Used for phone login (FR-16) and for verifying contact details after registration.

- **Auth:** none (public)
- **Operation id:** `requestOtp`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `channel` | string (`sms`, `email`) | yes |  |
| `destination` | string | yes |  |
| `purpose` | string (`login`, `verify_contact`, `password_reset`) | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `202` | Code sent (always 202 to avoid account enumeration) | — |
| `429` | Too many requests; see `Retry-After` | [Problem](#schema-problem) |

<a id="post-auth-otp-verify"></a>
### `POST /auth/otp/verify`

**Verify a code**

For `purpose=login` returns a session; otherwise returns 204.

- **Auth:** none (public)
- **Operation id:** `verifyOtp`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `destination` | string | yes |  |
| `code` | string | yes | pattern `^[0-9]{6}$` |
| `purpose` | string (`login`, `verify_contact`, `password_reset`) | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Session (login only) | [AuthSession](#schema-authsession) |
| `204` | Verified | — |
| `400` | Validation failed | [Problem](#schema-problem) |

<a id="post-auth-password-reset"></a>
### `POST /auth/password/reset`

**Set a new password with an emailed code**

Forgot password. First call `POST /auth/otp/request` with `purpose=password_reset`, then send the code here together with the new password. Do not send the code to `/auth/otp/verify` first: a code works once. Every existing session of the account is signed out and a new session is returned. The same error is returned for a wrong code, an expired code, and an address with no account.

- **Auth:** none (public)
- **Operation id:** `resetPassword`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `destination` | string | yes | The email or phone the code was sent to |
| `code` | string | yes | pattern `^[0-9]{6}$` |
| `new_password` | string | yes | min 8 chars, max 128 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Password changed; signed in | [AuthSession](#schema-authsession) |
| `400` | Validation failed | [Problem](#schema-problem) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="post-auth-refresh"></a>
### `POST /auth/refresh`

**Rotate tokens**

- **Auth:** none (public)
- **Operation id:** `refreshToken`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `refresh_token` | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Tokens](#schema-tokens) |
| `401` | Missing/invalid credentials | [Problem](#schema-problem) |

<a id="post-auth-logout"></a>
### `POST /auth/logout`

**Revoke refresh token**

- **Auth:** bearerAuth
- **Operation id:** `logout`
- **Called by the app:** yes

**Request body** (`application/json`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `refresh_token` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Logged out | — |

## Lookups

<a id="get-lookups-app-config"></a>
### `GET /lookups/app-config`

**How the back office is set up, for the app**

`join_requests.auto_approve`: a request to join a specific community is approved at once (back office Settings > Join requests; on by default). When false the app shows the "request pending" state.

- **Auth:** none (public)
- **Operation id:** `getAppConfig`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-lookups-countries"></a>
### `GET /lookups/countries`

**Countries (Uganda, Kenya, Rwanda)**

- **Auth:** none (public)
- **Operation id:** `listCountries`
- **Called by the app:** —

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-lookups-institutions"></a>
### `GET /lookups/institutions`

**Universities / high schools ("Select your university")**

- **Auth:** none (public)
- **Operation id:** `listInstitutions`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `type` | query | string (`university`, `institute`, `high_school`) |  |  |
| `country` | query | string |  |  |
| `q` | query | string |  |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

## Profile

<a id="get-me"></a>
### `GET /me`

**My profile**

Screen *My profile*. Email/phone are only ever returned to the owner.

- **Auth:** bearerAuth
- **Operation id:** `getMe`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MyProfile](#schema-myprofile) |

<a id="patch-me"></a>
### `PATCH /me`

**Update profile**

- **Auth:** bearerAuth
- **Operation id:** `updateMe`
- **Called by the app:** yes

**Request body** (`application/json`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `full_name` | string |  |  |
| `photo_media_id` | string \| null |  | nullable |
| `country` | string |  |  |
| `phone` | string |  |  |
| `email` | string · email |  |  |
| `institution_id` | string |  |  |
| `year_of_study` | integer |  | ≥ 1, ≤ 7 |
| `home_church` | object |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MyProfile](#schema-myprofile) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="delete-me"></a>
### `DELETE /me`

**Request account deletion**

Right to delete (BRD §7). Starts a retention-policy grace period; returns 202.

- **Auth:** bearerAuth
- **Operation id:** `deleteMyAccount`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `202` | Deletion scheduled | — |

<a id="post-me-export"></a>
### `POST /me/export`

**Request an export of my personal data**

- **Auth:** bearerAuth
- **Operation id:** `requestDataExport`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `202` | Export queued; a download link is sent by email/notification | — |

<a id="get-me-guardian"></a>
### `GET /me/guardian`

**My guardian (minors)**

- **Auth:** bearerAuth
- **Operation id:** `getMyGuardian`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | The recorded guardian, or null | [GuardianResponse](#schema-guardianresponse) |

<a id="put-me-guardian"></a>
### `PUT /me/guardian`

**Record my guardian (users under 18)**

The app asks for this after sign-up. Messaging stays restricted until staff confirm consent.

- **Auth:** bearerAuth
- **Operation id:** `setMyGuardian`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `relationship` | string |  |  |
| `email` | string · email |  |  |
| `phone` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Saved | [GuardianResponse](#schema-guardianresponse) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="get-me-communities"></a>
### `GET /me/communities`

**My communities (General + at most one Specific)**

Used by *Communities hub*, *Communities hub, request pending* and *My profile*.

- **Auth:** bearerAuth
- **Operation id:** `getMyCommunities`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-me-notifications"></a>
### `GET /me/notifications`

**My in-app notifications (newest first)**

- **Auth:** bearerAuth
- **Operation id:** `listMyNotifications`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-me-notifications-read-all"></a>
### `POST /me/notifications/read-all`

**Mark every notification read**

- **Auth:** bearerAuth
- **Operation id:** `markAllNotificationsRead`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Done | — |

<a id="post-me-notifications-notificationid-read"></a>
### `POST /me/notifications/{notificationId}/read`

**Mark one notification read**

- **Auth:** bearerAuth
- **Operation id:** `markNotificationRead`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `notificationId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Done | — |
| `404` | Not found | [Problem](#schema-problem) |

<a id="get-me-notification-preferences"></a>
### `GET /me/notification-preferences`

**My notification settings**

- **Auth:** bearerAuth
- **Operation id:** `getNotificationPreferences`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [NotificationPreferences](#schema-notificationpreferences) |

<a id="put-me-notification-preferences"></a>
### `PUT /me/notification-preferences`

**Save my notification settings**

- **Auth:** bearerAuth
- **Operation id:** `setNotificationPreferences`
- **Called by the app:** yes

**Request body** (`application/json`, required): [NotificationPreferences](#schema-notificationpreferences)

| Field | Type | Required | Notes |
|---|---|---|---|
| `channels` | array of string (`inApp`, `email`) | yes |  |
| `muted` | array of string (`joinRequestUpdates`, `replies`, `prayerResponses`, `announcements`, `meetingReminders`, `inactivityReminders`) | yes | Muted categories. Moderator warnings cannot be muted. |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Saved | [NotificationPreferences](#schema-notificationpreferences) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="get-me-warnings"></a>
### `GET /me/warnings`

**Warnings I received**

- **Auth:** bearerAuth
- **Operation id:** `listMyWarnings`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="post-me-warnings-warningid-acknowledge"></a>
### `POST /me/warnings/{warningId}/acknowledge`

**Mark a warning as read and understood**

- **Auth:** bearerAuth
- **Operation id:** `acknowledgeWarning`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `warningId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Warning](#schema-warning) |
| `404` | Not found | [Problem](#schema-problem) |

<a id="get-me-suspension"></a>
### `GET /me/suspension`

**My current suspension, if any**

While suspended the account is read-only (`403 account_suspended` on changes). A suspension without an end date set by staff lasts 7 days from when it was issued.

- **Auth:** bearerAuth
- **Operation id:** `getMySuspension`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-me-activity"></a>
### `GET /me/activity`

**My activity & badges (private)**

Screen *My activity*. Visible only to the user (BRD FR-18).

- **Auth:** bearerAuth
- **Operation id:** `getMyActivity`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

## Communities

<a id="get-me-join-requests"></a>
### `GET /me/join-requests`

**My join requests**

- **Auth:** bearerAuth
- **Operation id:** `listMyJoinRequests`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-communities"></a>
### `GET /communities`

**Browse / search communities**

Communities hub → "Find a specific community". Defaults to the caller's institution.
While the caller has a pending request, entries other than theirs have `can_request: false` ("locked").

- **Auth:** bearerAuth
- **Operation id:** `listCommunities`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `type` | query | string (`general`, `specific`) |  |  |
| `institution_id` | query | string |  |  |
| `q` | query | string |  | Matches name, meeting day or place |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="get-communities-communityid"></a>
### `GET /communities/{communityId}`

**Community detail / info**

Screens *Community detail* and *Community info and members* (header + About + meeting + leadership + online count).

- **Auth:** bearerAuth
- **Operation id:** `getCommunity`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Community](#schema-community) |
| `404` | Not found | [Problem](#schema-problem) |

<a id="get-communities-communityid-members"></a>
### `GET /communities/{communityId}/members`

**Members list**

Leaders (super-mentor, mentor) are sorted first. Members only; requires membership.

- **Auth:** bearerAuth
- **Operation id:** `listCommunityMembers`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `role` | query | string (`super_mentor`, `mentor`, `member`) |  |  |
| `online` | query | boolean |  |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

<a id="get-communities-communityid-meetings"></a>
### `GET /communities/{communityId}/meetings`

**The next weekly meeting and the last three**

Meetings are derived from the community's weekly `meeting`. `next` stays current while check-in is open.

- **Auth:** bearerAuth
- **Operation id:** `listMeetings`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `now` | query | string · date-time |  | ISO time to compute the schedule as of (default: now) |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="put-meetings-meetingid-going"></a>
### `PUT /meetings/{meetingId}/going`

**RSVP to a meeting**

- **Auth:** bearerAuth
- **Operation id:** `setMeetingGoing`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `meetingId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `going` | boolean | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MeetingOccurrence](#schema-meetingoccurrence) |
| `404` | Not found | [Problem](#schema-problem) |

<a id="post-meetings-meetingid-check-in"></a>
### `POST /meetings/{meetingId}/check-in`

**Record "I am here"**

Open from 30 minutes before the start to 2 hours after, by the server's clock. `409 check_in_closed` or `409 already_checked_in` otherwise.

- **Auth:** bearerAuth
- **Operation id:** `checkInToMeeting`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `meetingId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MeetingOccurrence](#schema-meetingoccurrence) |
| `404` | Not found | [Problem](#schema-problem) |
| `409` | State conflict. Codes include `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`. | [Problem](#schema-problem) |

<a id="post-communities-communityid-join-requests"></a>
### `POST /communities/{communityId}/join-requests`

**Request to join a specific community**

Goes to the super-mentor for approval; the user is notified of the decision.
Rule: a user may belong to **only one** specific community — returns `409 community_limit_reached`
if they already have a pending or approved one.

- **Auth:** bearerAuth
- **Operation id:** `requestToJoin`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Request created (status `pending`) | [JoinRequest](#schema-joinrequest) |
| `409` | State conflict. Codes include `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`. | [Problem](#schema-problem) |

<a id="delete-communities-communityid-membership"></a>
### `DELETE /communities/{communityId}/membership`

**Leave my specific community**

Not allowed for the General community (`409 not_leavable`) or for its super-mentor (`409 super_mentor_cannot_leave`).

- **Auth:** bearerAuth
- **Operation id:** `leaveCommunity`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Left; the user can request another community | — |
| `404` | Not found | [Problem](#schema-problem) |
| `409` | State conflict. Codes include `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`. | [Problem](#schema-problem) |

<a id="delete-join-requests-requestid"></a>
### `DELETE /join-requests/{requestId}`

**Cancel my pending request**

- **Auth:** bearerAuth
- **Operation id:** `cancelJoinRequest`
- **Called by the app:** —

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `requestId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Cancelled; other communities unlock | — |

## Feed

<a id="get-communities-communityid-posts"></a>
### `GET /communities/{communityId}/posts`

**Community feed**

Screens *Community feed* and *General community feed*. Pinned announcements first, then newest.

- **Auth:** bearerAuth
- **Operation id:** `listPosts`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `kind` | query | string (`post`, `question`) |  | Only this kind (questions for "Answer a question") |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-communities-communityid-posts"></a>
### `POST /communities/{communityId}/posts`

**Create a post (New post screen)**

Text plus optional photos (uploaded first via `/media`). Members of General and Specific communities may post.

- **Auth:** bearerAuth
- **Operation id:** `createPost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `Idempotency-Key` | header | string · uuid |  |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string | yes | max 5000 chars |
| `kind` | string (`post`, `question`) |  | default `"post"` |
| `anonymous` | boolean |  | Name hidden from students; moderators can still see who posted — default `false` |
| `media_ids` | array of string |  | max 4 items |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Created | [Post](#schema-post) |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="get-posts-postid"></a>
### `GET /posts/{postId}`

**Get a post**

- **Auth:** bearerAuth
- **Operation id:** `getPost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Post](#schema-post) |

<a id="patch-posts-postid"></a>
### `PATCH /posts/{postId}`

**Edit my post**

- **Auth:** bearerAuth
- **Operation id:** `updatePost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Request body** (`application/json`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Post](#schema-post) |

<a id="delete-posts-postid"></a>
### `DELETE /posts/{postId}`

**Delete my post (or hide, for community leaders)**

- **Auth:** bearerAuth
- **Operation id:** `deletePost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Deleted | — |

<a id="put-posts-postid-like"></a>
### `PUT /posts/{postId}/like`

**Like**

- **Auth:** bearerAuth
- **Operation id:** `likePost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ReactionState](#schema-reactionstate) |

<a id="delete-posts-postid-like"></a>
### `DELETE /posts/{postId}/like`

**Remove like**

- **Auth:** bearerAuth
- **Operation id:** `unlikePost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ReactionState](#schema-reactionstate) |

<a id="get-posts-postid-comments"></a>
### `GET /posts/{postId}/comments`

**Comments on a post**

- **Auth:** bearerAuth
- **Operation id:** `listComments`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-posts-postid-comments"></a>
### `POST /posts/{postId}/comments`

**Comment**

- **Auth:** bearerAuth
- **Operation id:** `createComment`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string | yes | max 2000 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Created | [Comment](#schema-comment) |

<a id="put-posts-postid-follow"></a>
### `PUT /posts/{postId}/follow`

**Follow a question (be told about new answers)**

Questions only. Each new answer notifies followers (category replies), except its writer and the asker, who is told anyway.

- **Auth:** bearerAuth
- **Operation id:** `followQuestion`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [FollowState](#schema-followstate) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="delete-posts-postid-follow"></a>
### `DELETE /posts/{postId}/follow`

**Stop following a question**

- **Auth:** bearerAuth
- **Operation id:** `unfollowQuestion`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [FollowState](#schema-followstate) |

<a id="put-posts-postid-hide"></a>
### `PUT /posts/{postId}/hide`

**Hide a post from my own feed**

"Hide this post": it leaves the caller's community feed and post search; nobody else is affected. Not a report.

- **Auth:** bearerAuth
- **Operation id:** `hidePost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Hidden for me | — |

<a id="delete-posts-postid-hide"></a>
### `DELETE /posts/{postId}/hide`

**Show a post I hid again**

- **Auth:** bearerAuth
- **Operation id:** `unhidePost`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Shown again | — |

<a id="put-posts-postid-pass"></a>
### `PUT /posts/{postId}/pass`

**Pass on answering a question**

Questions only. Sets `passed_by_me` so the app leaves it out of "Questions to answer". The question stays in the feed.

- **Auth:** bearerAuth
- **Operation id:** `passQuestion`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Passed | — |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="delete-posts-postid-pass"></a>
### `DELETE /posts/{postId}/pass`

**Undo a pass**

- **Auth:** bearerAuth
- **Operation id:** `unpassQuestion`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `postId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Undone | — |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="put-comments-commentid-vote"></a>
### `PUT /comments/{commentId}/vote`

**Mark an answer as helpful**

Answers to questions only; one vote per member; not on your own answer (403 own_answer).

- **Auth:** bearerAuth
- **Operation id:** `voteAnswer`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `commentId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [VoteState](#schema-votestate) |
| `403` | Your own answer | — |
| `404` | Not found or not a member | — |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="delete-comments-commentid-vote"></a>
### `DELETE /comments/{commentId}/vote`

**Remove your helpful vote**

- **Auth:** bearerAuth
- **Operation id:** `unvoteAnswer`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `commentId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [VoteState](#schema-votestate) |

<a id="get-search-posts"></a>
### `GET /search/posts`

**Search posts and questions in your communities**

Matches the text (at least 2 characters) of visible posts in communities you are a member of, newest first; blocked people are left out.

- **Auth:** bearerAuth
- **Operation id:** `searchPosts`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `q` | query | string | yes | min 2 chars |
| `kind` | query | string (`post`, `question`) |  |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |
| `422` | Validation failed | [Problem](#schema-problem) |

## Prayer

<a id="get-communities-communityid-prayer-requests"></a>
### `GET /communities/{communityId}/prayer-requests`

**Prayer wall**

Anonymous requests have `author: null`; the author identity is never exposed to clients (only to moderators).

- **Auth:** bearerAuth
- **Operation id:** `listPrayerRequests`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-communities-communityid-prayer-requests"></a>
### `POST /communities/{communityId}/prayer-requests`

**Share a request (New prayer request)**

Visible only to members of the specified community.

- **Auth:** bearerAuth
- **Operation id:** `createPrayerRequest`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string | yes | max 2000 chars |
| `anonymous` | boolean |  | default `false` |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Created | [PrayerRequest](#schema-prayerrequest) |

<a id="get-prayer-requests-prayerrequestid"></a>
### `GET /prayer-requests/{prayerRequestId}`

**One prayer request**

- **Auth:** bearerAuth
- **Operation id:** `getPrayerRequest`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `prayerRequestId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PrayerRequest](#schema-prayerrequest) |
| `404` | Not found | [Problem](#schema-problem) |

<a id="put-prayer-requests-prayerrequestid-prayed"></a>
### `PUT /prayer-requests/{prayerRequestId}/prayed`

**Mark "I prayed" (idempotent)**

Increments `prayed_count` once per user and logs a "Prayed for a request" activity event.

- **Auth:** bearerAuth
- **Operation id:** `markPrayed`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `prayerRequestId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="delete-prayer-requests-prayerrequestid-prayed"></a>
### `DELETE /prayer-requests/{prayerRequestId}/prayed`

**Undo "I prayed"**

- **Auth:** bearerAuth
- **Operation id:** `unmarkPrayed`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `prayerRequestId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-prayer-requests-prayerrequestid-responses"></a>
### `GET /prayer-requests/{prayerRequestId}/responses`

**Responses to a prayer request**

- **Auth:** bearerAuth
- **Operation id:** `listPrayerResponses`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `prayerRequestId` | path | string | yes |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-prayer-requests-prayerrequestid-responses"></a>
### `POST /prayer-requests/{prayerRequestId}/responses`

**Respond**

- **Auth:** bearerAuth
- **Operation id:** `respondToPrayerRequest`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `prayerRequestId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string | yes | max 2000 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Created | [PrayerResponse](#schema-prayerresponse) |

## Testimonies

<a id="get-communities-communityid-testimonies"></a>
### `GET /communities/{communityId}/testimonies`

**Testimonies list**

Returns published testimonies plus the caller's own pending ones (drives the banner "Your story is awaiting review by the moderators").

- **Auth:** bearerAuth
- **Operation id:** `listTestimonies`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-communities-communityid-testimonies"></a>
### `POST /communities/{communityId}/testimonies`

**Share your story**

Always created as `pending_review`; moderators approve before publication. `consent` must be `true`.

- **Auth:** bearerAuth
- **Operation id:** `submitTestimony`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | max 120 chars |
| `body` | string | yes | max 10000 chars |
| `media_ids` | array of string |  | Photo and/or video (upload via /media) |
| `consent` | boolean | yes | "I agree to share my story with my community." |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Submitted for review | [Testimony](#schema-testimony) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="get-testimonies-testimonyid"></a>
### `GET /testimonies/{testimonyId}`

**Read story**

- **Auth:** bearerAuth
- **Operation id:** `getTestimony`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `testimonyId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Testimony](#schema-testimony) |

<a id="put-testimonies-testimonyid-encourage"></a>
### `PUT /testimonies/{testimonyId}/encourage`

**Say "Encouraged" on a story**

One per member, published stories only (422 otherwise).

- **Auth:** bearerAuth
- **Operation id:** `encourageTestimony`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `testimonyId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [EncouragedState](#schema-encouragedstate) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="delete-testimonies-testimonyid-encourage"></a>
### `DELETE /testimonies/{testimonyId}/encourage`

**Take back "Encouraged"**

- **Auth:** bearerAuth
- **Operation id:** `unencourageTestimony`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `testimonyId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [EncouragedState](#schema-encouragedstate) |
| `422` | Validation failed | [Problem](#schema-problem) |

## Pathways

<a id="get-pathways"></a>
### `GET /pathways`

**All pathways + my current one**

Later pathways are `locked` until prerequisites complete ("Unlocks after the first pathway").

- **Auth:** bearerAuth
- **Operation id:** `listPathways`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="get-pathways-pathwayid"></a>
### `GET /pathways/{pathwayId}`

**Pathway detail with ordered steps**

- **Auth:** bearerAuth
- **Operation id:** `getPathway`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `pathwayId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PathwayDetail](#schema-pathwaydetail) |

<a id="put-pathways-pathwayid-enrollment"></a>
### `PUT /pathways/{pathwayId}/enrollment`

**Start a pathway**

- **Auth:** bearerAuth
- **Operation id:** `startPathway`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `pathwayId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PathwaySummary](#schema-pathwaysummary) |
| `409` | State conflict. Codes include `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`. | [Problem](#schema-problem) |

<a id="post-pathways-pathwayid-steps-stepid-complete"></a>
### `POST /pathways/{pathwayId}/steps/{stepId}/complete`

**Mark a video/devotional step complete**

Quiz steps complete via a passing quiz attempt instead. May award badges.

- **Auth:** bearerAuth
- **Operation id:** `completeStep`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `pathwayId` | path | string | yes |  |
| `stepId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

## Resources

<a id="get-communities-communityid-resources"></a>
### `GET /communities/{communityId}/resources`

**Community resources library**

Filter chips: All / Videos / Devotionals / Quizzes / Documents. Categories: Bible characters
(lives and lessons), Bible texts (study by passage). Only `published` items are returned (BRD §8.1).

- **Auth:** bearerAuth
- **Operation id:** `listResources`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `type` | query | string (`video`, `devotional`, `quiz`, `document`) |  |  |
| `category` | query | string (`bible_characters`, `bible_texts`) |  |  |
| `q` | query | string |  |  |
| `tag` | query | string |  |  |
| `bible_book` | query | string |  |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="get-resources-resourceid"></a>
### `GET /resources/{resourceId}`

**Resource detail (stream URL, text body or document URL)**

- **Auth:** bearerAuth
- **Operation id:** `getResource`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `resourceId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Resource](#schema-resource) |

<a id="put-resources-resourceid-progress"></a>
### `PUT /resources/{resourceId}/progress`

**Record watch/read progress or completion**

Feeds *My activity* ("Watched …") and tracking (FR-02).

- **Auth:** bearerAuth
- **Operation id:** `updateResourceProgress`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `resourceId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `position_seconds` | integer |  |  |
| `completed` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Saved | — |

<a id="get-resources-resourceid-reflection"></a>
### `GET /resources/{resourceId}/reflection`

**My private reflection on a devotional**

Only its author ever reads it. Empty text when there is none.

- **Auth:** bearerAuth
- **Operation id:** `getReflection`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `resourceId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Reflection](#schema-reflection) |

<a id="put-resources-resourceid-reflection"></a>
### `PUT /resources/{resourceId}/reflection`

**Save my private reflection**

- **Auth:** bearerAuth
- **Operation id:** `saveReflection`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `resourceId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string | yes | Empty text clears the reflection — max 5000 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Saved | [Reflection](#schema-reflection) |
| `422` | Validation failed | [Problem](#schema-problem) |

<a id="get-quizzes-quizid"></a>
### `GET /quizzes/{quizId}`

**Quiz questions (correct answers withheld)**

- **Auth:** bearerAuth
- **Operation id:** `getQuiz`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `quizId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Quiz](#schema-quiz) |

<a id="post-quizzes-quizid-attempts"></a>
### `POST /quizzes/{quizId}/attempts`

**Submit answers**

- **Auth:** bearerAuth
- **Operation id:** `submitQuizAttempt`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `quizId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `answers` | array of object | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Scored attempt | object |

## Messages

<a id="get-conversations"></a>
### `GET /conversations`

**Messages inbox**

Tabs All / Mentors / Members; `q` searches member names and message text.

- **Auth:** bearerAuth
- **Operation id:** `listConversations`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `filter` | query | string (`all`, `mentors`, `members`) |  | default `"all"` |
| `q` | query | string |  |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-conversations"></a>
### `POST /conversations`

**Start (or get existing) 1:1 conversation**

Returns the existing conversation if one exists. Rejected with 403 `messaging_restricted` when a
minor would be matched with an unverified adult (BRD §7) or when either party blocked the other.

- **Auth:** bearerAuth
- **Operation id:** `startConversation`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `user_id` | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Existing | [ConversationSummary](#schema-conversationsummary) |
| `201` | Created | [ConversationSummary](#schema-conversationsummary) |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

<a id="get-conversations-conversationid-messages"></a>
### `GET /conversations/{conversationId}/messages`

**Conversation history**

Newest first; the client groups by day ("Today"). Cursor pages backwards in time.

- **Auth:** bearerAuth
- **Operation id:** `listMessages`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `conversationId` | path | string | yes |  |
| `limit` | query | integer |  | ≥ 1, ≤ 100, default `20` |
| `cursor` | query | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Page](#schema-page) & object |

<a id="post-conversations-conversationid-messages"></a>
### `POST /conversations/{conversationId}/messages`

**Send a message**

- **Auth:** bearerAuth
- **Operation id:** `sendMessage`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `conversationId` | path | string | yes |  |
| `Idempotency-Key` | header | string · uuid |  |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string | yes | max 4000 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Created | [Message](#schema-message) |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

<a id="post-conversations-conversationid-read"></a>
### `POST /conversations/{conversationId}/read`

**Mark read up to a message**

- **Auth:** bearerAuth
- **Operation id:** `markConversationRead`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `conversationId` | path | string | yes |  |

**Request body** (`application/json`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `up_to_message_id` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | OK | — |

<a id="get-realtime"></a>
### `GET /realtime`

**WebSocket for live updates**

Upgrade to WebSocket with `?token=<access_token>`. Server pushes JSON events:
`message.created`, `message.read`, `presence.updated` (community `online_count`),
`join_request.decided`, `notification.created`. Clients fall back to polling the REST endpoints
and to push notifications when the socket is unavailable (low connectivity).

- **Auth:** bearerAuth
- **Operation id:** `realtimeSocket`
- **Called by the app:** —

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `101` | Switching Protocols | — |

## Safety

<a id="post-reports"></a>
### `POST /reports`

**Report a user or content**

Screens *Report a user* and *Report sent*. Targets: user, message, post, comment, testimony,
prayer_request (BRD §8.2). Screenshot is optional, uploaded first via `/media` (`purpose=report_evidence`).
Reviewed by the FCU moderation team; community leaders get first-level visibility for their cohort.

- **Auth:** bearerAuth
- **Operation id:** `createReport`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `Idempotency-Key` | header | string · uuid |  |  |

**Request body** (`application/json`, required): [ReportRequest](#schema-reportrequest)

| Field | Type | Required | Notes |
|---|---|---|---|
| `target_type` | string (`user`, `message`, `post`, `comment`, `testimony`, `prayer_request`) | yes |  |
| `target_id` | string | yes |  |
| `reason` | string (`harassment_bullying`, `offensive_content`, `breaks_community_rules`, `spam_or_fake_profile`, `other`) | yes |  |
| `details` | string |  | Required (not blank) when reason is other — max 2000 chars |
| `evidence_media_id` | string \| null |  | Chat screenshot — nullable |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Report received | object |

<a id="get-me-blocks"></a>
### `GET /me/blocks`

**People I have blocked**

- **Auth:** bearerAuth
- **Operation id:** `listMyBlocks`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

<a id="put-users-userid-block"></a>
### `PUT /users/{userId}/block`

**Block a user ("Block this user" on Report sent)**

- **Auth:** bearerAuth
- **Operation id:** `blockUser`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `userId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Blocked | — |

<a id="delete-users-userid-block"></a>
### `DELETE /users/{userId}/block`

**Unblock**

- **Auth:** bearerAuth
- **Operation id:** `unblockUser`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `userId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Unblocked | — |

## Media

<a id="post-media"></a>
### `POST /media`

**Create a direct-upload slot**

Returns a pre-signed `upload_url` (PUT the bytes there with the given headers) and a `media_id` to
reference in other requests. Media is attached to content only after it passes malware/size checks.
Limits: images ≤ 2 MB (the app sends WebP), video ≤ 200 MB.

- **Auth:** bearerAuth
- **Operation id:** `createUpload`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `purpose` | string (`profile_photo`, `post_photo`, `testimony_photo`, `testimony_video`, `report_evidence`) | yes |  |
| `content_type` | string | yes |  |
| `size_bytes` | integer | yes |  |
| `duration_seconds` | number |  | Required for testimony_video: story videos are at most 2 minutes — ≤ 120 |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | object |

<a id="post-media-mediaid-complete"></a>
### `POST /media/{mediaId}/complete`

**Confirm a direct (R2) upload finished**

Optional. With Cloudflare R2 the client PUTs to a signed URL; the API also verifies the upload lazily when the media is attached. Returns 409 if the file is missing or larger than declared.

- **Auth:** bearerAuth
- **Operation id:** `completeMediaUpload`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `mediaId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Upload confirmed | — |
| `409` | Not uploaded yet | — |

<a id="put-media-mediaid-upload"></a>
### `PUT /media/{mediaId}/upload`

**Upload file bytes to the slot (local/dev storage)**

Raw body with the declared Content-Type. In production the `upload_url` is a pre-signed object-storage URL instead.

- **Auth:** bearerAuth
- **Operation id:** `uploadMediaBytes`
- **Called by the app:** —

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `mediaId` | path | string | yes |  |

**Request body** (`*/*`, required)

Type: string · binary

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Stored | — |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |
| `404` | Not found | [Problem](#schema-problem) |

## Devices

<a id="post-devices"></a>
### `POST /devices`

**Register a push token**

- **Auth:** bearerAuth
- **Operation id:** `registerDevice`
- **Called by the app:** yes

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `platform` | string (`ios`, `android`) | yes |  |
| `push_token` | string | yes |  |
| `app_version` | string |  |  |
| `locale` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Registered | object |

<a id="delete-devices-deviceid"></a>
### `DELETE /devices/{deviceId}`

**Remove a push token (on logout)**

- **Auth:** bearerAuth
- **Operation id:** `unregisterDevice`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `deviceId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Removed | — |

## Landing

<a id="get-public-landing"></a>
### `GET /public/landing`

**Landing screen content**

Student stories (video) shown under "Hear it from students". Screen *FCU landing*.

- **Auth:** none (public)
- **Operation id:** `getLanding`
- **Called by the app:** yes

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |

## Mentor tools

<a id="get-communities-communityid-moderation-cases"></a>
### `GET /communities/{communityId}/moderation/cases`

**Open reports on content in my community (super-mentor only)**

Reports about the same post, comment, prayer request or testimony form one case.

- **Auth:** bearerAuth
- **Operation id:** `listModerationCases`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

<a id="post-communities-communityid-moderation-cases-caseid-action"></a>
### `POST /communities/{communityId}/moderation/cases/{caseId}/action`

**Keep, hide, warn the author, or escalate to the FCU team**

`warn` also hides the content, records a warning for the author and notifies them. `escalate` moves the reports to the staff queue.

- **Auth:** bearerAuth
- **Operation id:** `actOnModerationCase`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `caseId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string (`keep`, `hide`, `warn`, `escalate`) | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | The case with its outcome | [ModerationCase](#schema-moderationcase) |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |
| `409` | State conflict. Codes include `username_taken`, `email_taken`, `phone_taken`, `community_limit_reached`, `already_enrolled`. | [Problem](#schema-problem) |

<a id="get-communities-communityid-members-last-active"></a>
### `GET /communities/{communityId}/members/last-active`

**When each member last did anything (super-mentor only)**

Timestamps only, never the events themselves. Members with no activity are absent.

- **Auth:** bearerAuth
- **Operation id:** `listMembersLastActive`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

<a id="get-communities-communityid-join-requests"></a>
### `GET /communities/{communityId}/join-requests`

**Pending requests for my community (super-mentor only)**

- **Auth:** bearerAuth
- **Operation id:** `listCommunityJoinRequests`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `communityId` | path | string | yes |  |
| `status` | query | string (`pending`, `approved`, `rejected`) |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

<a id="post-join-requests-requestid-decision"></a>
### `POST /join-requests/{requestId}/decision`

**Approve or reject a join request (super-mentor)**

Sends an in-app/push notification to the student.

- **Auth:** bearerAuth
- **Operation id:** `decideJoinRequest`
- **Called by the app:** yes

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `requestId` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `decision` | string (`approve`, `reject`) | yes |  |
| `note` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [JoinRequest](#schema-joinrequest) |
| `403` | Not permitted (role, membership, minor restriction, block) | [Problem](#schema-problem) |

## System

<a id="get-health"></a>
### `GET /health`

**Liveness check**

- **Auth:** none (public)
- **Operation id:** `getHealth`
- **Called by the app:** —

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | Service is up | object |

## Schemas

<a id="schema-problem"></a>
### Problem

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | string | yes |  |
| `title` | string | yes |  |
| `status` | integer | yes |  |
| `code` | string |  |  |
| `detail` | string |  |  |
| `errors` | array of object |  | Field-level validation errors |

<a id="schema-page"></a>
### Page

| Field | Type | Required | Notes |
|---|---|---|---|
| `next_cursor` | string \| null |  | nullable |

<a id="schema-tokens"></a>
### Tokens

| Field | Type | Required | Notes |
|---|---|---|---|
| `access_token` | string |  |  |
| `refresh_token` | string |  |  |
| `expires_in` | integer |  |  |

<a id="schema-authsession"></a>
### AuthSession

| Field | Type | Required | Notes |
|---|---|---|---|
| `access_token` | string |  |  |
| `refresh_token` | string |  |  |
| `expires_in` | integer |  |  |
| `user` | [MyProfile](#schema-myprofile) |  |  |

<a id="schema-registerrequest"></a>
### RegisterRequest

Send `institution_id` from `GET /institutions`. Only for `institution_type: institute`, when the institute is not listed, send `institution_name` instead: the institute is added (hidden from the list until staff review it) or reused if one with that name exists in the country. `high_school` is accepted only for older app versions.

| Field | Type | Required | Notes |
|---|---|---|---|
| `photo_media_id` | string |  |  |
| `full_name` | string | yes |  |
| `username` | string | yes |  |
| `birthdate` | string · date | yes |  |
| `country` | string | yes | ISO 3166-1 alpha-2 (UG, KE, RW) |
| `email` | string · email |  |  |
| `phone` | string |  | E.164 |
| `institution_type` | string (`university`, `institute`, `high_school`) | yes |  |
| `institution_id` | string |  |  |
| `institution_name` | string |  | Institutes only: a name typed because it is not listed — min 2 chars, max 120 chars |
| `year_of_study` | integer |  | Required for university students — ≥ 1, ≤ 7 |
| `home_church` | object |  | Optional at sign-up (can be added later with `PATCH /me`); when sent, all three are required. |
| `accepted_national_activities` | boolean | yes | Agrees to take part in FOCUS national activities (must be true) |
| `password` | string · password | yes | min 8 chars |
| `accepted_terms` | boolean | yes |  |
| `accepted_code_of_conduct` | boolean | yes | Community guidelines shown at sign-up (BRD §8.2) |
| `guardian` | object |  | Optional. Minors can send it now or later via `PUT /me/guardian` (x-open-question - exact definition of minor and consent mechanism TBD with FOCUS Uganda) |

<a id="schema-meetingoccurrence"></a>
### MeetingOccurrence

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  | communityId@local date |
| `community_id` | string |  |  |
| `starts_at` | string · date-time |  |  |
| `room` | string |  |  |
| `going` | boolean |  |  |
| `attended` | boolean |  |  |

<a id="schema-moderationcase"></a>
### ModerationCase

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `community_id` | string |  |  |
| `content` | string (`post`, `comment`, `prayer_request`, `testimony`) |  |  |
| `target_id` | string |  |  |
| `author` | object \| null |  | Null for anonymous prayer requests |
| `preview` | string |  |  |
| `reason` | string |  | The most common reason given |
| `report_count` | integer |  | Distinct reporters |
| `first_reporter_name` | string |  |  |
| `reported_at` | string · date-time |  |  |
| `level` | integer |  |  |
| `outcome` | string (`kept`, `hidden`, `warned`, `escalated`) |  | Present on the reply to an action |

<a id="schema-warning"></a>
### Warning

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `reason` | string |  |  |
| `preview` | string |  |  |
| `created_at` | string · date-time |  |  |
| `acknowledged` | boolean |  |  |

<a id="schema-notification"></a>
### Notification

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `type` | string (`request_approved`, `request_declined`, `comment_reply`, `prayed_for_you`, `prayer_response`, `announcement`, `meeting_reminder`, `inactivity`, `moderator_warning`) |  |  |
| `title` | string |  |  |
| `body` | string \| null |  | nullable |
| `target_route` | string |  | App screen to open, e.g. /post/{id} |
| `read_at` | string \| null · date-time |  | nullable |
| `created_at` | string · date-time |  |  |

<a id="schema-notificationpreferences"></a>
### NotificationPreferences

| Field | Type | Required | Notes |
|---|---|---|---|
| `channels` | array of string (`inApp`, `email`) | yes |  |
| `muted` | array of string (`joinRequestUpdates`, `replies`, `prayerResponses`, `announcements`, `meetingReminders`, `inactivityReminders`) | yes | Muted categories. Moderator warnings cannot be muted. |

<a id="schema-guardianresponse"></a>
### GuardianResponse

| Field | Type | Required | Notes |
|---|---|---|---|
| `guardian` | object \| null |  | nullable |

<a id="schema-institution"></a>
### Institution

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `name` | string |  |  |
| `type` | string (`university`, `institute`, `high_school`) |  |  |
| `country` | string |  |  |

<a id="schema-userref"></a>
### UserRef

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `full_name` | string |  |  |
| `username` | string |  |  |
| `photo_url` | string \| null · uri |  | nullable |
| `community_role` | string (`super_mentor`, `mentor`, `member`) |  |  |
| `online` | boolean |  |  |

<a id="schema-myprofile"></a>
### MyProfile

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `full_name` | string |  |  |
| `username` | string |  |  |
| `photo_url` | string \| null · uri |  | nullable |
| `email` | string \| null · email |  | nullable |
| `phone` | string \| null |  | nullable |
| `email_verified` | boolean |  |  |
| `phone_verified` | boolean |  |  |
| `birthdate` | string · date |  |  |
| `country` | string |  |  |
| `institution` | [Institution](#schema-institution) |  |  |
| `year_of_study` | integer \| null |  | ≥ 1, ≤ 7, nullable |
| `home_church` | null \| object |  |  |
| `accepted_national_activities` | boolean |  |  |
| `minor_status` | string (`adult`, `pending_guardian_consent`, `minor_consented`) |  |  |
| `platform_role` | string (`student`, `leader`, `associate`, `content_admin`, `system_admin`) |  |  |
| `created_at` | string · date-time |  |  |

<a id="schema-communityrole"></a>
### CommunityRole

Type: string (`super_mentor`, `mentor`, `member`)

<a id="schema-communitysummary"></a>
### CommunitySummary

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `type` | string (`general`, `specific`) |  |  |
| `name` | string |  |  |
| `initials` | string |  |  |
| `institution` | [Institution](#schema-institution) |  |  |
| `super_mentor` | [UserRef](#schema-userref) \| null |  |  |
| `meeting` | [Meeting](#schema-meeting) \| null |  |  |
| `can_request` | boolean |  | False when the caller already has a pending/approved specific community |
| `membership_status` | string (`none`, `pending`, `member`) |  |  |

<a id="schema-community"></a>
### Community

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `type` | string (`general`, `specific`) |  |  |
| `name` | string |  |  |
| `initials` | string |  |  |
| `institution` | [Institution](#schema-institution) |  |  |
| `super_mentor` | [UserRef](#schema-userref) \| null |  |  |
| `meeting` | [Meeting](#schema-meeting) \| null |  |  |
| `can_request` | boolean |  | False when the caller already has a pending/approved specific community |
| `membership_status` | string (`none`, `pending`, `member`) |  |  |
| `description` | string |  |  |
| `members_count` | integer |  |  |
| `online_count` | integer |  |  |
| `online_preview` | array of [UserRef](#schema-userref) |  | Avatars for the "Online now" strip |
| `leadership` | array of [UserRef](#schema-userref) |  |  |
| `tabs` | array of string |  | Tabs shown in the community header (Feed, Prayer, Testimonies, Pathways, Resources, Info & members) |

<a id="schema-meeting"></a>
### Meeting

| Field | Type | Required | Notes |
|---|---|---|---|
| `recurrence` | string |  |  |
| `weekday` | string (`mon`, `tue`, `wed`, `thu`, `fri`, `sat`, `sun`) |  |  |
| `start_time` | string |  |  |
| `timezone` | string |  |  |
| `location` | string |  |  |

<a id="schema-mymembership"></a>
### MyMembership

| Field | Type | Required | Notes |
|---|---|---|---|
| `community` | [CommunitySummary](#schema-communitysummary) |  |  |
| `membership_status` | string (`member`, `pending`) |  |  |
| `joined_at` | string \| null · date-time |  | nullable |
| `join_request_id` | string \| null |  | While pending: the request's id, so it can be cancelled (DELETE /join-requests/{id}) without another call. Null once a member. — nullable |

<a id="schema-member"></a>
### Member

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `full_name` | string |  |  |
| `username` | string |  |  |
| `photo_url` | string \| null · uri |  | nullable |
| `community_role` | string (`super_mentor`, `mentor`, `member`) |  |  |
| `online` | boolean |  |  |
| `joined_at` | string · date-time |  |  |

<a id="schema-joinrequest"></a>
### JoinRequest

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `community` | [CommunitySummary](#schema-communitysummary) |  |  |
| `user` | [UserRef](#schema-userref) |  |  |
| `status` | string (`pending`, `approved`, `rejected`, `cancelled`) |  |  |
| `created_at` | string · date-time |  |  |
| `decided_at` | string \| null · date-time |  | nullable |
| `note` | string \| null |  | The super-mentor's message when declining — nullable |

<a id="schema-mediaitem"></a>
### MediaItem

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `kind` | string (`image`, `video`) |  |  |
| `url` | string · uri |  |  |
| `thumbnail_url` | string \| null · uri |  | nullable |
| `duration_seconds` | integer \| null |  | nullable |

<a id="schema-post"></a>
### Post

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `community_id` | string |  |  |
| `kind` | string (`post`, `question`) |  | A question is answered in its comments |
| `anonymous` | boolean |  |  |
| `author` | [UserRef](#schema-userref) \| null |  | Null when the post is anonymous (moderators see the author in the back office) |
| `is_mine` | boolean |  | The viewer wrote it (also for anonymous posts) |
| `text` | string |  |  |
| `media` | array of [MediaItem](#schema-mediaitem) |  |  |
| `pinned` | boolean |  |  |
| `like_count` | integer |  |  |
| `comment_count` | integer |  |  |
| `liked_by_me` | boolean |  |  |
| `follower_count` | integer |  | Questions only |
| `following` | boolean |  | Questions only; the viewer follows it |
| `passed_by_me` | boolean |  | Questions only; the viewer chose "Pass" on answering it |
| `created_at` | string · date-time |  |  |

<a id="schema-comment"></a>
### Comment

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `author` | [UserRef](#schema-userref) |  |  |
| `text` | string |  |  |
| `vote_count` | integer |  | Helpful votes (answers to questions) |
| `voted_by_me` | boolean |  |  |
| `created_at` | string · date-time |  |  |

<a id="schema-prayerresponse"></a>
### PrayerResponse

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `author` | [UserRef](#schema-userref) \| null |  | Null when the reply is anonymous |
| `anonymous` | boolean |  | True when the owner of an anonymous request replied on it |
| `text` | string |  |  |
| `created_at` | string · date-time |  |  |

<a id="schema-followstate"></a>
### FollowState

| Field | Type | Required | Notes |
|---|---|---|---|
| `follower_count` | integer |  |  |
| `following` | boolean |  |  |

<a id="schema-votestate"></a>
### VoteState

| Field | Type | Required | Notes |
|---|---|---|---|
| `vote_count` | integer |  |  |
| `voted_by_me` | boolean |  |  |

<a id="schema-encouragedstate"></a>
### EncouragedState

| Field | Type | Required | Notes |
|---|---|---|---|
| `encouraged_count` | integer |  |  |
| `encouraged_by_me` | boolean |  |  |

<a id="schema-reflection"></a>
### Reflection

| Field | Type | Required | Notes |
|---|---|---|---|
| `text` | string |  | Empty when the member has not written one |
| `updated_at` | string \| null · date-time |  | nullable |

<a id="schema-reactionstate"></a>
### ReactionState

| Field | Type | Required | Notes |
|---|---|---|---|
| `like_count` | integer |  |  |
| `liked_by_me` | boolean |  |  |

<a id="schema-prayerrequest"></a>
### PrayerRequest

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `community_id` | string |  |  |
| `author` | [UserRef](#schema-userref) \| null |  | Null when anonymous |
| `text` | string |  |  |
| `prayed_count` | integer |  |  |
| `prayed_by_me` | boolean |  |  |
| `response_count` | integer |  |  |
| `created_at` | string · date-time |  |  |

<a id="schema-testimony"></a>
### Testimony

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `community_id` | string |  |  |
| `format` | string (`video`, `story`) |  |  |
| `title` | string |  |  |
| `excerpt` | string |  |  |
| `body` | string \| null |  | Full text — nullable |
| `media` | array of [MediaItem](#schema-mediaitem) |  |  |
| `author` | [UserRef](#schema-userref) |  |  |
| `institution_name` | string |  |  |
| `status` | string (`pending_review`, `published`, `rejected`) |  |  |
| `reviewed` | boolean |  | Shows the "Reviewed" badge |
| `approved_by` | string \| null |  | Approver name (traceability — nullable |
| `published_at` | string \| null · date-time |  | nullable |
| `encouraged_count` | integer |  | "Encouraged" reactions |
| `encouraged_by_me` | boolean |  |  |
| `created_at` | string · date-time |  |  |

<a id="schema-pathwaysummary"></a>
### PathwaySummary

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `title` | string |  |  |
| `steps_total` | integer |  |  |
| `steps_completed` | integer |  |  |
| `current_step` | integer \| null |  | nullable |
| `status` | string (`locked`, `available`, `in_progress`, `completed`) |  |  |
| `unlock_hint` | string \| null |  | nullable |

<a id="schema-pathwaydetail"></a>
### PathwayDetail

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `title` | string |  |  |
| `steps_total` | integer |  |  |
| `steps_completed` | integer |  |  |
| `current_step` | integer \| null |  | nullable |
| `status` | string (`locked`, `available`, `in_progress`, `completed`) |  |  |
| `unlock_hint` | string \| null |  | nullable |
| `steps` | array of object |  |  |

<a id="schema-resourcetype"></a>
### ResourceType

Type: string (`video`, `devotional`, `quiz`, `document`)

<a id="schema-resource"></a>
### Resource

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `type` | string (`video`, `devotional`, `quiz`, `document`) |  |  |
| `title` | string |  |  |
| `category` | string (`bible_characters`, `bible_texts`) |  |  |
| `tags` | array of string |  |  |
| `bible_book` | string \| null |  | nullable |
| `duration_seconds` | integer \| null |  | Video length — nullable |
| `read_minutes` | integer \| null |  | Devotional length — nullable |
| `question_count` | integer \| null |  | Quiz only — nullable |
| `file_size_bytes` | integer \| null |  | Document only — nullable |
| `added_by` | [UserRef](#schema-userref) |  |  |
| `thumbnail_url` | string \| null · uri |  | nullable |
| `stream_url` | string \| null · uri |  | Video (HLS) — nullable |
| `body_html` | string \| null |  | Devotional body — nullable |
| `document_url` | string \| null · uri |  | nullable |
| `offline_available` | boolean |  |  |
| `download_url` | string \| null · uri |  | nullable |
| `language` | string |  |  |
| `status` | string (`published`) |  |  |
| `my_progress` | object |  |  |

<a id="schema-quiz"></a>
### Quiz

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `title` | string |  |  |
| `pass_mark_percent` | integer |  |  |
| `questions` | array of object |  |  |
| `my_last_attempt` | null \| object |  | The caller's most recent attempt, or null. Only their own choices; the correct answers are never sent. |

<a id="schema-badge"></a>
### Badge

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `name` | string |  |  |
| `icon_url` | string \| null · uri |  | nullable |
| `earned` | boolean |  |  |
| `earned_at` | string \| null · date-time |  | nullable |

<a id="schema-activityevent"></a>
### ActivityEvent

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `type` | string (`video_watched`, `quiz_completed`, `meeting_attended`, `prayed`, `post_created`, `pathway_step_completed`, `testimony_submitted`) |  |  |
| `label` | string |  |  |
| `occurred_at` | string · date-time |  |  |

<a id="schema-conversationsummary"></a>
### ConversationSummary

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `participant` | [UserRef](#schema-userref) |  |  |
| `kind` | string (`mentor`, `member`, `general_community`) |  |  |
| `last_message` | string |  |  |
| `last_message_at` | string · date-time |  |  |
| `unread_count` | integer |  |  |

<a id="schema-message"></a>
### Message

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `conversation_id` | string |  |  |
| `sender_id` | string |  |  |
| `text` | string |  |  |
| `sent_at` | string · date-time |  |  |
| `read_at` | string \| null · date-time |  | nullable |

<a id="schema-reportrequest"></a>
### ReportRequest

| Field | Type | Required | Notes |
|---|---|---|---|
| `target_type` | string (`user`, `message`, `post`, `comment`, `testimony`, `prayer_request`) | yes |  |
| `target_id` | string | yes |  |
| `reason` | string (`harassment_bullying`, `offensive_content`, `breaks_community_rules`, `spam_or_fake_profile`, `other`) | yes |  |
| `details` | string |  | Required (not blank) when reason is other — max 2000 chars |
| `evidence_media_id` | string \| null |  | Chat screenshot — nullable |

<a id="schema-publicstory"></a>
### PublicStory

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `quote` | string |  |  |
| `student_name` | string |  |  |
| `institution_name` | string |  |  |
| `institution_type` | string (`university`, `institute`, `high_school`) |  |  |
| `duration_seconds` | integer |  |  |
| `thumbnail_url` | string · uri |  |  |
| `video_url` | string · uri |  |  |
