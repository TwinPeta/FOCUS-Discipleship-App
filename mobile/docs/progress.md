# Prompt 3 (screens 43-61) progress
Brief: `docs/fcu_prompt_3_screens_43_61.md`. Owners and claims: `docs/collaboration.md`. Each agent ticks only its own lines.

## Agent A
- [x] 44 Notifications (`/notifications`): New (with Mark all as read) and Earlier sections; icon tile, time ("Today · 9:15", "Yesterday", "Mon"), unread dot; tap marks read and opens `targetRoute`; empty state; the hub bell dot reads the repository
- [x] 45 Notification settings (`/notifications/settings`): In-app and Email channels; 6 categories (inactivity off by default); saved through `NotificationRepository`; muting stops records from being created
- [x] 61 Moderator warning (`/warning/:id`, full screen): reason, hidden-content preview, "I understand" (acknowledges, then continues), "Read the charter"; unacknowledged-warning guard
- [x] 60 Account suspended (`/suspended`, full screen): reason and end date, "Read the charter", "Sign out"; suspended guard first in the chain, releases on its own when `until` passes
- [x] Final guard chain: suspended -> unacknowledged warning -> signed out -> onboarding incomplete -> membership (tests in `test/moderation/enforcement_test.dart`)
- [x] 51 Meetings (`/community/:id/meetings`): Next meeting (day, time, room) with "I am going" (RSVP toggle) and "Add to calendar" (stub); "At the meeting?" with "I am here" only inside the check-in window, once per meeting, recorded as an `ActivityEvent` (badges go to screen 38); Past meetings with Attended / Missed; back goes to Info
- [x] 57 Loading / 59 Error audit: every async screen now shows `Skeleton` while loading and `ErrorView` / `ErrorScreen` with Try again on failure. Fixed: community shell, hub (whole page and communities list), community detail, Info & members, Resources, and the My activity badges row. Already compliant: feeds, prayer wall, testimonies, pathways, viewers 33-38, 30-32, 44, 45, 51, 60, 61, post detail
- [x] 56 Offline: `OfflineBanner` (in both shells) now carries the tip "Turn on Data saver to use less data on slow connections."; the last feed and prayer wall are cached in memory (`OfflineCache`) and marked "Saved"; composer row, New post button, "Share a request" and "I prayed" are disabled (faded, labelled), not hidden. Debug scenario "Go offline" already exists. Tests: `test/core/offline_test.dart`
- [x] 56/57/59 for messaging (done by Agent B): inbox and Conversation use `Skeleton` + `ErrorView` (Try again re-runs the call) and show `OfflineBanner`; offline, the Conversation field and send stay visible but are disabled ("You are offline"); earlier messages stay readable. Test: `test/messaging/messaging_states_test.dart`

## Agent B
- [x] Content reports to moderation queue (`fileReport`; reviewed by A; reporter id now required)
- [x] 43 Member profile (`/members/:id`): header message button, avatar, @username, role badge + Verified for mentors/super-mentors, About, institution and community chips, earned badges only; Message (respects `canMessage`), Report (user `ReportFlow`), Block (confirm, pop, Undo). Own profile: no Message/Report/Block. A blocked member's profile shows "You blocked this person" + Unblock
- [x] 54 New message (`/messages/new`): search, "Your mentors" and "Members of {community}"; tap opens or creates the thread (replaces this page); blocked people excluded by the repository; rows failing `canMessage` are disabled with the note. The old bottom sheet is deleted
- [x] 55 Blocked users (`/settings/blocked`): rows with Unblock, empty state
- [x] 58 No messages yet: the empty inbox, **Find a member** -> `/messages/new`
- [x] 52 Prayer request (`/prayer/:id`, built by A): author or Anonymous, time and community, body, "I prayed" (reuses the wall's once-only logic, "N people prayed"), Responses, pinned "Write an encouraging response" + send
- [x] 53 Testimony (`/testimony/:id`, built by A): Reviewed badge, title, "name · university", full text, Encouraged toggle, outlined Report (ReportFlow, target testimony); pending stories open only for their author
- [x] Batch 6 link and Back walk (started early): `test/navigation/link_walk_test.dart` walks 36 legs (deep link + pushed) with no dead ends; fixed a deep-link crash under `/messages/:id/report`, composer/form pop on an empty stack (`popOr`), and deep-link Back targets (`AmberHeaderScaffold.backFallback`). Findings for Agent A: `docs/link_walk.md`
- [x] 46 Settings (`/settings`, built by A): profile card -> Edit profile; Edit profile, Notifications, Language (English, nothing to open), Privacy & data, Help & FAQ; Sign out (confirm -> `/login`); "Version 1.0" (long-press opens `/debug` in debug builds)
- [x] 47 Edit profile (`/settings/profile`, built by A): photo + Change photo, full name, username (uniqueness check on blur and on save), phone, the Join form's institution picker; read-only email line; Save disabled until changed and valid. `/profile/edit` now redirects here
- [x] 50 Help & FAQ (`/help`, public, built by A): accordion with the first answer open; "Copy support email" (clipboard, no url_launcher)
- [x] 48 Privacy & data (`/settings/privacy`, built by A): Download my data (fake export, "We will email you a copy"), My activity & badges, Blocked users, retention note, destructive "Delete my account"
- [x] 49 Delete account (bottom sheet, built by A): 30-day and "cannot be undone" copy, password confirm; Keep my account; Delete disabled until a password, wrong password shows an inline error; success deletes account, profile and membership, ends the session -> `/login`
- [x] `docs/wiring.md` has no rows left and no placeholder routes remain. `PlaceholderScreen` itself stays until Agent B's Batch 6 link walk (which still references it) is updated; then delete it

## Prompt 3 assumptions
- After phone testing (2026-11-15): bottom navigation Home (General feed) | Community (your community's feed, or the hub if none) | Profile on the four top-level screens (`core/widgets/app_bottom_nav.dart`, uses `go`). Typed text was invisible because `AppTheme` used an empty `TextTheme()`; fixed with a regression test.
- Uploads (`core/media/upload_policy.dart`): text, emojis and photos only. Photos: JPG/PNG/WebP/HEIC, compressed to quality 80 and at most 1600px, refused above 2 MB with a message; every picker uses `pickPhoto`. Video and document attaching are removed from the composer and Share a testimony. Text limits: posts and long forms 2000 characters, messages, comments and responses 1000. `file_picker` is now unused in code but still in pubspec (remove when convenient). Note: image_picker's quality setting re-encodes JPEGs; PNG/WebP rely on the 1600px resize plus the 2 MB check.
- Delete account (49): `AuthRepository.deleteAccount(password)` checks the password against the signed-in account (generic `InvalidCredentials`, nothing deleted on failure). `AccountDeletion` then deletes the profile, clears the membership (best effort) and signs out. In the fake, other stores (posts, messages, activity) live in memory only; a real backend deletes them server-side within `deletionWindowDays` (30). Deleting is disabled offline.
- Retention period (`dataRetentionMonths` = 24) and the deletion window are constants in `settings/data/privacy_repository.dart`. "Download my data" goes through `PrivacyRepository.requestDataExport` (fake records the request).
- Support email is a placeholder (`supportEmail` in `core/config/app_info.dart`); confirm the real address. The version shown is the constant `appVersion` (keep it in step with pubspec; no package_info).
- The Join form's "I study at" toggle and institution list became the shared `InstitutionPicker` (`profile/presentation/widgets/`), used by Join (2) and Edit profile (47). Country isn't editable on Edit profile, so it lists that country's institutions.
- `SettingsRow` (icon tile, title, subtitle, chevron) is shared by Settings (46) and Privacy & data (48).
- FAQ answers 2-4 are written by A (the brief gave only the first); review the wording.
- Prayer anonymity (52): `PrayerRepository.createRequest(ownerId:)` keeps the real owner **inside the repository only** (`_ownerOf`); `PrayerRequest` and `PrayerResponse` drop author fields when anonymous. The anonymous owner's own replies are stored as "Anonymous". Response notifications go to the owner by id and never name anyone. New responses appear only once stored (no optimistic row), so the owner's name never shows even briefly.
- 52/53 deep links work before the wall or testimonies tab was opened (seeds are built from the id prefix). A missing or hidden item shows an "not available" empty state.
- 53 "full text" is `Testimony.excerpt` (the list truncates it). `Testimony` gained `encouragedCount` / `encouragedByMe`; "Encouraged" is one per member. The Report button is hidden on your own story.
- Offline cache is in-memory and keyed per list (`feed:<community>:<scope>`, `prayer:<community>`). Offline, a list is served from it (no paging); with nothing cached the call still runs, which a real backend would fail into `ErrorView`. The "Saved" marker appears only offline, so online layout and goldens are unchanged.
- `PillButton` and `TabSectionHeader` now show a faded, semantically disabled state when their callback is null (previously a null callback looked enabled).
- Offline write paths not reachable from a disabled entry point (New prayer request and Share testimony forms) are left as they were; their entry buttons are the gate. Comment input (post detail) was already offline-aware.
- Meetings are generated weekly from the community's `meetingDay` / `meetingTime` / `room` (e.g. "Every Tuesday", "5:00 PM"). A meeting stays "next" until its check-in window closes, then the next week's takes over. The fake seeds the 3 earlier weeks as attended, missed, attended. Only RSVPs and check-ins are stored (`MeetingRepository`, ids `communityId@yyyy-mm-dd`).
- Check-in window: 30 minutes before the start to 2 hours after (`CheckInWindow`, configurable; the screen reads the repository's window). The clock is injected (`meetingClockProvider`) and the screen re-checks it every minute. The repository rejects check-ins outside the window and repeat check-ins (including a double tap in flight).
- "Add to calendar" is a stub snackbar (no calendar package without approval). RSVP and check-in are disabled offline.
- When a check-in earns a badge, Badge earned (38) is the only confirmation; otherwise a snackbar says "You are checked in".
- Shared `formatLongDate` ("21 November 2026") moved to `core/utils/date_utils.dart`. The test harness `pumpFcuApp` gained an optional `overrides` list.
- A suspended account may still open `/charter` and `/help` (the screen says to read the charter or write to support); everything else redirects to `/suspended`. Once the suspension ends, `/suspended` sends the account to the hub. The router schedules a timer for `until`, so the release needs no app restart; the guard clock is injectable (`guardClockProvider`).
- While a warning is unacknowledged, only `/warning/:id` and `/charter` are reachable. The oldest pending warning is shown first. An acknowledged warning can still be opened from its notification ("Continue" instead of "I understand").
- Warnings and suspensions apply only to signed-in accounts. They do not hold routes on `/loading` (that interfered with router refresh), so the app can show for about 300ms before the guard redirects. A real backend would return both with the session.
- Suspensions are set by admins only: `SuspensionRepository` is read-only, with a debug hook (`debugSuspend`). Debug scenarios: "Receive a moderator warning" and "Suspend my account (7 days)".
- Notification taps are data-driven: each producer sets `targetRoute`. Approved/declined -> `/request/approved|declined`; prayer -> `/prayer/:id`; announcement and inactivity -> `/general-feed`; meeting -> `/community/:id/meetings`; comment reply -> `/post/:id`; moderator warning -> `/warning/:id` (placeholder until 61).
- New types `commentReply` and `prayerResponse`. Categories: join request updates (approved, declined), replies, prayer responses (prayed for you, prayer response), announcements, meeting reminders, inactivity. **Moderator warnings belong to no category and cannot be muted**; they are recorded even with in-app off, for safety.
- `add()` returns null and records nothing when the recipient muted the category or turned in-app off. Email still goes out when in-app is off but email is on. Preferences are stored per recipient (null = the signed-in user).
- Delivery channels are `NotificationChannel` implementations (`FakeEmailChannel` records "sent" emails). Push = one more `DeliveryChannel` value plus a channel class; nothing else changes.
- Sections: "New" = unread, "Earlier" = read. "Mark all as read" sits on the New header.
- New shared widget `SwitchRow` (`core/widgets/switch_row.dart`): an amber switch where the whole row is the target. Agent B can reuse it for Settings (46).
- (B) Blocking lives in the repositories now: `ModerationRepository.isBlocked` (sync) is injected like `isHidden` into posts (+ comments), prayer requests, testimonies, messaging and member rosters. Threads with a blocked person are hidden, `getThreadById` returns null, and open/send throw `PersonBlocked`. You cannot block yourself. Provider-level filters stay so lists refresh when the block list changes. Anonymous prayer requests have no author id, so blocking cannot hide them.
- (B) `MemberRepository` / `MemberProfile`: a fake directory keyed by the ids the other fakes use (bio, username, community name, earned badge ids). Institution is not stored per member: profiles show the viewer's institution (members of your communities are on your campus). Unknown ids show "Member not available". Your own profile is built from your account and your own earned badges.
- (B) Seed names aligned with the community roster: comment authors `member-2` = Peter Ssentongo and `member-3` = Joy Atim; seeded testimonies now carry author ids (`student-2`, `m-1`). Agent A's moderation seed calls `member-4` "Ivan Kasozi"; the roster says Isaac Wandera.
- (B) The user report from a profile uses the shared content route (`/report/user/:id`): "Report a user" / "What happened?"; the sent page offers **Back to profile** and **Block this user**. User reports never enter the community moderation queue.
- (B) Shared widgets: `SearchField` (moved from the hub's `CommunitySearchField`, now takes `hintText`; hub, inbox and New message use it), `openConversation` (the one way to open a thread; handles `MessagingRestricted` and `PersonBlocked`), `confirmAndBlock` (confirm, block, Undo snackbar). `kBadgeCatalog` is the one badge list.
- (B) `/settings/blocked` is reachable by route and from 48 Privacy / 46 Settings once those land (Agent B, next).

# Prompt 2 (screens 21-42) progress
Brief: `docs/fcu_prompt_2_screens_21_42.md`. Ledger: `docs/wiring.md` (clear every "resolved in 2" row).
- [x] Shared widgets: BottomSheetScaffold, CelebrationScreen, OtpField, PasswordField, ConfirmDialog (+ OnboardingScaffold); ReportFlow lands with batch 4
- [x] Batch 1: AuthRepository/session, SignUpController, 21 password, 22 verify (OTP), 23 consent, 24 guardian, 25 sign in, 26 forgot password, `/charter`; signed-out + onboarding guards; under-18 `canMessage` in MessageRepository; Join form stops creating the account
- [x] Batch 2: 27 approved, 28 declined (shown once, `seen`), 29 leave sheet; NotificationRepository + hub bell dot; debug "Approve/Decline my request", "Guardian confirms"; pending-hub debug link removed
- [x] Batch 3: 33 video (PlaybackController fake), 34 devotional (+reflection), 35 quiz, 36 result, 37 document, 38 badge earned (queue); completion -> activity + pathway step + badges; debug "mark step complete"/"attended meeting" removed
- [x] Batch 4: 39 post & comments, 40 post options sheet, 41/42 ReportFlow (post skin); user report 11/12 refactored onto ReportFlow; comments/prayer/testimony reports reuse it
- [x] Batch 5: 30 manage, 31 join requests, 32 reports to review (Hide/Warn/Keep/Escalate); super-mentor guard + repository role checks
  - [x] 30 Manage (`/community/:id/manage`): live counters for join requests, open reports and members to follow up; follow-up sheet with a Message button per member; Meeting details links to `/community/:id/meetings` (placeholder until 51); tests in `test/community/manage_community_test.dart`
  - [x] 31 Join requests (`/community/:id/manage/requests`): `JoinRequest` + `JoinRequestRepository` (role-checked), approve/decline notify the student, "Already in" disables Approve; tests in `test/community/join_requests_test.dart`
  - [x] 32 Reports to review (`/community/:id/manage/reports`): `ModerationCase`, `Warning`, role-checked `ModerationQueueRepository` (Hide / Warn author / Keep / Escalate to admin, each records an outcome and leaves the queue), `WarningRepository`, hidden content filtered in the post and prayer repositories; tests in `test/moderation/reports_to_review_test.dart`
- [ ] Finish: analyze 0, tests green, wiring rows for prompt 2 cleared, assumptions + stubs recorded

## Prompt 2 assumptions
- Screen 30 "Members to follow up": `ActivityRepository.lastActiveByMember` (super-mentor only) returns **only** each member's last-activity timestamp, never their events, so activity history stays private. Leaders are excluded; members never active count as quiet. The 14-day threshold is `followUpInactivity`, and the clock is injectable (`manageClockProvider`). The list opens in a bottom sheet, with `MessagePersonButton` (extracted from Info & members) on each row.
- Screen 30 "Meeting details" reads the community's day/time/room ("Every Tuesday" shows as "Tuesday") and links to Meetings (51). The two debug shortcuts to 31 and 32 are removed; "Use the super-mentor test account" stays.
- Screen 31 lives at `/community/:id/manage/requests` (the existing manage guard covers it). Reached from the Manage card (screen 30).
- The join-request queue is a seeded fake for Growth Circle (4 students, one already in Life & Faith Circle); it is separate from the signed-in user's own `Membership`, whose approval stays on the "Approve my request" debug scenario.
- Student notifications carry `recipientId`; `getNotifications()` returns only the signed-in user's (recipientId null), `getNotificationsFor(id)` returns another user's. A backend would push these to that student.
- Screen 32 lives at `/community/:id/manage/reports`; reached from the Manage card (screen 30). The queue is seeded for Growth Circle (a comment, a post and a prayer request). Batch 4's `ReportFlow` for content will feed new cases into it; today `ReportRepository` submissions do not create cases.
- **Warn author also hides the content** (screen 61 says "This message was hidden"), creates `Warning(reason, preview, acknowledged:false)` and a `moderatorWarning` notification for the author targeting `/warning/:id` (screen 61, prompt 3). Warn asks for confirmation; Hide, Keep and Escalate act immediately.
- Hidden content is enforced in `FakePostRepository`/`FakePrayerRepository` via an injected `isHidden` check (from `ModerationQueueRepository`), so it disappears for everyone. Comments don't exist yet (batch 4); their ids are recorded as hidden for when they do.
- Escalate sets the case to level 2 and puts it in a fake admin queue (`getAdminQueue`). `NotSuperMentor` moved to `user_role.dart`, shared by screens 31 and 32.
- Approve/decline are idempotent-safe: a second call while one is in flight, or on a decided request, throws `JoinRequestNotPending`. Decline uses the shared `showTextInputDialog`; a blank message is stored as none. Actions are disabled offline.
- Session is in memory only (no secure storage). Passwords never enter app state: `SignUpController` keeps `fakePasswordDigest` (iterated FNV, explicitly fake; a real backend hashes server-side).
- Debug demo account: `demo@fcu.test` / `Password1234` (seeded profile "Demo Student"). Fake email code: `123456` (shown on screen in debug builds).
- Profiles are keyed by account id (`UserProfile.id == AuthSession.accountId`); `ProfileRepository.getProfile(accountId)` replaced `getCurrentProfile()`.
- Join form validates and checks username + email availability, then stores the answers in the sign-up draft; the account + profile are created on "Join my campus". Back preserves the draft.
- Guards: signed-out sends protected routes to `/`; onboarding enforces step order (details -> password -> verified -> consent), sends a signed-in account without a profile to `/join`, and sends a complete account away from sign-up/sign-in pages. `/join/guardian` needs a session.
- Under-18 limit (flag `kUnder18MessagingLimit`): enforced in `FakeMessagingRepository` (`canMessage`, open/send throw `MessagingRestricted`). "Adult" = mentors, super-mentors, and members unless `Person.isAdult: false`; minors may message other minors. Until the guardian status loads, a minor is treated as restricted.
- The guardian step's Back goes to the hub (the account already exists); the restriction stays until a guardian confirms ("Guardian confirms" debug scenario).
- Relationship options: Parent, Legal guardian, Other relative.
- `LabeledDropdown` moved to `core/widgets` (second consumer).
- Charter text is placeholder copy (`/charter`, public, reused by prompt 3).
- "Declined" keeps the internal status `rejected`; `Membership` gained `message` (decline note) and `resultSeen`. Approve/decline set `resultSeen=false`; screens 27/28 mark it seen when shown.
- The one-time result opens from the hub the first time it sees an unseen result (covers "next app open"); the notification's `targetRoute` and the debug scenarios open the same screens.
- "Choose another community" acknowledges the decline (rejected -> none) before going to the hub; "Go to my campus" leaves the status untouched (the hub treats rejected like none).
- Leave is `MembershipRepository.leave()` (approved -> none only); the guard then redirects community routes.
- Notifications: `FakeNotificationRepository` records synchronously; membership approve/decline emit at the source. "Prayed for you", announcement, meeting reminder and inactivity come from debug scenarios for now; moderator warnings arrive with batch 5. The bell dot is ink with a white ring; its label carries the unread count.
- Batch 3: viewers take `?pathway=&community=` (`learningRoute`); content ids are the resource or pathway-step id. Content bodies are placeholders generated by `FakeLearningRepository`.
- Completion goes through `LearningActions`: records the activity, advances the pathway step only if it is the current one, queues badges (`BadgeQueue`) for screen 38. Opening a video no longer counts as watched; "Mark as complete" does. New activity types `devotionalRead`, `documentRead`.
- Quiz is scored in the repository; pass mark 70% (`Quiz.passMark`); a failed quiz is not completed. Review mode is `/quiz/:id/review`.
- Prayer-wall badges also open screen 38 (snackbar removed). The "Record meeting attended" debug *scenario* stays in the registry; the on-screen shortcut is gone. Testimony video cards are unchanged (testimony detail is prompt 3).
- Viewers are not membership-gated (Resources content is campus-wide in the fake).
- "Download" on the document viewer is a stub snackbar; no PDF or video package added.
- Batch 4 / 39: `PostRepository` gained `getPost`, `getComments`, `addComment`; `Post.commentCount` is derived from stored comments. Seeded posts ending in `-post-1`/`-post-photo` start with two comments. `getPost` only finds posts in a feed that has loaded at least once (fake seeds lazily); otherwise the screen shows "Post not available".
- Likes and comments on the post screen are optimistic and copied into the loaded feed (`FeedPostsController.replacePost`). Feed "Comment" now opens `/post/:id` and shows the count. A blocked author's post shows "Post not available"; blocked commenters are filtered in the provider.
- Offline: like and the comment field are disabled (not hidden) and the hint reads "You are offline".
- `MessageInputBar` extracted to `core/widgets` (conversation + comments); `PostActionButton` made public; `postPhotoView` shared by feed and post screen.
- 40: `showPostOptionsSheet` (`BottomSheetScaffold` + new `BottomSheetAction` row). Authors see **Delete post** and do not see **Report post** (reporting yourself is meaningless). Hide is per-user (`PostRepository.hidePost/unhidePost`, filtered out of `getPosts`/`getPost`), optimistic, Undo in the snackbar. Delete is checked in the repository (`PostPermissionDenied` for non-authors) and removes the post's comments. From the post screen, Hide/Delete close the screen. Copy link copies `https://fcu.app/post/{id}` (placeholder).
- 41/42: `ReportFlow` + `ReportReasonRow` + `ReportSentView` (on `CelebrationScreen`) in `messaging/presentation/report_flow.dart` (it depends on the `Report` domain, so it lives with it, not in `core/widgets`). Screens 11/12 are now thin wrappers (screenshot card + Block). Content reports use one route, `/report/:type/:id?user=&name=&back=` (`contentReportLocation`), `type` = post | comment | prayer | testimony; `back` only accepts in-app paths. **Hide this post** on 42 shows only for posts.
- `Report.targetUserId` is now nullable: anonymous prayer requests never expose the author to the client, so moderation resolves it from `targetId`. Added `ReportTargetType.testimony`.
- Report entry points: a 44px flag (`ReportIconButton`) on comments, prayer cards and story testimony cards, hidden on the user's own content (own anonymous prayers cannot be recognised, so they still show it). Video testimony cards have none until testimony detail (prompt 3).
- Content reports feed moderation (Agent B): `FakeReportRepository` forwards every community-content report (post, comment, prayer request, testimony, with a `communityId`) to `ModerationQueueRepository.fileReport`. It opens a level 1 case or appends to the target's open case: +1 per distinct reporter, the reason becomes the most common one, a repeat by the same reporter or a concurrent double submit counts once, and reporting your own content is refused. User/conversation reports stay out of the community queue.
- `Report` gained `communityId`, `targetUserName`, `preview` (at most 160 chars, carried in the report route), `reporterId`, `reporterName`. A real backend would resolve the preview and author from `targetId` itself.
- Shared with Agent A (for review): `ModeratedContent.testimony`; `ModerationCase.authorId` is nullable (anonymous prayers show "Anonymous"); `canWarn` is false then, `warnAuthor` throws `ModerationAuthorUnknown`, and screen 32 shows a disabled "Author unknown" button instead of "Warn author". Hidden testimonies are filtered in `FakeTestimonyRepository` (`isHidden`), and screen 32 refreshes the testimonies list after Hide/Warn.
- General-community posts are filed with their `general-...` community id; no super-mentor reviews that queue yet (campus team/admin, later).
- "Say hello to my mentor" opens or creates the super-mentor thread; when the under-18 limit applies the button is disabled and reads "Waiting for your guardian's confirmation".

---

# Prompt 1 (audit + small changes) progress
Brief: `docs/fcu_prompt_1_audit_and_small_changes.md`. Findings: `docs/audit.md`. Wiring ledger: `docs/wiring.md`.
- [x] Phase A: audit written (4 P0 / 32 P1 / 17 P2), waiting for "go" plus answers to the questions
- [x] Phase B: P0 fixes (P0-1..4) with tests
- [x] Phase B: P1 fixes (all 32)
- [x] Phase B: foundations (Skeleton, ErrorView, EmptyState, OfflineBanner + ConnectivityService, roles + guard chain, debug registry, PlaceholderScreen + wiring ledger)
- [x] Phase B: cheap P2s (see audit.md outcome for the remainder)
- [x] Phase C: small changes table plus the seeded photo post and the super-mentor switch (docs/wiring.md)
- [x] Phase D: analyze 0, format clean, 90 tests; layout matrix 3 sizes x 3 scales + keyboard; goldens 1-5. Not done: profile-mode scroll on a device

---

# FCU next-15-screens progress

Source brief: `prompts/fcu_flutter_next15_prompt.md`. Tick items as completed; use this file to resume instead of re-reading the brief.

## Shared building blocks (core/widgets)
- [x] `CommunityShell` (amber header + tabs, StatefulShellRoute) — refactored `CommunityFeedScreen` onto it
- [x] `GeneralShell` (amber header, no tabs, scope switch)
- [x] `AmberHeaderScaffold` (amber header, back, title/subtitle, body slot, pinned bottom action)
- [x] `AppSecondaryButton` (white, 2px ink border)
- [x] `FilterChips`
- [x] `RoleBadge`
- [x] `PostCard` → moved to core/widgets, takes primitive props (not a `Post`), optional role badge/action row/media
- [x] `ListRowCard`
- [x] `AppTextArea`
- [x] `CheckRow`
- [x] `AvatarWithPresence`

## Routes / guards
- [x] Guard mechanism: `RequireApprovedMembership` / `RequireProfile` wrapper widgets in `core/widgets/route_guards.dart` (not `GoRouter.redirect` — see assumptions)
- [x] `StatefulShellRoute` for `/community/:id/{feed,prayer,testimonies,pathways,resources,info}`
- [x] Route table skeleton for all new routes (ComingSoon placeholders until each batch lands)
- [ ] Back-stack rules: forms removed from stack after submit; back buttons pop correctly (verify per-screen as each is built)

## Batch A — Feed completion (8, 13)
- [x] Screen 8: General feed (GeneralShell, composer row, promo card, posts, FAB)
- [x] Screen 13: Composer (text + media + emoji panel, PostRepository create)

## Batch B — Community tabs (6, 7, 14, 15)
- [x] Screen 6: Info & members
- [x] Screen 7: Resources
- [x] Screen 14: Prayer wall
- [x] Screen 15: New prayer request

## Batch C — Testimonies and Pathways (16, 17, 18, 19)
- [x] Screen 16: Testimonies
- [x] Screen 17: Share a testimony
- [x] Screen 18: Pathways
- [x] Screen 19: Pathway steps (debug-only "mark step complete" per brief)

## Batch D — Messaging and reporting (9, 10, 11, 12)
- [x] Screen 9: Messages inbox
- [x] Screen 10: Conversation
- [x] Screen 11: Report a user
- [x] Screen 12: Report sent
- [x] Wired Info & Members "message" button to real thread open/create (was a Batch B stub)

## Batch E — Activity and badges (20), wiring
- [x] Screen 20: My activity (badges row, recent activity, debug "attended meeting")
- [x] ActivityRepository + badge rules wired into: video open (Resources + Testimonies video cards, Pathway step "Continue" for video steps), quiz/step complete (Pathway "mark step complete"), "I prayed" (Prayer wall), debug "attended meeting" (My activity)
- [x] Wiring checklist: Info member message → thread ✓; all 6 community tabs ✓; Profile "My activity & badges" → /activity ✓; Messages button present in both CommunityShell and GeneralShell (shared `CommunityHeaderChrome`) ✓; report button from a conversation → /messages/:id/report ✓

## Data models to add
- [x] All models added (Post, PrayerRequest, Testimony, Pathway/PathwayStep, Resource, Thread/Message, Report, AppBadge, ActivityEvent)

## Repositories to add
- [x] `PrayerRepository`
- [x] `TestimonyRepository`
- [x] `PathwayRepository`
- [x] `ResourceRepository`
- [x] `ThreadRepository` / `MessageRepository` (one `FakeMessagingRepository` backs both, shares state)
- [x] `ReportRepository`
- [x] `ModerationRepository`
- [x] `ActivityRepository`
- [x] No separate `BadgeRepository` — badges are derived/returned by `ActivityRepository.record()` and fetched via `getBadges()`; a dedicated model-only repo would've had nothing to do that `ActivityRepository` doesn't already own (see assumptions)

## Quality bar
- [x] `flutter analyze` clean (checked after every batch, 0 issues as of the final pass)
- [x] `flutter test` green — 27 tests (checked after every batch)
- [x] Tests: prayer once-only+count, anonymous no author (`test/prayer/prayer_rules_test.dart`)
- [x] Tests: testimony pending→banner (`test/testimony/testimony_rules_test.dart`), pathway sequence/unlock (`test/pathways/pathway_rules_test.dart`)
- [x] Tests: conversation send+unread clear, report requires reason, block hides thread (`test/messaging/`)
- [x] Tests: badge rules (`test/activity/badge_rules_test.dart`)
- [x] Privacy enforced in data layer: anonymous prayers (`FakeMessagingRepository`/`PrayerRequest` constructor assert), blocked users (`threadsProvider` filter), private activity (never queried/shown outside My activity — no repository exposes another user's events/badges)
- [x] Accessibility/robustness pass: semantic labels on every icon-only button; long names/titles get `maxLines`+ellipsis (thread rows, pathway rows, post authors); AppTextArea fixed to grow (not overflow) under 1.3x-scaled text since it no longer hard-pins a height; most targets ≥44px except `FilterChips` (40px, per the brief's own spec for that widget)

## Assumptions log
- Route guards are per-screen wrapper widgets (`RequireApprovedMembership`, `RequireProfile`) reading Riverpod providers, not `GoRouter.redirect` — simplest option consistent with the existing ad-hoc per-screen check pattern; wiring Riverpod async state into go_router's redirect/refreshListenable would need a global `ProviderContainer` the app doesn't otherwise use.
- `Post` carries an explicit nullable `roleLabel` (badge text) independent of `Person.role`, since the general feed's "Campus team"/"Student" badges aren't values of `PersonRole`. Posts with no `roleLabel` also hide the like/comment row.
- `PostCard` takes primitive props rather than a `Post`, so `core/widgets` doesn't depend on a feature's domain model.
- Online/presence counts are a deterministic placeholder (`estimateOnlineCount`), since no real presence data model exists.
- Added `file_picker` dependency (user-approved) for document attachments in the composer/resources.
- This machine's `C:` drive is nearly full; `flutter pub get`/`analyze`/`test` in this repo must run with `PUB_CACHE=F:/.pub-cache` or package downloads fail.
- `StatefulShellBranch`'s default route can't own a path parameter, so `/community/:id` is now a parent `GoRoute` (redirects bare `/community/:id` to `.../feed`) with the `StatefulShellRoute` nested under it and branch paths relative (`feed`, `prayer`, ...).
- Composer media attachments are stored as local file paths only (no upload); the "Post" button is disabled until text or at least one attachment is present.
- `Person` gained an optional `online` flag (default false) for the Info & Members "online now" roster — small, non-breaking addition to an existing model rather than a new one.
- `CommunityRepository.getMembers(communityId)` added (leadership + a few fake extra members) since no full roster existed before.
- The Info & Members "message" button and Prayer wall's "Respond" button are stubs (snackbar) for now — real thread creation/open wires up once Batch D's `ThreadRepository` exists; tracked in the Batch E wiring checklist.
- `PrayerRequest` adds `authorName` (nullable, alongside `authorId`) beyond the brief's field list, so the UI has a display name without a separate lookup; both are null together when `anonymous` is true (enforced by a constructor assert).
- `Testimony` and `Pathway` both add a `communityId`/extra progress field beyond the brief's literal field list (`communityId` on Testimony for per-community storage like Post/PrayerRequest; `currentStepIndex` on Pathway for the "Step N of total" card) — consistent extensions, not new models.
- Testimony privacy (others never see a pending story) is enforced in `FakeTestimonyRepository.getTestimonies` itself (filters to `reviewed || isMine`), not just in the UI.
- "Share a testimony"'s attached photo/video filenames are shown for UX but not persisted — `Testimony` has no media fields per the brief, and there's no backend to store files against.
- Pathway "locked" is a derived state (`unlocksAfterPathwayId` + prerequisite's `status`), not a stored enum value, so changing the unlock graph only means changing `unlocksAfterPathwayId` as the brief asked.
- Pathway-complete badge award (Batch E) and video/quiz-open activity recording aren't wired yet — `ActivityRepository` doesn't exist until Batch E; the debug "mark step complete" action and stub viewer snackbars are in place to hook into later.
- `Report` has no `id` field (brief's literal field list); it's a one-off submit-and-done action, not something re-fetched later.
- Thread-hiding for blocked users is enforced in `threadsProvider` (provider/data layer), not the UI — filters out any thread whose participant is in `ModerationRepository.getBlockedUserIds()`.
- Found and fixed a real layout bug while writing the Report-screen test: `AppTextArea` used `expands: true`, which needs a bounded-height parent and throws "infinite size during layout" inside the `SingleChildScrollView`s it's actually used in (New prayer request, Share a testimony, Report details). Fixed to a plain growing `maxLines: null` field with a `minHeight` floor — this is why a widget test (not just `flutter analyze`) matters for anything using this widget.
- `Badge` was renamed to `AppBadge` in code (the model is still "Badge" conceptually/in the UI) — Flutter's own `material.dart` exports a `Badge` widget, and this app's screens already import `material_ui` (which re-exports Flutter material), so the brief's literal class name would collide on every screen that needs both.
- No separate `BadgeRepository`: `ActivityRepository.record()` evaluates all four badge rules and returns newly-earned badges in one call, and `getBadges()` returns current state. Splitting that into a second repository would just mean one repo calling the other for every record — same data, no real separation of concerns.
- `ActivityRepository` is extended with "newly earned" return values on `record()` (not in the brief's literal interface) specifically to drive the "badges show a one-time snackbar" requirement without a separate polling/diffing mechanism.
- Extracted `_DashedCirclePainter` (previously private to the Join form's photo picker) into `core/widgets/dashed_circle_painter.dart` since the locked-badge ring on My activity needed the same shape — a real second consumer, not speculative reuse.
- Extracted the "Today/Yesterday/weekday" date-label logic (previously private to the Conversation screen) into `core/utils/date_utils.dart` as `formatDayLabel` for the same reason: My activity's recent-activity rows needed it too.

## Final status
All 20 screens in scope are implemented and wired; `flutter analyze` is clean and all 27 tests pass as of the last commit. Stubs intentionally left match the brief's list below — nothing else in the 15-screen scope is a placeholder.

## Stubs intentionally left
video/devotional/document viewers, quiz player, "Read story" detail, post comments, prayer "Respond", Bible characters/texts topic pages
