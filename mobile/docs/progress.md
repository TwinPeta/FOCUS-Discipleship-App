# Prompt 2 (screens 21-42) progress
Brief: `docs/fcu_prompt_2_screens_21_42.md`. Ledger: `docs/wiring.md` (clear every "resolved in 2" row).
- [x] Shared widgets: BottomSheetScaffold, CelebrationScreen, OtpField, PasswordField, ConfirmDialog (+ OnboardingScaffold); ReportFlow lands with batch 4
- [x] Batch 1: AuthRepository/session, SignUpController, 21 password, 22 verify (OTP), 23 consent, 24 guardian, 25 sign in, 26 forgot password, `/charter`; signed-out + onboarding guards; under-18 `canMessage` in MessageRepository; Join form stops creating the account
- [x] Batch 2: 27 approved, 28 declined (shown once, `seen`), 29 leave sheet; NotificationRepository + hub bell dot; debug "Approve/Decline my request", "Guardian confirms"; pending-hub debug link removed
- [x] Batch 3: 33 video (PlaybackController fake), 34 devotional (+reflection), 35 quiz, 36 result, 37 document, 38 badge earned (queue); completion -> activity + pathway step + badges; debug "mark step complete"/"attended meeting" removed
- [x] Batch 4: 39 post & comments, 40 post options sheet, 41/42 ReportFlow (post skin); user report 11/12 refactored onto ReportFlow; comments/prayer/testimony reports reuse it
- [ ] Batch 5: 30 manage, 31 join requests, 32 reports to review (Hide/Warn/Keep/Escalate); super-mentor guard + repository role checks
  - [x] 31 Join requests (`/community/:id/manage/requests`): `JoinRequest` + `JoinRequestRepository` (role-checked), approve/decline notify the student, "Already in" disables Approve; tests in `test/community/join_requests_test.dart`
  - [x] 32 Reports to review (`/community/:id/manage/reports`): `ModerationCase`, `Warning`, role-checked `ModerationQueueRepository` (Hide / Warn author / Keep / Escalate to admin, each records an outcome and leaves the queue), `WarningRepository`, hidden content filtered in the post and prayer repositories; tests in `test/moderation/reports_to_review_test.dart`
- [ ] Finish: analyze 0, tests green, wiring rows for prompt 2 cleared, assumptions + stubs recorded

## Prompt 2 assumptions
- Screen 31 lives at `/community/:id/manage/requests` (the existing manage guard covers it). Until screen 30 links to it, the debug scenario "Open join requests" switches to super-mentor and opens it.
- The join-request queue is a seeded fake for Growth Circle (4 students, one already in Life & Faith Circle); it is separate from the signed-in user's own `Membership`, whose approval stays on the "Approve my request" debug scenario.
- Student notifications carry `recipientId`; `getNotifications()` returns only the signed-in user's (recipientId null), `getNotificationsFor(id)` returns another user's. A backend would push these to that student.
- Screen 32 lives at `/community/:id/manage/reports`; debug scenario "Open reports to review" opens it until screen 30 links to it. The queue is seeded for Growth Circle (a comment, a post and a prayer request). Batch 4's `ReportFlow` for content will feed new cases into it; today `ReportRepository` submissions do not create cases.
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
