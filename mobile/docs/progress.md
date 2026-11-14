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
- [ ] `Post` (+communityId, media[], scope)
- [ ] `PrayerRequest`
- [ ] `Testimony`
- [ ] `Pathway`, `PathwayStep`
- [ ] `Resource`
- [ ] `Thread`, `Message`
- [ ] `Report`
- [ ] `Badge`
- [ ] `ActivityEvent`

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
