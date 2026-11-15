# FCU Back Office – Staff API — endpoint reference

> Generated from `openapi-admin.yaml` (OpenAPI 3.1.0, API version 1.0.0) by `docs/api/tools/openapi_to_markdown.js`. Do not edit by hand; regenerate.

**Servers:** `https://apis.focusuganda.org/v1/admin` (Production), `http://localhost:4000/v1/admin` (Local development)

**93 operations** in 22 groups.

## Index

### Auth

Staff sign-in, session cookies, password reset

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | [`/auth/login`](#post-auth-login) | Staff login (creates a server-side session, sets the httpOnly fcu_access cookie) | none (public) |
| `POST` | [`/auth/logout`](#post-auth-logout) | Sign out (ends the session on the server and clears the cookie) | none (public) |
| `POST` | [`/auth/forgot-password`](#post-auth-forgot-password) | Request a reset link (always 200) | none (public) |
| `POST` | [`/auth/reset-password`](#post-auth-reset-password) | Set a new password from a reset token (410 if expired/used) | none (public) |
| `GET` | [`/auth/me`](#get-auth-me) | Current staff user | cookieAuth or bearerAuth |

### Dashboard

Headline numbers for the home screen

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/dashboard`](#get-dashboard) | KPIs, weekly activity, attention items, inactive members | cookieAuth or bearerAuth |

### Members

Students and staff: create, import, roles, suspend, remind

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/members`](#get-members) | List members (q, role, status, communityId, institutionId) | cookieAuth or bearerAuth |
| `POST` | [`/members`](#post-members) | Create a member; minors get a pending guardian-consent record | cookieAuth or bearerAuth |
| `GET` | [`/members/inactive`](#get-members-inactive) | Members inactive beyond 30 days | cookieAuth or bearerAuth |
| `POST` | [`/members/import`](#post-members-import) | Bulk import rows; returns created/skipped/failed per row | cookieAuth or bearerAuth |
| `GET` | [`/members/{id}`](#get-members-id) | Member detail | cookieAuth or bearerAuth |
| `PATCH` | [`/members/{id}/role`](#patch-members-id-role) | Change role (audited, not your own) | cookieAuth or bearerAuth |
| `PATCH` | [`/members/{id}/community`](#patch-members-id-community) | Move to another specific community of the same institution | cookieAuth or bearerAuth |
| `POST` | [`/members/{id}/suspend`](#post-members-id-suspend) | Suspend (reason ≥5 chars); revokes sessions, records a sanction | cookieAuth or bearerAuth |
| `POST` | [`/members/{id}/remind`](#post-members-id-remind) | Send a check-in reminder | cookieAuth or bearerAuth |

### Institutions

Universities and high schools shown at sign-up

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/institutions`](#get-institutions) | List institutions with counts | cookieAuth or bearerAuth |
| `POST` | [`/institutions`](#post-institutions) | Create institution (auto-creates its General community) | cookieAuth or bearerAuth |
| `PATCH` | [`/institutions/{id}`](#patch-institutions-id) | Update institution | cookieAuth or bearerAuth |

### Communities

General and specific communities, leaders, closing

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/communities`](#get-communities) | List communities (super-mentors see only their own) | cookieAuth or bearerAuth |
| `POST` | [`/communities`](#post-communities) | Create community; superMentorId assigns the leader | cookieAuth or bearerAuth |
| `GET` | [`/communities/{id}`](#get-communities-id) | Community detail | cookieAuth or bearerAuth |
| `PATCH` | [`/communities/{id}`](#patch-communities-id) | Update community (super-mentors: details/meeting only) | cookieAuth or bearerAuth |

### Join requests

Approve or decline requests to join a community

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/join-requests`](#get-join-requests) | List requests with conflict info and pending count | cookieAuth or bearerAuth |
| `POST` | [`/join-requests/bulk-approve`](#post-join-requests-bulk-approve) | Approve many; conflicts are skipped with a reason | cookieAuth or bearerAuth |
| `POST` | [`/join-requests/{id}/approve`](#post-join-requests-id-approve) | Approve (409 community_limit_reached if already in another specific community) | cookieAuth or bearerAuth |
| `POST` | [`/join-requests/{id}/decline`](#post-join-requests-id-decline) | Decline with optional reason | cookieAuth or bearerAuth |

### Roles

Staff accounts and their roles

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | [`/roles/staff`](#post-roles-staff) | Create a staff account (super-mentor needs communityId) | cookieAuth or bearerAuth |

### Content

Library content (videos, devotionals, quizzes, documents) and its review workflow

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/content`](#get-content) | Library list. With ?status= returns a bare array of picker options | cookieAuth or bearerAuth |
| `POST` | [`/content`](#post-content) | Create draft (submitForReview:true to submit) | cookieAuth or bearerAuth |
| `GET` | [`/content/{id}`](#get-content-id) | Content detail with approval trail | cookieAuth or bearerAuth |
| `PATCH` | [`/content/{id}`](#patch-content-id) | Edit a draft | cookieAuth or bearerAuth |
| `POST` | [`/content/{id}/transition`](#post-content-id-transition) | Workflow: SUBMIT_FOR_REVIEW, APPROVE_AND_PUBLISH, REQUEST_CHANGES, ARCHIVE, RESTORE_TO_DRAFT. Authors cannot validate their own content (except SYSTEM_ADMIN) | cookieAuth or bearerAuth |
| `GET` | [`/bible-links`](#get-bible-links) | Bible character/text options (?q=) | cookieAuth or bearerAuth |

### Pathways

Discipleship pathways and their steps

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/pathways`](#get-pathways) | List pathways | cookieAuth or bearerAuth |
| `POST` | [`/pathways`](#post-pathways) | Create pathway; publishing requires every step's content to be PUBLISHED | cookieAuth or bearerAuth |
| `GET` | [`/pathways/{id}`](#get-pathways-id) | Pathway detail | cookieAuth or bearerAuth |
| `PUT` | [`/pathways/{id}`](#put-pathways-id) | Update pathway (alias of PATCH) | cookieAuth or bearerAuth |
| `PATCH` | [`/pathways/{id}`](#patch-pathways-id) | Update pathway | cookieAuth or bearerAuth |
| `DELETE` | [`/pathways/{id}`](#delete-pathways-id) | Delete (409 if learners are enrolled) | cookieAuth or bearerAuth |

### Badges

Badges and the rules that award them

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/badges`](#get-badges) | List badges | cookieAuth or bearerAuth |
| `POST` | [`/badges`](#post-badges) | Create badge | cookieAuth or bearerAuth |
| `PUT` | [`/badges/{id}`](#put-badges-id) | Update badge | cookieAuth or bearerAuth |
| `PATCH` | [`/badges/{id}`](#patch-badges-id) | Update badge (same as PUT) | cookieAuth or bearerAuth |
| `DELETE` | [`/badges/{id}`](#delete-badges-id) | Delete (409 if a pathway awards it) | cookieAuth or bearerAuth |

### Announcements

Messages to everyone or to one community

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/announcements`](#get-announcements) | List announcements | cookieAuth or bearerAuth |
| `POST` | [`/announcements`](#post-announcements) | Publish now or schedule (future date required) | cookieAuth or bearerAuth |
| `PATCH` | [`/announcements/{id}`](#patch-announcements-id) | Edit a draft/scheduled announcement | cookieAuth or bearerAuth |

### Stories

Landing page student stories

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/stories`](#get-stories) | Landing-page stories in display order | cookieAuth or bearerAuth |
| `POST` | [`/stories`](#post-stories) | Add story (consentObtained must be true) | cookieAuth or bearerAuth |
| `PATCH` | [`/stories/{id}`](#patch-stories-id) | Toggle visibility | cookieAuth or bearerAuth |
| `PUT` | [`/stories/reorder`](#put-stories-reorder) | Set display order | cookieAuth or bearerAuth |

### Notifications

Notification rules

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/notifications/rules`](#get-notifications-rules) | List notification rules and templates | cookieAuth or bearerAuth |
| `PATCH` | [`/notifications/rules/{id}`](#patch-notifications-rules-id) | Edit template / channels / enabled (≥1 channel required) | cookieAuth or bearerAuth |

### Settings

Platform settings

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/settings/inactivity-threshold`](#get-settings-inactivity-threshold) | Days before a member counts as inactive | cookieAuth or bearerAuth |
| `PUT` | [`/settings/inactivity-threshold`](#put-settings-inactivity-threshold) | Set the threshold (1–365) | cookieAuth or bearerAuth |
| `GET` | [`/settings/{section}`](#get-settings-section) | section = charter \| consents \| minors \| retention | cookieAuth or bearerAuth |
| `PATCH` | [`/settings/{section}`](#patch-settings-section) | Update a section (audited) | cookieAuth or bearerAuth |

### Moderation

Reports, flagged posts, testimony review and sanctions

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/moderation/reports`](#get-moderation-reports) | Open/in-review reports in the caller's scope | cookieAuth or bearerAuth |
| `POST` | [`/moderation/reports/{id}/action`](#post-moderation-reports-id-action) | DISMISS, WARN, HIDE, ESCALATE (any); SUSPEND, DELETE (system admin only). Notes required | cookieAuth or bearerAuth |
| `GET` | [`/moderation/testimonies`](#get-moderation-testimonies) | Testimonies awaiting review | cookieAuth or bearerAuth |
| `POST` | [`/moderation/testimonies/{id}/review`](#post-moderation-testimonies-id-review) | APPROVE, REQUEST_CHANGES, REJECT (notes required unless approving) | cookieAuth or bearerAuth |
| `GET` | [`/moderation/posts`](#get-moderation-posts) | Reported or hidden posts, prayer requests and comments | cookieAuth or bearerAuth |
| `POST` | [`/moderation/posts/{id}/action`](#post-moderation-posts-id-action) | KEEP, HIDE, WARN_AUTHOR, ESCALATE | cookieAuth or bearerAuth |
| `GET` | [`/moderation/sanctions`](#get-moderation-sanctions) | Warnings and suspensions | cookieAuth or bearerAuth |
| `POST` | [`/moderation/sanctions/{id}/reinstate`](#post-moderation-sanctions-id-reinstate) | Lift a sanction | cookieAuth or bearerAuth |

### Privacy

Data export and deletion requests, guardian consents

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/privacy/guardian-consents`](#get-privacy-guardian-consents) | Guardian consent records for minors | cookieAuth or bearerAuth |
| `POST` | [`/privacy/guardian-consents/{id}/remind`](#post-privacy-guardian-consents-id-remind) | Remind guardian (emails them when the app has their email address) | cookieAuth or bearerAuth |
| `GET` | [`/privacy/data-requests`](#get-privacy-data-requests) | Export / deletion requests with deadlines | cookieAuth or bearerAuth |
| `POST` | [`/privacy/data-requests/{id}/process`](#post-privacy-data-requests-id-process) | Complete a request. DELETION anonymises the account irreversibly | cookieAuth or bearerAuth |

### Audit

The log of what staff did, and its export

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/audit-log`](#get-audit-log) | Audit entries (q, action, role, period=7d\|30d\|90d) | cookieAuth or bearerAuth |
| `POST` | [`/audit-log/export`](#post-audit-log-export) | Record an export | cookieAuth or bearerAuth |

### Reports

Scheduled and on-demand reports

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/reports`](#get-reports) | Analytics (range, campus, community) | cookieAuth or bearerAuth |
| `POST` | [`/reports/export`](#post-reports-export) | Export as csv or json (pdf/xlsx → 501) | cookieAuth or bearerAuth |
| `GET` | [`/reports/schedules`](#get-reports-schedules) | Scheduled reports | cookieAuth or bearerAuth |
| `POST` | [`/reports/schedules`](#post-reports-schedules) | Schedule a report | cookieAuth or bearerAuth |
| `PATCH` | [`/reports/schedules/{id}`](#patch-reports-schedules-id) | Pause or resume a schedule | cookieAuth or bearerAuth |
| `DELETE` | [`/reports/schedules/{id}`](#delete-reports-schedules-id) | Remove a schedule | cookieAuth or bearerAuth |

### My community

What a super-mentor sees and does for their own community

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/my-community`](#get-my-community) | Super-mentor home: KPIs, requests, members, reports, resources | cookieAuth or bearerAuth |
| `POST` | [`/my-community/join-requests/{id}/approve`](#post-my-community-join-requests-id-approve) | Approve a request for your community | cookieAuth or bearerAuth |
| `POST` | [`/my-community/join-requests/{id}/decline`](#post-my-community-join-requests-id-decline) | Decline a request | cookieAuth or bearerAuth |
| `PATCH` | [`/my-community/meeting`](#patch-my-community-meeting) | Set next meeting {day,time,place} | cookieAuth or bearerAuth |
| `POST` | [`/my-community/members/{id}/remind`](#post-my-community-members-id-remind) | Remind an inactive member | cookieAuth or bearerAuth |
| `POST` | [`/my-community/announcements`](#post-my-community-announcements) | Write to the group | cookieAuth or bearerAuth |
| `POST` | [`/my-community/moderation/{id}`](#post-my-community-moderation-id) | First-level decision: dismiss \| escalate | cookieAuth or bearerAuth |

### Account

The signed-in staff member: profile, password, sessions

| Method | Path | Summary | Auth |
|---|---|---|---|
| `PATCH` | [`/account/profile`](#patch-account-profile) | Update own name/avatar | cookieAuth or bearerAuth |
| `POST` | [`/account/password`](#post-account-password) | Change password (signs out every other device) | cookieAuth or bearerAuth |
| `GET` | [`/account/sessions`](#get-account-sessions) | Own active sessions (server-side; `current` marks this device) | cookieAuth or bearerAuth |
| `DELETE` | [`/account/sessions/{id}`](#delete-account-sessions-id) | Revoke a session (that device is signed out on its next request) | cookieAuth or bearerAuth |

### Media

File uploads for covers, thumbnails, videos, documents and story videos

| Method | Path | Summary | Auth |
|---|---|---|---|
| `POST` | [`/media`](#post-media) | Start an upload (returns where to send the file and its permanent address) | cookieAuth or bearerAuth |
| `PUT` | [`/media/{id}/upload`](#put-media-id-upload) | Send the file bytes (local-storage mode only; with R2 upload to the signed URL instead) | cookieAuth or bearerAuth |
| `POST` | [`/media/{id}/complete`](#post-media-id-complete) | Confirm the upload arrived; returns the permanent file address | cookieAuth or bearerAuth |

### Email

Why email is (not) working: settings, recent sends, and a test message

| Method | Path | Summary | Auth |
|---|---|---|---|
| `GET` | [`/email/status`](#get-email-status) | Email settings (never the key) and what happened to the last sends | cookieAuth or bearerAuth |
| `POST` | [`/email/test`](#post-email-test) | Send a real test email and report Resend's own answer | cookieAuth or bearerAuth |

## Endpoints

## Auth

<a id="post-auth-login"></a>
### `POST /auth/login`

**Staff login (creates a server-side session, sets the httpOnly fcu_access cookie)**

Roles: public

- **Auth:** none (public)
- **Operation id:** `postAuthLogin`

**Request body** (`application/json`, required): [LoginBody](#schema-loginbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `email` | string | yes |  |
| `password` | string | yes |  |
| `rememberMe` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [SessionResponse](#schema-sessionresponse) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-auth-logout"></a>
### `POST /auth/logout`

**Sign out (ends the session on the server and clears the cookie)**

Roles: public

- **Auth:** none (public)
- **Operation id:** `postAuthLogout`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-auth-forgot-password"></a>
### `POST /auth/forgot-password`

**Request a reset link (always 200)**

Roles: public

- **Auth:** none (public)
- **Operation id:** `postAuthForgotpassword`

**Request body** (`application/json`, required): [EmailBody](#schema-emailbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `email` | string · email | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-auth-reset-password"></a>
### `POST /auth/reset-password`

**Set a new password from a reset token (410 if expired/used)**

Roles: public

- **Auth:** none (public)
- **Operation id:** `postAuthResetpassword`

**Request body** (`application/json`, required): [ResetBody](#schema-resetbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `token` | string | yes |  |
| `password` | string | yes | ≥8 chars, letter + number |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-auth-me"></a>
### `GET /auth/me`

**Current staff user**

Roles: any staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getAuthMe`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [SessionResponse](#schema-sessionresponse) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## Dashboard

<a id="get-dashboard"></a>
### `GET /dashboard`

**KPIs, weekly activity, attention items, inactive members**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getDashboard`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Dashboard](#schema-dashboard) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## Members

<a id="get-members"></a>
### `GET /members`

**List members (q, role, status, communityId, institutionId)**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getMembers`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MemberList](#schema-memberlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-members"></a>
### `POST /members`

**Create a member; minors get a pending guardian-consent record**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMembers`

**Request body** (`application/json`, required): [AddMember](#schema-addmember)

| Field | Type | Required | Notes |
|---|---|---|---|
| `fullName` | string | yes |  |
| `email` | string · email | yes |  |
| `phone` | string |  |  |
| `birthdate` | string · date |  |  |
| `role` | string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`) |  |  |
| `institutionId` | string | yes |  |
| `communityId` | string |  |  |
| `guardianConsentReceived` | boolean |  |  |
| `sendInvitation` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Member](#schema-member) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-members-inactive"></a>
### `GET /members/inactive`

**Members inactive beyond 30 days**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getMembersInactive`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MemberList](#schema-memberlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-members-import"></a>
### `POST /members/import`

**Bulk import rows; returns created/skipped/failed per row**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMembersImport`

**Request body** (`application/json`, required): [ImportBody](#schema-importbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `rows` | array of [AddMember](#schema-addmember) | yes | max 2000 items |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ImportResult](#schema-importresult) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-members-id"></a>
### `GET /members/{id}`

**Member detail**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getMembersId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Member](#schema-member) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-members-id-role"></a>
### `PATCH /members/{id}/role`

**Change role (audited, not your own)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchMembersIdRole`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [RoleBody](#schema-rolebody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `role` | string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`) | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Member](#schema-member) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-members-id-community"></a>
### `PATCH /members/{id}/community`

**Move to another specific community of the same institution**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchMembersIdCommunity`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [CommunityIdBody](#schema-communityidbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `communityId` | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Member](#schema-member) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-members-id-suspend"></a>
### `POST /members/{id}/suspend`

**Suspend (reason ≥5 chars); revokes sessions, records a sanction**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMembersIdSuspend`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [ReasonBody](#schema-reasonbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | string | yes | min 3 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Member](#schema-member) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-members-id-remind"></a>
### `POST /members/{id}/remind`

**Send a check-in reminder**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMembersIdRemind`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Institutions

<a id="get-institutions"></a>
### `GET /institutions`

**List institutions with counts**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getInstitutions`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [InstitutionList](#schema-institutionlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-institutions"></a>
### `POST /institutions`

**Create institution (auto-creates its General community)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postInstitutions`

**Request body** (`application/json`, required): [InstitutionBody](#schema-institutionbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `type` | string (`UNIVERSITY`, `HIGH_SCHOOL`) | yes |  |
| `country` | string (`Uganda`, `Kenya`, `Rwanda`) |  |  |
| `city` | string | yes |  |
| `generalCoverUrl` | string |  |  |
| `shownInSignup` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Institution](#schema-institution) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-institutions-id"></a>
### `PATCH /institutions/{id}`

**Update institution**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchInstitutionsId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [InstitutionBody](#schema-institutionbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `type` | string (`UNIVERSITY`, `HIGH_SCHOOL`) | yes |  |
| `country` | string (`Uganda`, `Kenya`, `Rwanda`) |  |  |
| `city` | string | yes |  |
| `generalCoverUrl` | string |  |  |
| `shownInSignup` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Institution](#schema-institution) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Communities

<a id="get-communities"></a>
### `GET /communities`

**List communities (super-mentors see only their own)**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getCommunities`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [CommunityList](#schema-communitylist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-communities"></a>
### `POST /communities`

**Create community; superMentorId assigns the leader**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postCommunities`

**Request body** (`application/json`, required): [CommunityBody](#schema-communitybody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `institutionId` | string | yes |  |
| `kind` | string (`GENERAL`, `SPECIFIC`) |  |  |
| `name` | string | yes |  |
| `description` | string |  |  |
| `coverPhotoUrl` | string |  |  |
| `meetingDay` | string |  |  |
| `meetingTime` | string |  |  |
| `meetingPlace` | string |  |  |
| `superMentorId` | string |  |  |
| `mentorIds` | array of string |  |  |
| `openForJoinRequests` | boolean |  |  |
| `status` | string (`ACTIVE`, `CLOSED`) |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Community](#schema-community) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-communities-id"></a>
### `GET /communities/{id}`

**Community detail**

Roles: staff (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getCommunitiesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [CommunityDetail](#schema-communitydetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-communities-id"></a>
### `PATCH /communities/{id}`

**Update community (super-mentors: details/meeting only)**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (own)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchCommunitiesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [CommunityBody](#schema-communitybody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `institutionId` | string | yes |  |
| `kind` | string (`GENERAL`, `SPECIFIC`) |  |  |
| `name` | string | yes |  |
| `description` | string |  |  |
| `coverPhotoUrl` | string |  |  |
| `meetingDay` | string |  |  |
| `meetingTime` | string |  |  |
| `meetingPlace` | string |  |  |
| `superMentorId` | string |  |  |
| `mentorIds` | array of string |  |  |
| `openForJoinRequests` | boolean |  |  |
| `status` | string (`ACTIVE`, `CLOSED`) |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [CommunityDetail](#schema-communitydetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Join requests

<a id="get-join-requests"></a>
### `GET /join-requests`

**List requests with conflict info and pending count**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped), CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getJoinrequests`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [JoinRequestList](#schema-joinrequestlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-join-requests-bulk-approve"></a>
### `POST /join-requests/bulk-approve`

**Approve many; conflicts are skipped with a reason**

Roles: SYSTEM_ADMIN, SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postJoinrequestsBulkapprove`

**Request body** (`application/json`, required): [IdsBody](#schema-idsbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `ids` | array of string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [BulkResult](#schema-bulkresult) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-join-requests-id-approve"></a>
### `POST /join-requests/{id}/approve`

**Approve (409 community_limit_reached if already in another specific community)**

Roles: SYSTEM_ADMIN, SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postJoinrequestsIdApprove`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [JoinRequest](#schema-joinrequest) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-join-requests-id-decline"></a>
### `POST /join-requests/{id}/decline`

**Decline with optional reason**

Roles: SYSTEM_ADMIN, SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postJoinrequestsIdDecline`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [OptReasonBody](#schema-optreasonbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [JoinRequest](#schema-joinrequest) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Roles

<a id="post-roles-staff"></a>
### `POST /roles/staff`

**Create a staff account (super-mentor needs communityId)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postRolesStaff`

**Request body** (`application/json`, required): [StaffBody](#schema-staffbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `fullName` | string | yes |  |
| `email` | string | yes |  |
| `role` | string (`SYSTEM_ADMIN`, `CONTENT_ADMIN`, `SUPER_MENTOR`) | yes |  |
| `communityId` | string |  |  |
| `sendInviteEmail` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Member](#schema-member) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Content

<a id="get-content"></a>
### `GET /content`

**Library list. With ?status= returns a bare array of picker options**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN, SUPER_MENTOR (published only)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getContent`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ContentItemList](#schema-contentitemlist) \| array of [ContentItem](#schema-contentitem) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-content"></a>
### `POST /content`

**Create draft (submitForReview:true to submit)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postContent`

**Request body** (`application/json`, required): [ContentBody](#schema-contentbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes |  |
| `type` | string (`VIDEO`, `DEVOTIONAL`, `QUIZ`, `DOCUMENT`) | yes |  |
| `bibleLink` | string | yes | id from /bible-links |
| `language` | string |  |  |
| `tags` | array of string |  |  |
| `description` | string |  |  |
| `validatorName` | string |  |  |
| `pathwayIds` | array of string |  |  |
| `body` | string |  |  |
| `videoUrl` | string |  |  |
| `thumbnailUrl` | string |  |  |
| `documentUrl` | string |  |  |
| `submitForReview` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [ContentItem](#schema-contentitem) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-content-id"></a>
### `GET /content/{id}`

**Content detail with approval trail**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getContentId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ContentItemDetail](#schema-contentitemdetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-content-id"></a>
### `PATCH /content/{id}`

**Edit a draft**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchContentId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [ContentBody](#schema-contentbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes |  |
| `type` | string (`VIDEO`, `DEVOTIONAL`, `QUIZ`, `DOCUMENT`) | yes |  |
| `bibleLink` | string | yes | id from /bible-links |
| `language` | string |  |  |
| `tags` | array of string |  |  |
| `description` | string |  |  |
| `validatorName` | string |  |  |
| `pathwayIds` | array of string |  |  |
| `body` | string |  |  |
| `videoUrl` | string |  |  |
| `thumbnailUrl` | string |  |  |
| `documentUrl` | string |  |  |
| `submitForReview` | boolean |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ContentItemDetail](#schema-contentitemdetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-content-id-transition"></a>
### `POST /content/{id}/transition`

**Workflow: SUBMIT_FOR_REVIEW, APPROVE_AND_PUBLISH, REQUEST_CHANGES, ARCHIVE, RESTORE_TO_DRAFT. Authors cannot validate their own content (except SYSTEM_ADMIN)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postContentIdTransition`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [TransitionBody](#schema-transitionbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string (`SUBMIT_FOR_REVIEW`, `APPROVE_AND_PUBLISH`, `REQUEST_CHANGES`, `ARCHIVE`, `RESTORE_TO_DRAFT`) | yes |  |
| `notes` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ContentItem](#schema-contentitem) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-bible-links"></a>
### `GET /bible-links`

**Bible character/text options (?q=)**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getBiblelinks`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [BibleLinkList](#schema-biblelinklist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## Pathways

<a id="get-pathways"></a>
### `GET /pathways`

**List pathways**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getPathways`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PathwayList](#schema-pathwaylist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-pathways"></a>
### `POST /pathways`

**Create pathway; publishing requires every step's content to be PUBLISHED**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postPathways`

**Request body** (`application/json`, required): [PathwayBody](#schema-pathwaybody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `theme` | string | yes |  |
| `level` | string (`Beginner`, `Intermediate`, `Advanced`) |  |  |
| `description` | string |  |  |
| `unlockRule` | string (`none`, `previous_pathway`, `profile_complete`, `mentor_assigned`) |  |  |
| `badgeAwardedId` | string \| null |  | nullable |
| `published` | boolean |  |  |
| `steps` | array of object | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Pathway](#schema-pathway) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-pathways-id"></a>
### `GET /pathways/{id}`

**Pathway detail**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getPathwaysId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PathwayDetail](#schema-pathwaydetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="put-pathways-id"></a>
### `PUT /pathways/{id}`

**Update pathway (alias of PATCH)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `putPathwaysId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [PathwayBody](#schema-pathwaybody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `theme` | string | yes |  |
| `level` | string (`Beginner`, `Intermediate`, `Advanced`) |  |  |
| `description` | string |  |  |
| `unlockRule` | string (`none`, `previous_pathway`, `profile_complete`, `mentor_assigned`) |  |  |
| `badgeAwardedId` | string \| null |  | nullable |
| `published` | boolean |  |  |
| `steps` | array of object | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PathwayDetail](#schema-pathwaydetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-pathways-id"></a>
### `PATCH /pathways/{id}`

**Update pathway**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchPathwaysId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [PathwayBody](#schema-pathwaybody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `theme` | string | yes |  |
| `level` | string (`Beginner`, `Intermediate`, `Advanced`) |  |  |
| `description` | string |  |  |
| `unlockRule` | string (`none`, `previous_pathway`, `profile_complete`, `mentor_assigned`) |  |  |
| `badgeAwardedId` | string \| null |  | nullable |
| `published` | boolean |  |  |
| `steps` | array of object | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [PathwayDetail](#schema-pathwaydetail) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="delete-pathways-id"></a>
### `DELETE /pathways/{id}`

**Delete (409 if learners are enrolled)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `deletePathwaysId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | No content | — |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## Badges

<a id="get-badges"></a>
### `GET /badges`

**List badges**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getBadges`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [BadgeList](#schema-badgelist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-badges"></a>
### `POST /badges`

**Create badge**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postBadges`

**Request body** (`application/json`, required): [BadgeBody](#schema-badgebody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `description` | string | yes |  |
| `ruleType` | string (`join_community`, `finish_quizzes`, `pray_requests`, `complete_pathway`, `attend_meetings_streak`) | yes |  |
| `ruleTargetCount` | integer | yes | ≥ 1, ≤ 1000 |
| `icon` | string |  |  |
| `visibleOnProfile` | boolean |  |  |
| `status` | string (`active`, `draft`, `archived`) |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Badge](#schema-badge) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="put-badges-id"></a>
### `PUT /badges/{id}`

**Update badge**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `putBadgesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [BadgeBody](#schema-badgebody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `description` | string | yes |  |
| `ruleType` | string (`join_community`, `finish_quizzes`, `pray_requests`, `complete_pathway`, `attend_meetings_streak`) | yes |  |
| `ruleTargetCount` | integer | yes | ≥ 1, ≤ 1000 |
| `icon` | string |  |  |
| `visibleOnProfile` | boolean |  |  |
| `status` | string (`active`, `draft`, `archived`) |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Badge](#schema-badge) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-badges-id"></a>
### `PATCH /badges/{id}`

**Update badge (same as PUT)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchBadgesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [BadgeBody](#schema-badgebody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `description` | string | yes |  |
| `ruleType` | string (`join_community`, `finish_quizzes`, `pray_requests`, `complete_pathway`, `attend_meetings_streak`) | yes |  |
| `ruleTargetCount` | integer | yes | ≥ 1, ≤ 1000 |
| `icon` | string |  |  |
| `visibleOnProfile` | boolean |  |  |
| `status` | string (`active`, `draft`, `archived`) |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Badge](#schema-badge) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="delete-badges-id"></a>
### `DELETE /badges/{id}`

**Delete (409 if a pathway awards it)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `deleteBadgesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | No content | — |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## Announcements

<a id="get-announcements"></a>
### `GET /announcements`

**List announcements**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getAnnouncements`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [AnnouncementList](#schema-announcementlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-announcements"></a>
### `POST /announcements`

**Publish now or schedule (future date required)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postAnnouncements`

**Request body** (`application/json`, required): [AnnouncementBody](#schema-announcementbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes |  |
| `message` | string | yes |  |
| `audienceType` | string (`all`, `community`) | yes |  |
| `communityId` | string |  |  |
| `imageUrl` | string |  |  |
| `publishTiming` | string (`now`, `scheduled`) |  |  |
| `scheduledFor` | string · date-time |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Announcement](#schema-announcement) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-announcements-id"></a>
### `PATCH /announcements/{id}`

**Edit a draft/scheduled announcement**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchAnnouncementsId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Announcement](#schema-announcement) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Stories

<a id="get-stories"></a>
### `GET /stories`

**Landing-page stories in display order**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getStories`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [StoryList](#schema-storylist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-stories"></a>
### `POST /stories`

**Add story (consentObtained must be true)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postStories`

**Request body** (`application/json`, required): [StoryBody](#schema-storybody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `studentName` | string | yes |  |
| `institution` | string | yes |  |
| `videoUrl` | string | yes |  |
| `duration` | string | yes |  |
| `consentObtained` | boolean | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [Story](#schema-story) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-stories-id"></a>
### `PATCH /stories/{id}`

**Toggle visibility**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchStoriesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Story](#schema-story) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="put-stories-reorder"></a>
### `PUT /stories/reorder`

**Set display order**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `putStoriesReorder`

**Request body** (`application/json`, required): [ReorderBody](#schema-reorderbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `stories` | array of object | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [StoryList](#schema-storylist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Notifications

<a id="get-notifications-rules"></a>
### `GET /notifications/rules`

**List notification rules and templates**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN. Each rule governs one trigger (join request approved/declined, new announcement, prayer received, report received, testimony published, inactivity reminder): whether it fires, through which channels, and the wording that people receive.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getNotificationsRules`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [NotificationRuleList](#schema-notificationrulelist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-notifications-rules-id"></a>
### `PATCH /notifications/rules/{id}`

**Edit template / channels / enabled (≥1 channel required)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN. The template is what recipients get: use {{member_name}}, {{community_name}}, {{item_title}} and {{message_preview}} (unknown placeholders become empty). A disabled rule, or a channel switched off, sends nothing through it. The "report received" rule is emailed to the community's super-mentor.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchNotificationsRulesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [NotificationRule](#schema-notificationrule) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Settings

<a id="get-settings-inactivity-threshold"></a>
### `GET /settings/inactivity-threshold`

**Days before a member counts as inactive**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getSettingsInactivitythreshold`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [InactivityThreshold](#schema-inactivitythreshold) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="put-settings-inactivity-threshold"></a>
### `PUT /settings/inactivity-threshold`

**Set the threshold (1–365)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `putSettingsInactivitythreshold`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [InactivityThreshold](#schema-inactivitythreshold) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-settings-section"></a>
### `GET /settings/{section}`

**section = charter \| consents \| minors \| retention**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getSettingsSection`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `section` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object \| object \| object \| object |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-settings-section"></a>
### `PATCH /settings/{section}`

**Update a section (audited)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchSettingsSection`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `section` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | object \| object \| object \| object |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Moderation

<a id="get-moderation-reports"></a>
### `GET /moderation/reports`

**Open/in-review reports in the caller's scope**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getModerationReports`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ModerationReportList](#schema-moderationreportlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-moderation-reports-id-action"></a>
### `POST /moderation/reports/{id}/action`

**DISMISS, WARN, HIDE, ESCALATE (any); SUSPEND, DELETE (system admin only). Notes required**

Roles: SYSTEM_ADMIN, SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postModerationReportsIdAction`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [ActionBody](#schema-actionbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string | yes | Reports: DISMISS\|WARN\|HIDE\|ESCALATE\|SUSPEND\|DELETE. Posts: KEEP\|HIDE\|WARN_AUTHOR\|ESCALATE |
| `notes` | string | yes | min 3 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ModerationReport](#schema-moderationreport) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-moderation-testimonies"></a>
### `GET /moderation/testimonies`

**Testimonies awaiting review**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getModerationTestimonies`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ModerationTestimonyList](#schema-moderationtestimonylist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-moderation-testimonies-id-review"></a>
### `POST /moderation/testimonies/{id}/review`

**APPROVE, REQUEST_CHANGES, REJECT (notes required unless approving)**

Roles: SYSTEM_ADMIN, SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postModerationTestimoniesIdReview`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [TestimonyReviewBody](#schema-testimonyreviewbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string (`APPROVE`, `REQUEST_CHANGES`, `REJECT`) | yes |  |
| `notes` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ModerationTestimony](#schema-moderationtestimony) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-moderation-posts"></a>
### `GET /moderation/posts`

**Reported or hidden posts, prayer requests and comments**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getModerationPosts`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ModerationPostList](#schema-moderationpostlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-moderation-posts-id-action"></a>
### `POST /moderation/posts/{id}/action`

**KEEP, HIDE, WARN_AUTHOR, ESCALATE**

Roles: SYSTEM_ADMIN, SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postModerationPostsIdAction`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [ActionBody](#schema-actionbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string | yes | Reports: DISMISS\|WARN\|HIDE\|ESCALATE\|SUSPEND\|DELETE. Posts: KEEP\|HIDE\|WARN_AUTHOR\|ESCALATE |
| `notes` | string | yes | min 3 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ModerationPost](#schema-moderationpost) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-moderation-sanctions"></a>
### `GET /moderation/sanctions`

**Warnings and suspensions**

Roles: SYSTEM_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getModerationSanctions`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [SanctionList](#schema-sanctionlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-moderation-sanctions-id-reinstate"></a>
### `POST /moderation/sanctions/{id}/reinstate`

**Lift a sanction**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postModerationSanctionsIdReinstate`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [ReasonBody](#schema-reasonbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | string | yes | min 3 chars |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Sanction](#schema-sanction) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Privacy

<a id="get-privacy-guardian-consents"></a>
### `GET /privacy/guardian-consents`

**Guardian consent records for minors**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getPrivacyGuardianconsents`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [GuardianConsentList](#schema-guardianconsentlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-privacy-guardian-consents-id-remind"></a>
### `POST /privacy/guardian-consents/{id}/remind`

**Remind guardian (emails them when the app has their email address)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postPrivacyGuardianconsentsIdRemind`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ReminderResult](#schema-reminderresult) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-privacy-data-requests"></a>
### `GET /privacy/data-requests`

**Export / deletion requests with deadlines**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getPrivacyDatarequests`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [DataRequestList](#schema-datarequestlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-privacy-data-requests-id-process"></a>
### `POST /privacy/data-requests/{id}/process`

**Complete a request. DELETION anonymises the account irreversibly**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postPrivacyDatarequestsIdProcess`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [DataRequest](#schema-datarequest) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Audit

<a id="get-audit-log"></a>
### `GET /audit-log`

**Audit entries (q, action, role, period=7d\|30d\|90d)**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getAuditlog`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [AuditEntryList](#schema-auditentrylist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-audit-log-export"></a>
### `POST /audit-log/export`

**Record an export**

Roles: SYSTEM_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postAuditlogExport`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Reports

<a id="get-reports"></a>
### `GET /reports`

**Analytics (range, campus, community)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN, SUPER_MENTOR (scoped)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getReports`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ReportsCatalog](#schema-reportscatalog) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-reports-export"></a>
### `POST /reports/export`

**Export as csv or json (pdf/xlsx → 501)**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN, SUPER_MENTOR. `csv` returns the file as text; `json` returns the rows.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postReportsExport`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | The export | string |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |
| `501` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-reports-schedules"></a>
### `GET /reports/schedules`

**Scheduled reports**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getReportsSchedules`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ReportScheduleList](#schema-reportschedulelist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-reports-schedules"></a>
### `POST /reports/schedules`

**Schedule a report**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postReportsSchedules`

**Request body** (`application/json`, required): [ScheduleBody](#schema-schedulebody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `reportType` | string (`discipleship_summary`, `community_health`, `content_completions`) | yes |  |
| `cadence` | string (`weekly`, `monthly`, `quarterly`) | yes |  |
| `recipientEmail` | string · email | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | OK | [ReportSchedule](#schema-reportschedule) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-reports-schedules-id"></a>
### `PATCH /reports/schedules/{id}`

**Pause or resume a schedule**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchReportsSchedulesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `active` | boolean | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [ReportSchedule](#schema-reportschedule) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `404` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="delete-reports-schedules-id"></a>
### `DELETE /reports/schedules/{id}`

**Remove a schedule**

Roles: SYSTEM_ADMIN, CONTENT_ADMIN

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `deleteReportsSchedulesId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | No content | — |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## My community

<a id="get-my-community"></a>
### `GET /my-community`

**Super-mentor home: KPIs, requests, members, reports, resources**

Roles: SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getMycommunity`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MyCommunity](#schema-mycommunity) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-my-community-join-requests-id-approve"></a>
### `POST /my-community/join-requests/{id}/approve`

**Approve a request for your community**

Roles: SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMycommunityJoinrequestsIdApprove`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-my-community-join-requests-id-decline"></a>
### `POST /my-community/join-requests/{id}/decline`

**Decline a request**

Roles: SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMycommunityJoinrequestsIdDecline`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`application/json`, required): [OptReasonBody](#schema-optreasonbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | string |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="patch-my-community-meeting"></a>
### `PATCH /my-community/meeting`

**Set next meeting {day,time,place}**

Roles: SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchMycommunityMeeting`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Object](#schema-object) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-my-community-members-id-remind"></a>
### `POST /my-community/members/{id}/remind`

**Remind an inactive member**

Roles: SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMycommunityMembersIdRemind`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-my-community-announcements"></a>
### `POST /my-community/announcements`

**Write to the group**

Roles: SUPER_MENTOR. Publishes straight away to the members of the super-mentor's community.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMycommunityAnnouncements`

**Request body** (`application/json`, required)

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string |  |  |
| `message` | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Published | object |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-my-community-moderation-id"></a>
### `POST /my-community/moderation/{id}`

**First-level decision: dismiss \| escalate**

Roles: SUPER_MENTOR

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMycommunityModerationId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

## Account

<a id="patch-account-profile"></a>
### `PATCH /account/profile`

**Update own name/avatar**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `patchAccountProfile`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-account-password"></a>
### `POST /account/password`

**Change password (signs out every other device)**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postAccountPassword`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="get-account-sessions"></a>
### `GET /account/sessions`

**Own active sessions (server-side; `current` marks this device)**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getAccountSessions`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [SessionList](#schema-sessionlist) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="delete-account-sessions-id"></a>
### `DELETE /account/sessions/{id}`

**Revoke a session (that device is signed out on its next request)**

Roles: staff

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `deleteAccountSessionsId`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [Ok](#schema-ok) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

## Media

<a id="post-media"></a>
### `POST /media`

**Start an upload (returns where to send the file and its permanent address)**

Roles: staff. Allowed per `purpose`: `cover_photo` (jpeg/png, 5 MB), `content_thumbnail` (jpeg/png/webp, 5 MB),
`content_video` (mp4/webm/quicktime, 500 MB), `content_document` (pdf/doc/docx, 25 MB), `story_video` (mp4/webm/quicktime, 200 MB).

With Cloudflare R2 (`direct: true`) the browser `PUT`s the file to `upload_url` with `upload_headers`; otherwise it sends
the bytes to `PUT /media/{id}/upload`. Then call `POST /media/{id}/complete` and store the returned `url` on the record.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMedia`

**Request body** (`application/json`, required): [MediaSlotBody](#schema-mediaslotbody)

| Field | Type | Required | Notes |
|---|---|---|---|
| `purpose` | string (`cover_photo`, `content_thumbnail`, `content_video`, `content_document`, `story_video`) | yes |  |
| `content_type` | string | yes |  |
| `size_bytes` | integer | yes | ≥ 1 |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `201` | Created | [MediaSlot](#schema-mediaslot) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="put-media-id-upload"></a>
### `PUT /media/{id}/upload`

**Send the file bytes (local-storage mode only; with R2 upload to the signed URL instead)**

Roles: staff (the uploader). Body is the raw file; `Content-Type` must match the slot.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `putMediaIdUpload`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Request body** (`*/*`, required)

Type: string · binary

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `204` | Stored | — |
| `400` | RFC 7807 problem | [Problem](#schema-problem) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `404` | RFC 7807 problem | [Problem](#schema-problem) |
| `409` | RFC 7807 problem | [Problem](#schema-problem) |
| `413` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-media-id-complete"></a>
### `POST /media/{id}/complete`

**Confirm the upload arrived; returns the permanent file address**

Roles: staff (the uploader)

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postMediaIdComplete`

**Parameters**

| Name | In | Type | Required | Notes |
|---|---|---|---|---|
| `id` | path | string | yes |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [MediaReady](#schema-mediaready) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `404` | RFC 7807 problem | [Problem](#schema-problem) |
| `409` | RFC 7807 problem | [Problem](#schema-problem) |

## Email

<a id="get-email-status"></a>
### `GET /email/status`

**Email settings (never the key) and what happened to the last sends**

Roles: SYSTEM_ADMIN. `problems` lists settings that would break email (unverified sender, links to localhost); `recent` shows the last 20 sends with Resend's error when one failed.

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `getEmailStatus`

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [EmailStatus](#schema-emailstatus) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |

<a id="post-email-test"></a>
### `POST /email/test`

**Send a real test email and report Resend's own answer**

Roles: SYSTEM_ADMIN. Sends to `to`, or to the signed-in administrator when omitted. On failure the problem's `detail` is the provider's message (wrong key, unverified sender...).

- **Auth:** cookieAuth or bearerAuth
- **Operation id:** `postEmailTest`

**Request body** (`application/json`)

| Field | Type | Required | Notes |
|---|---|---|---|
| `to` | string · email |  |  |

**Responses**

| Status | Meaning | Body |
|---|---|---|
| `200` | OK | [EmailTestResult](#schema-emailtestresult) |
| `401` | RFC 7807 problem | [Problem](#schema-problem) |
| `403` | RFC 7807 problem | [Problem](#schema-problem) |
| `422` | RFC 7807 problem | [Problem](#schema-problem) |
| `502` | RFC 7807 problem | [Problem](#schema-problem) |

## Schemas

<a id="schema-institution"></a>
### Institution

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `name` | string | yes |  |
| `type` | string | yes |  |
| `country` | string | yes |  |
| `city` | string | yes |  |
| `generalCoverUrl` | string | yes |  |
| `shownInSignup` | boolean | yes |  |
| `communityCount` | integer | yes |  |
| `studentCount` | integer | yes |  |
| `createdAt` | string · date-time | yes |  |

<a id="schema-community"></a>
### Community

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `institutionId` | string | yes |  |
| `institutionName` | string | yes |  |
| `kind` | string | yes |  |
| `name` | string | yes |  |
| `description` | string | yes |  |
| `coverPhotoUrl` | string | yes |  |
| `meetingDay` | string | yes |  |
| `meetingTime` | string | yes |  |
| `meetingPlace` | string | yes |  |
| `superMentorId` | string | yes |  |
| `superMentorName` | string \| null | yes | nullable |
| `mentorIds` | array of string | yes |  |
| `openForJoinRequests` | boolean | yes |  |
| `status` | string | yes |  |
| `memberCount` | integer | yes |  |
| `createdAt` | string · date-time | yes |  |

<a id="schema-communitydetail"></a>
### CommunityDetail

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `institutionId` | string |  |  |
| `institutionName` | string |  |  |
| `kind` | string |  |  |
| `name` | string |  |  |
| `description` | string |  |  |
| `coverPhotoUrl` | string |  |  |
| `meetingDay` | string |  |  |
| `meetingTime` | string |  |  |
| `meetingPlace` | string |  |  |
| `superMentorId` | string |  |  |
| `superMentorName` | string \| null |  | nullable |
| `mentorIds` | array of any |  |  |
| `openForJoinRequests` | boolean |  |  |
| `status` | string |  |  |
| `memberCount` | integer |  |  |
| `createdAt` | string · date-time |  |  |

<a id="schema-joinrequest"></a>
### JoinRequest

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `studentId` | string |  |  |
| `studentUsername` | string |  |  |
| `institutionName` | string |  |  |
| `requestedCommunityId` | string |  |  |
| `requestedCommunityName` | string |  |  |
| `requestedAt` | string · date-time |  |  |
| `status` | string |  |  |
| `currentSpecificCommunityId` | string \| null |  | nullable |
| `currentSpecificCommunityName` | string \| null |  | nullable |

<a id="schema-contentitem"></a>
### ContentItem

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `title` | string | yes |  |
| `type` | string | yes |  |
| `bibleLink` | string |  |  |
| `language` | string |  |  |
| `tags` | array of any |  |  |
| `description` | string |  |  |
| `validatorName` | string |  |  |
| `pathwayIds` | array of any |  |  |
| `body` | string |  |  |
| `videoUrl` | string |  |  |
| `thumbnailUrl` | string |  |  |
| `documentUrl` | string |  |  |
| `status` | string |  |  |
| `authorName` | string |  |  |
| `validatedAt` | string \| null · date-time |  | nullable |
| `updatedAt` | string · date-time |  |  |
| `version` | integer |  |  |
| `approvalTrail` | array of object |  |  |
| `published` | boolean |  |  |

<a id="schema-contentitemdetail"></a>
### ContentItemDetail

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `title` | string | yes |  |
| `type` | string | yes |  |
| `bibleLink` | string | yes |  |
| `language` | string | yes |  |
| `tags` | array of any | yes |  |
| `description` | string | yes |  |
| `validatorName` | string | yes |  |
| `pathwayIds` | array of any | yes |  |
| `body` | string | yes |  |
| `videoUrl` | string | yes |  |
| `thumbnailUrl` | string | yes |  |
| `documentUrl` | string | yes |  |
| `status` | string | yes |  |
| `authorName` | string | yes |  |
| `validatedAt` |  | yes |  |
| `updatedAt` | string · date-time | yes |  |
| `version` | integer | yes |  |
| `approvalTrail` | array of object | yes |  |

<a id="schema-biblelink"></a>
### BibleLink

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `label` | string | yes |  |
| `kind` | string | yes |  |

<a id="schema-pathway"></a>
### Pathway

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `name` | string | yes |  |
| `theme` | string | yes |  |
| `level` | string | yes |  |
| `description` | string | yes |  |
| `steps` | array of object | yes |  |
| `unlockRule` | string | yes |  |
| `badgeAwardedId` |  | yes |  |
| `badgeName` |  | yes |  |
| `learnersCount` | integer | yes |  |
| `published` | boolean | yes |  |
| `updatedAt` | string · date-time | yes |  |

<a id="schema-pathwaydetail"></a>
### PathwayDetail

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `name` | string | yes |  |
| `theme` | string | yes |  |
| `level` | string | yes |  |
| `description` | string | yes |  |
| `steps` | array of object | yes |  |
| `unlockRule` | string | yes |  |
| `badgeAwardedId` |  | yes |  |
| `badgeName` |  | yes |  |
| `learnersCount` | integer | yes |  |
| `published` | boolean | yes |  |
| `updatedAt` | string · date-time | yes |  |

<a id="schema-badge"></a>
### Badge

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `name` | string | yes |  |
| `description` | string | yes |  |
| `ruleType` | string | yes |  |
| `ruleTargetCount` | integer | yes |  |
| `ruleDescription` | string | yes |  |
| `icon` | string | yes |  |
| `earnedCount` | integer | yes |  |
| `visibleOnProfile` | boolean | yes |  |
| `status` | string | yes |  |
| `updatedAt` | string · date-time | yes |  |

<a id="schema-announcement"></a>
### Announcement

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `title` | string | yes |  |
| `message` | string | yes |  |
| `audienceType` | string | yes |  |
| `communityId` |  | yes |  |
| `communityName` | string | yes |  |
| `imageUrl` |  | yes |  |
| `scheduledFor` | string \| null · date-time | yes | nullable |
| `status` | string | yes |  |
| `authorName` | string | yes |  |
| `createdAt` | string · date-time | yes |  |

<a id="schema-story"></a>
### Story

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `studentName` | string | yes |  |
| `institution` | string | yes |  |
| `videoUrl` | string | yes |  |
| `duration` | string | yes |  |
| `visible` | boolean | yes |  |
| `order` | integer | yes |  |
| `consentObtained` | boolean | yes |  |
| `createdAt` | string · date-time | yes |  |

<a id="schema-notificationrule"></a>
### NotificationRule

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `triggerKey` | string | yes |  |
| `triggerLabel` | string | yes |  |
| `recipient` | string | yes |  |
| `channels` | object | yes |  |
| `enabled` | boolean | yes |  |
| `template` | object | yes |  |
| `updatedAt` | string · date-time | yes |  |

<a id="schema-moderationreport"></a>
### ModerationReport

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `reason` | string |  |  |
| `reporterName` | string |  |  |
| `reportedUserId` | string |  |  |
| `reportedUserName` | string |  |  |
| `reportedUserRole` | string |  |  |
| `communityId` | string |  |  |
| `communityName` | string |  |  |
| `details` | string |  |  |
| `screenshotUrl` |  |  |  |
| `earlierReportsCount` | integer |  |  |
| `status` | string |  |  |
| `createdAt` | string · date-time |  |  |

<a id="schema-moderationtestimony"></a>
### ModerationTestimony

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `authorName` | string | yes |  |
| `communityId` | string | yes |  |
| `communityName` | string | yes |  |
| `story` | string | yes |  |
| `videoUrl` |  | yes |  |
| `studentAgreement` | boolean | yes |  |
| `notes` |  | yes |  |
| `status` | string | yes |  |
| `createdAt` | string · date-time | yes |  |

<a id="schema-moderationpost"></a>
### ModerationPost

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `kind` | string | yes |  |
| `authorName` | string | yes |  |
| `communityId` | string | yes |  |
| `communityName` | string | yes |  |
| `content` | string | yes |  |
| `reportCount` | integer | yes |  |
| `hidden` | boolean | yes |  |
| `createdAt` | string · date-time | yes |  |

<a id="schema-sanction"></a>
### Sanction

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `userId` | string |  |  |
| `userName` | string |  |  |
| `communityId` | string |  |  |
| `communityName` | string |  |  |
| `type` | string |  |  |
| `reason` | string |  |  |
| `issuedBy` | string |  |  |
| `issuedAt` | string · date-time |  |  |
| `active` | boolean |  |  |

<a id="schema-guardianconsent"></a>
### GuardianConsent

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `studentName` | string |  |  |
| `guardianName` | string |  |  |
| `guardianContact` | string |  |  |
| `status` | string |  |  |
| `updatedAt` | string · date-time |  |  |

<a id="schema-datarequest"></a>
### DataRequest

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `memberName` | string |  |  |
| `memberEmail` | string |  |  |
| `type` | string |  |  |
| `requestedAt` | string · date-time |  |  |
| `deadlineAt` | string · date-time |  |  |
| `status` | string |  |  |

<a id="schema-auditentry"></a>
### AuditEntry

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `occurredAt` | string · date-time |  |  |
| `actorName` | string |  |  |
| `actorRole` | string |  |  |
| `action` | string |  |  |
| `actionLabel` | string |  |  |
| `target` | string |  |  |
| `place` | string |  |  |

<a id="schema-reportschedule"></a>
### ReportSchedule

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string | yes |  |
| `reportType` | string | yes |  |
| `reportLabel` | string | yes |  |
| `cadence` | string | yes |  |
| `recipientEmail` | string | yes |  |
| `active` | boolean | yes |  |

<a id="schema-dashboard"></a>
### Dashboard

| Field | Type | Required | Notes |
|---|---|---|---|
| `kpis` | array of object |  |  |
| `weeklyActivity` | array of object |  |  |
| `needsAttention` | array of object |  |  |
| `inactiveMembers` | array of any |  |  |

<a id="schema-reportscatalog"></a>
### ReportsCatalog

| Field | Type | Required | Notes |
|---|---|---|---|
| `membersOverTime` | array of object |  |  |
| `completionsByType` | array of any |  |  |
| `activeCommunities` | array of object |  |  |
| `scheduledReports` | array of any |  |  |

<a id="schema-mediaslotbody"></a>
### MediaSlotBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `purpose` | string (`cover_photo`, `content_thumbnail`, `content_video`, `content_document`, `story_video`) | yes |  |
| `content_type` | string | yes |  |
| `size_bytes` | integer | yes | ≥ 1 |

<a id="schema-mediaslot"></a>
### MediaSlot

| Field | Type | Required | Notes |
|---|---|---|---|
| `media_id` | string | yes |  |
| `url` | string | yes | Permanent address of the file once uploaded |
| `direct` | boolean | yes | true: PUT to upload_url; false: PUT the bytes to /media/{id}/upload |
| `upload_url` | string \| null | yes | nullable |
| `upload_headers` | object | yes |  |
| `expires_at` | string · date-time | yes |  |

<a id="schema-mediaready"></a>
### MediaReady

| Field | Type | Required | Notes |
|---|---|---|---|
| `media_id` | string | yes |  |
| `status` | string | yes |  |
| `url` | string | yes |  |

<a id="schema-emailstatus"></a>
### EmailStatus

| Field | Type | Required | Notes |
|---|---|---|---|
| `configured` | boolean | yes |  |
| `from` | string | yes |  |
| `replyTo` | string \| null | yes | nullable |
| `backofficeUrl` | string | yes |  |
| `notificationEmails` | boolean | yes |  |
| `problems` | array of string | yes |  |
| `recent` | array of object | yes |  |

<a id="schema-emailtestresult"></a>
### EmailTestResult

| Field | Type | Required | Notes |
|---|---|---|---|
| `ok` | boolean | yes |  |
| `to` | string | yes |  |
| `id` | string \| null | yes | nullable |

<a id="schema-sessionlist"></a>
### SessionList

| Field | Type | Required | Notes |
|---|---|---|---|
| `sessions` | array of object | yes |  |

<a id="schema-mycommunity"></a>
### MyCommunity

| Field | Type | Required | Notes |
|---|---|---|---|
| `communityId` | string |  |  |
| `communityName` | string |  |  |
| `campus` | string |  |  |
| `kpis` | object |  |  |
| `pendingRequests` | array of any |  |  |
| `nextMeeting` | object |  |  |
| `followUpMembers` | array of any |  |  |
| `members` | array of object |  |  |
| `reports` | array of object |  |  |
| `resources` | array of object |  |  |

<a id="schema-institutionlist"></a>
### InstitutionList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Institution](#schema-institution) | yes |  |
| `total` | integer | yes |  |

<a id="schema-communitylist"></a>
### CommunityList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Community](#schema-community) | yes |  |
| `total` | integer | yes |  |

<a id="schema-joinrequestlist"></a>
### JoinRequestList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [JoinRequest](#schema-joinrequest) | yes |  |
| `total` | integer | yes |  |
| `counts` | object |  | Counts per tab (for example per status) |

<a id="schema-contentitemlist"></a>
### ContentItemList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [ContentItem](#schema-contentitem) | yes |  |
| `total` | integer | yes |  |
| `counts` | object |  | Counts per tab (for example per status) |

<a id="schema-biblelinklist"></a>
### BibleLinkList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [BibleLink](#schema-biblelink) | yes |  |
| `total` | integer | yes |  |

<a id="schema-pathwaylist"></a>
### PathwayList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Pathway](#schema-pathway) | yes |  |
| `total` | integer | yes |  |

<a id="schema-badgelist"></a>
### BadgeList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Badge](#schema-badge) | yes |  |
| `total` | integer | yes |  |

<a id="schema-announcementlist"></a>
### AnnouncementList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Announcement](#schema-announcement) | yes |  |
| `total` | integer | yes |  |

<a id="schema-storylist"></a>
### StoryList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Story](#schema-story) | yes |  |
| `total` | integer | yes |  |

<a id="schema-notificationrulelist"></a>
### NotificationRuleList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [NotificationRule](#schema-notificationrule) | yes |  |
| `total` | integer | yes |  |

<a id="schema-moderationreportlist"></a>
### ModerationReportList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [ModerationReport](#schema-moderationreport) | yes |  |
| `total` | integer | yes |  |
| `counts` | object |  | Counts per tab (for example per status) |

<a id="schema-moderationtestimonylist"></a>
### ModerationTestimonyList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [ModerationTestimony](#schema-moderationtestimony) | yes |  |
| `total` | integer | yes |  |

<a id="schema-moderationpostlist"></a>
### ModerationPostList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [ModerationPost](#schema-moderationpost) | yes |  |
| `total` | integer | yes |  |

<a id="schema-sanctionlist"></a>
### SanctionList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Sanction](#schema-sanction) | yes |  |
| `total` | integer | yes |  |

<a id="schema-guardianconsentlist"></a>
### GuardianConsentList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [GuardianConsent](#schema-guardianconsent) | yes |  |
| `total` | integer | yes |  |

<a id="schema-datarequestlist"></a>
### DataRequestList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [DataRequest](#schema-datarequest) | yes |  |
| `total` | integer | yes |  |

<a id="schema-auditentrylist"></a>
### AuditEntryList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [AuditEntry](#schema-auditentry) | yes |  |
| `total` | integer | yes |  |

<a id="schema-reportschedulelist"></a>
### ReportScheduleList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [ReportSchedule](#schema-reportschedule) | yes |  |
| `total` | integer | yes |  |

<a id="schema-inactivitythreshold"></a>
### InactivityThreshold

| Field | Type | Required | Notes |
|---|---|---|---|
| `days` | integer | yes | ≥ 1, ≤ 365 |

<a id="schema-settingssection"></a>
### SettingsSection

The fields depend on {section}: charter, consents, minors or retention

Type: object \| object \| object \| object

<a id="schema-problem"></a>
### Problem

| Field | Type | Required | Notes |
|---|---|---|---|
| `type` | string |  |  |
| `title` | string |  |  |
| `status` | integer |  |  |
| `code` | string |  |  |
| `detail` | string |  |  |
| `errors` | array of object |  |  |

<a id="schema-ok"></a>
### Ok

| Field | Type | Required | Notes |
|---|---|---|---|
| `ok` | boolean |  |  |

<a id="schema-reminderresult"></a>
### ReminderResult

| Field | Type | Required | Notes |
|---|---|---|---|
| `ok` | boolean | yes |  |
| `emailed` | boolean | yes | false when only a phone number is on file, so nothing could be emailed |

<a id="schema-object"></a>
### Object

Type: object

<a id="schema-list"></a>
### List

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of object |  |  |
| `total` | integer |  |  |
| `counts` | object |  |  |

<a id="schema-role"></a>
### Role

Type: string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`)

<a id="schema-sessionuser"></a>
### SessionUser

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `email` | string |  |  |
| `fullName` | string |  |  |
| `role` | string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`) |  |  |
| `status` | string (`INVITED`, `ACTIVE`, `INACTIVE`, `SUSPENDED`) |  |  |
| `communityId` | string \| null |  | nullable |
| `communityIds` | array of string |  |  |
| `communityName` | string \| null |  | nullable |

<a id="schema-sessionresponse"></a>
### SessionResponse

| Field | Type | Required | Notes |
|---|---|---|---|
| `user` | [SessionUser](#schema-sessionuser) |  |  |

<a id="schema-loginbody"></a>
### LoginBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `email` | string | yes |  |
| `password` | string | yes |  |
| `rememberMe` | boolean |  |  |

<a id="schema-emailbody"></a>
### EmailBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `email` | string · email | yes |  |

<a id="schema-resetbody"></a>
### ResetBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `token` | string | yes |  |
| `password` | string | yes | ≥8 chars, letter + number |

<a id="schema-member"></a>
### Member

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string |  |  |
| `fullName` | string |  |  |
| `username` | string |  |  |
| `email` | string |  |  |
| `phone` | string \| null |  | nullable |
| `birthdate` | string \| null |  | nullable |
| `isMinor` | boolean |  |  |
| `guardianConsentStatus` | string \| null (`PENDING`, `RECEIVED`, `null`) |  | nullable |
| `role` | string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`) |  |  |
| `status` | string (`INVITED`, `ACTIVE`, `INACTIVE`, `SUSPENDED`) |  |  |
| `institutionId` | string |  |  |
| `institutionName` | string |  |  |
| `communityId` | string \| null |  | nullable |
| `communityName` | string \| null |  | nullable |
| `lastActiveAt` | string · date-time |  |  |
| `participation` | object |  |  |

<a id="schema-memberlist"></a>
### MemberList

| Field | Type | Required | Notes |
|---|---|---|---|
| `items` | array of [Member](#schema-member) |  |  |
| `total` | integer |  |  |

<a id="schema-addmember"></a>
### AddMember

| Field | Type | Required | Notes |
|---|---|---|---|
| `fullName` | string | yes |  |
| `email` | string · email | yes |  |
| `phone` | string |  |  |
| `birthdate` | string · date |  |  |
| `role` | string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`) |  |  |
| `institutionId` | string | yes |  |
| `communityId` | string |  |  |
| `guardianConsentReceived` | boolean |  |  |
| `sendInvitation` | boolean |  |  |

<a id="schema-importbody"></a>
### ImportBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `rows` | array of [AddMember](#schema-addmember) | yes | max 2000 items |

<a id="schema-importresult"></a>
### ImportResult

| Field | Type | Required | Notes |
|---|---|---|---|
| `createdCount` | integer |  |  |
| `skippedCount` | integer |  |  |
| `failedRows` | array of object |  |  |

<a id="schema-rolebody"></a>
### RoleBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `role` | string (`STUDENT`, `MENTOR`, `SUPER_MENTOR`, `ALUMNI`, `CONTENT_ADMIN`, `SYSTEM_ADMIN`) | yes |  |

<a id="schema-communityidbody"></a>
### CommunityIdBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `communityId` | string | yes |  |

<a id="schema-reasonbody"></a>
### ReasonBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | string | yes | min 3 chars |

<a id="schema-optreasonbody"></a>
### OptReasonBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | string |  |  |

<a id="schema-idsbody"></a>
### IdsBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `ids` | array of string | yes |  |

<a id="schema-bulkresult"></a>
### BulkResult

| Field | Type | Required | Notes |
|---|---|---|---|
| `approved` | array of string |  |  |
| `skipped` | array of object |  |  |

<a id="schema-institutionbody"></a>
### InstitutionBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `type` | string (`UNIVERSITY`, `HIGH_SCHOOL`) | yes |  |
| `country` | string (`Uganda`, `Kenya`, `Rwanda`) |  |  |
| `city` | string | yes |  |
| `generalCoverUrl` | string |  |  |
| `shownInSignup` | boolean |  |  |

<a id="schema-communitybody"></a>
### CommunityBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `institutionId` | string | yes |  |
| `kind` | string (`GENERAL`, `SPECIFIC`) |  |  |
| `name` | string | yes |  |
| `description` | string |  |  |
| `coverPhotoUrl` | string |  |  |
| `meetingDay` | string |  |  |
| `meetingTime` | string |  |  |
| `meetingPlace` | string |  |  |
| `superMentorId` | string |  |  |
| `mentorIds` | array of string |  |  |
| `openForJoinRequests` | boolean |  |  |
| `status` | string (`ACTIVE`, `CLOSED`) |  |  |

<a id="schema-staffbody"></a>
### StaffBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `fullName` | string | yes |  |
| `email` | string | yes |  |
| `role` | string (`SYSTEM_ADMIN`, `CONTENT_ADMIN`, `SUPER_MENTOR`) | yes |  |
| `communityId` | string |  |  |
| `sendInviteEmail` | boolean |  |  |

<a id="schema-contentbody"></a>
### ContentBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes |  |
| `type` | string (`VIDEO`, `DEVOTIONAL`, `QUIZ`, `DOCUMENT`) | yes |  |
| `bibleLink` | string | yes | id from /bible-links |
| `language` | string |  |  |
| `tags` | array of string |  |  |
| `description` | string |  |  |
| `validatorName` | string |  |  |
| `pathwayIds` | array of string |  |  |
| `body` | string |  |  |
| `videoUrl` | string |  |  |
| `thumbnailUrl` | string |  |  |
| `documentUrl` | string |  |  |
| `submitForReview` | boolean |  |  |

<a id="schema-transitionbody"></a>
### TransitionBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string (`SUBMIT_FOR_REVIEW`, `APPROVE_AND_PUBLISH`, `REQUEST_CHANGES`, `ARCHIVE`, `RESTORE_TO_DRAFT`) | yes |  |
| `notes` | string |  |  |

<a id="schema-pathwaybody"></a>
### PathwayBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `theme` | string | yes |  |
| `level` | string (`Beginner`, `Intermediate`, `Advanced`) |  |  |
| `description` | string |  |  |
| `unlockRule` | string (`none`, `previous_pathway`, `profile_complete`, `mentor_assigned`) |  |  |
| `badgeAwardedId` | string \| null |  | nullable |
| `published` | boolean |  |  |
| `steps` | array of object | yes |  |

<a id="schema-badgebody"></a>
### BadgeBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | yes |  |
| `description` | string | yes |  |
| `ruleType` | string (`join_community`, `finish_quizzes`, `pray_requests`, `complete_pathway`, `attend_meetings_streak`) | yes |  |
| `ruleTargetCount` | integer | yes | ≥ 1, ≤ 1000 |
| `icon` | string |  |  |
| `visibleOnProfile` | boolean |  |  |
| `status` | string (`active`, `draft`, `archived`) |  |  |

<a id="schema-announcementbody"></a>
### AnnouncementBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes |  |
| `message` | string | yes |  |
| `audienceType` | string (`all`, `community`) | yes |  |
| `communityId` | string |  |  |
| `imageUrl` | string |  |  |
| `publishTiming` | string (`now`, `scheduled`) |  |  |
| `scheduledFor` | string · date-time |  |  |

<a id="schema-storybody"></a>
### StoryBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `studentName` | string | yes |  |
| `institution` | string | yes |  |
| `videoUrl` | string | yes |  |
| `duration` | string | yes |  |
| `consentObtained` | boolean | yes |  |

<a id="schema-reorderbody"></a>
### ReorderBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `stories` | array of object | yes |  |

<a id="schema-actionbody"></a>
### ActionBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string | yes | Reports: DISMISS\|WARN\|HIDE\|ESCALATE\|SUSPEND\|DELETE. Posts: KEEP\|HIDE\|WARN_AUTHOR\|ESCALATE |
| `notes` | string | yes | min 3 chars |

<a id="schema-testimonyreviewbody"></a>
### TestimonyReviewBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `action` | string (`APPROVE`, `REQUEST_CHANGES`, `REJECT`) | yes |  |
| `notes` | string |  |  |

<a id="schema-schedulebody"></a>
### ScheduleBody

| Field | Type | Required | Notes |
|---|---|---|---|
| `reportType` | string (`discipleship_summary`, `community_health`, `content_completions`) | yes |  |
| `cadence` | string (`weekly`, `monthly`, `quarterly`) | yes |  |
| `recipientEmail` | string · email | yes |  |
