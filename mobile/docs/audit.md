# Audit: screens 1-20 (prompt 1, Phase A)

Baseline before any change: `flutter analyze` 0 issues, 27/27 tests green, Flutter 3.50.0.
Grades: **P0** wrong behavior / leak / crash, **P1** bug-prone / slow / inaccessible / hard to change, **P2** consistency / cleanup.
Sizes: **S** < 1 h, **M** 1-3 h, **L** > 3 h.

**Counts: 4 P0, 32 P1, 17 P2.**

---

## A1. Function review

| Function | Verdict | Reason (invariant check at repository level) |
|---|---|---|
| Create profile | **change** | Formats and age >= 13 are validated in the UI only. There is no username uniqueness check. A double tap in the same frame can create two profiles, because the guard runs after validation and the repo has no idempotency. Photo is optional ✓. `currentProfileProvider` (a StateProvider) is the real source of truth, and `ProfileRepository.getCurrentProfile` is never read. See P0-4, P1-31. |
| General community | **change** | Joined automatically ✓ (derived from the institution), cannot be left ✓ (no API), shown first ✓. **But the General feed never loads** (P0-1). |
| Specific membership | **change** | Max-one and the legal transitions are enforced only by disabled buttons. `FakeMembershipRepository.requestToJoin` overwrites a pending or approved membership. `debugApprove`/`reject` work from `none`. Nothing throws. See P0-3. Simpler and more robust: a pure `Membership.transitionTo()` state machine in the domain, called by the repo. |
| Hub search | **keep** | Local and case-insensitive on name, day and room ✓. Disabled while pending ✓. Empty state ✓. Tested ✓. Minor: move `_filter` out of the widget into a pure function (P2-16). |
| Route guards | **change** | They are wrapper widgets that redirect in a post-frame callback, not router redirects. `/communities`, `/communities/:id` and `/profile` have no profile guard. A locked pathway can be opened by deep link. There is no `errorBuilder`. See P1-17/18/6. |
| Feed | **change** | **The like is persisted inverted** (P0-2). The repo is not paging-ready (P1-16). Lists are not virtualized (P1-21). There is no rollback and refresh blanks the list (P1-14). "Appears exactly once" works only because the repo and the controller share a mutable list (P1-15). There is one relative-time formatter ✓ but it has no unit test. |
| Composer | **change** | Post is disabled when empty ✓. There is no discard confirmation, no resize/compress (`image_picker` supports `maxWidth`/`imageQuality` without a new package) and no attachment limit (P1-13). |
| Prayer wall | **change** | One mark per user ✓ and the count stays consistent ✓ (tested). But anonymity is enforced by an `assert`, which is stripped in release (P1-2). Un-marking and re-marking records a new "prayed" event, so the badge can be farmed (P1-3). Avatars receive the full name as initials (P1-28). |
| Testimonies | **change** | New stories are `pending` because the UI sets it; the repo does not force it. "Only the author sees pending" trusts a client-set `isMine` flag stored on the item, not an author id (P1-1). |
| Pathways | **change** | The repo lets you complete a locked or done step, so the sequence is not strict (P1-4). Progress is stored twice: `Pathway.status`, `currentStepIndex` and `stepCount` alongside the step states (P1-5). The unlock rule is a single `unlocksAfterPathwayId` and is not checked on the steps route (P1-6). |
| Resources | **keep** | Type and topic filters combine ✓. Empty state ✓. Add a unit test for the combination (filtering lives in the widget; move it to a pure function). |
| Messaging | **change** | Opening a thread marks it read ✓. Unread is cleared ✓. But threads are not re-ordered by last activity (P1-7), there is no `failed` state or retry (P1-8), and the new-message sheet lists members of a community the user is only *pending* in (P1-12). |
| Report / block | **change** | A reason is required ✓ (non-null enum plus a disabled button). Reports are stored ✓. But the report path is thread-specific (P1-10), and blocking hides threads only, not posts, members or a deep-linked conversation (P1-9). |
| Activity / badges | **change** | Badge rules are deterministic and tested ✓, and activity is private ✓. But events are recorded from 5 UI call sites, not at the source, with duplicated invalidate code (P1-11). Event types are strings (P2-6). |

---

## P0

| # | File | Problem | Fix | Size |
|---|---|---|---|---|
| P0-1 | `feed/presentation/providers/feed_providers.dart:9`, `community/data/community_repository.dart:111` | `FeedPostsController._scopeFor` looks up `communityByIdProvider('general-<inst>')`. `FakeCommunityRepository.getCommunityById` only knows the 3 specific ids and throws, so **screen 8 always shows "Could not load the feed"**. The composer chip shows "Posting in …". | Pass the scope explicitly (family key `FeedKey(communityId, scope)`), and let `CommunityRepository.getCommunityById` resolve general ids. Add a widget test that the General feed shows its seed posts. | S |
| P0-2 | `feed_providers.dart:38-48`, `post_repository.dart:133` | The controller builds `toggled` and passes it to `repo.toggleLike(toggled)`, which flips it **again**. The repo stores the pre-tap state, so a like is lost on refresh and the count drifts. | Make the repo API idempotent, `setLiked(postId, liked)`, and roll back the optimistic state on failure. Test it. | S |
| P0-3 | `community/data/membership_repository.dart` | The repo does not enforce max-one or the legal transitions. `requestToJoin` replaces a pending or approved membership. `debugApprove()` from `none` yields `approved` with a null community. `reject` works from `none`. Nothing throws. | Add `Membership.transitionTo(next)` (none -> pending -> approved\|rejected -> none) that throws `IllegalMembershipTransition`. `requestToJoin` throws when pending or approved for another community, and returns the existing request for the same community, so two rapid taps give one request. Unit-test every edge. | S |
| P0-4 | `profile/presentation/join_form_screen.dart:172`, `profile/data/profile_repository.dart` | `_submit` has no re-entry guard before its first `await`, and the repo has no idempotency, so a same-frame double tap creates two profiles. Username uniqueness is not checked. Age and format rules exist only in the UI. | Return early when `_isSubmitting`. In the repo, `createProfile` validates (shared `Validators`), throws `UsernameTakenError`, and returns the existing profile on a repeated call. Add `isUsernameAvailable(username)` with an inline error. Test it. | M |

## P1

| # | File | Problem | Fix | Size |
|---|---|---|---|---|
| P1-1 | `testimony/domain/testimony.dart`, `testimony_repository.dart:51,56` | Visibility trusts the client-set `isMine` flag stored on the item. `submitStory` does not force `pending`. | Add `authorId`. The repo compares it with the viewer id passed in or injected, and forces `status = pending` on submit. | S |
| P1-2 | `prayer/domain/prayer_request.dart:12` | Anonymity is enforced by `assert` only, so it is gone in release builds. | Normalize in the constructor or factory (`anonymous` nulls the author) and strip again in `createRequest`. Test it in a release-style check (no assert reliance). | S |
| P1-3 | `prayer_providers.dart:43` | Each re-mark records a new `prayed` event, so one request can earn Prayer partner (5). | Record only the first-ever mark per request (the repo tracks it) and move recording to the repo or controller (see P1-11). | S |
| P1-4 | `pathways/data/pathway_repository.dart:187` | `completeStep` accepts locked or done steps, so it is not strictly sequential. A double tap records quiz/pathway events twice. | Throw unless the step is `current`. Make it idempotent. | S |
| P1-5 | `pathways/domain/pathway.dart` | Progress is stored twice (`status`, `currentStepIndex`, `stepCount` plus the step states). | Derive a `PathwayProgress` from the steps in one place (repo or domain). Remove the stored copies. | M |
| P1-6 | `app_router.dart:151`, `pathways_screen.dart:34` | A locked pathway is reachable by deep link and its steps can be completed. The unlock rule is hard-wired to a single prerequisite. | Add an `UnlockRule` value (`requiresCompleted: [ids]`) evaluated in the repo or domain. The steps screen shows a locked `EmptyState`. | S |
| P1-7 | `messaging_repository.dart:81` | Threads are never re-ordered by `lastAt`. | Sort by `lastAt` descending in `getThreads`. Test it. | S |
| P1-8 | `messaging_providers.dart:25`, `message.dart:1` | There is no `failed` state. An exception leaves the bubble at "Sending…" forever and is unhandled. | Add `MessageStatus.failed`, catch the error, and allow tap-to-retry. Test it. | S |
| P1-9 | `messaging_providers.dart:9` and the feed, prayer, members and thread providers | Blocking hides threads only. Posts, prayer requests, members and `/messages/:threadId` still show the blocked user. | Add one `blockedUserIdsProvider` and filter it in every user-content provider. `threadById` returns "not available". Test it. | M |
| P1-10 | `messaging/domain/report.dart`, `app_router.dart:189` | The report is tied to a thread (`threadId` required, route under `/messages`). Prompt 2 needs reports on posts and comments. | Use `Report{targetType, targetId, targetUserId, reason, details?, screenshot?}` with one generic route. The current route becomes a thin alias. | M |
| P1-11 | `resources_screen.dart:47`, `testimonies_screen.dart:94`, `pathway_steps_screen.dart:80`, `prayer_providers.dart:43`, `pathway_providers.dart:44` | Activity is recorded at 5 UI call sites, each copying the invalidate pair. The existing `recordActivity` helper is mostly unused. | Record at the source: an `ActivityRecorder` service called by the controllers or repos that own the action, and one place that invalidates. | M |
| P1-12 | `messages_inbox_screen.dart:44` | The new-message sheet uses `membership.communityId` even while the request is **pending**, so the user can message a community they are not in. | Require `approved`. | S |
| P1-13 | `composer_screen.dart` | There is no discard confirmation, no resize/compress (`pickImage` without `maxWidth`/`imageQuality`) and no attachment limit. A failed post leaves the spinner on. | Add a `PopScope` with a confirm sheet when there is content, use `maxWidth: 1600, imageQuality: 80`, limit attachments (see Q4), and use try/finally. | S |
| P1-14 | `feed_providers.dart:22,32,52` | `refresh()` sets `AsyncLoading`, so the list becomes a spinner and the scroll position is lost. Refresh errors are unhandled. Like and create have no rollback. | Use `AsyncValue.guard` while keeping the previous data, roll back on failure, and keep the post on create errors with a retry snackbar. | S |
| P1-15 | `post_repository.dart:124`, `prayer_repository.dart:58`, `testimony_repository.dart:49` | The repos return their internal mutable lists, so controller state aliases repo storage. "A new post appears once" works by accident. | Return `List.unmodifiable(copy)` and dedupe by id in the controllers. Test "new post appears exactly once" and "after refresh". | S |
| P1-16 | `post_repository.dart:5` | The feed API is not paging-ready. | Use `getPosts(communityId, scope, {String? cursor, int limit = 20}) -> Page<Post>`. The UI loads more at the end of the list. | S |
| P1-17 | `core/widgets/route_guards.dart`, `app_router.dart` | Guards are widget wrappers redirecting post-frame (a spinner flash, and per-route copies). `/communities`, `/communities/:id` and `/profile` are unguarded and dead-end on "No profile yet". | Build the router in a `routerProvider`, with `redirect` plus a `refreshListenable` bridged from Riverpod, and an ordered guard chain (Phase B foundation). Delete the wrappers. Add route tests for deep links. | M |
| P1-18 | `app_router.dart` | There is no `errorBuilder`, so an unknown route shows go_router's default page. An unknown community id shows bare text. | Use `ErrorView` for both. | S |
| P1-19 | `app_router.dart:39,163` | `/compose` and edit-profile depend on `state.extra`, which is lost on deep link or restoration. `/compose` without extra shows ComingSoon. | Use path params: `/community/:id/compose`, `/general-feed/compose`. Edit profile moves to `/settings/profile` (prompt 3); until then, read the profile from the provider rather than from `extra`. | S |
| P1-20 | `core/theme/app_text_styles.dart`, `main.dart` | `google_fonts` fetches Source Sans 3 at runtime. Offline it falls back to the system font, and goldens cannot be stable. | Bundle the weights used (400, 500, 600, 700, 800, 900) under `assets/google_fonts/` and set `GoogleFonts.config.allowRuntimeFetching = false` in `main`. See Q2. | S |
| P1-21 | Both feeds, prayer, testimonies, inbox, members, resources, activity | `ListView(children: [for …])` builds every row, so nothing is virtualized. | Use `ListView.separated`/`builder` (or slivers where a header scrolls with the list). | M |
| P1-22 | `initials_avatar.dart:50`, `join_photo_picker.dart:73`, `composer_screen.dart:440` | Full-resolution decode of picked photos (a 12 MP image for a 40 px avatar). | Use `ResizeImage` or `cacheWidth` from size × devicePixelRatio. | S |
| P1-23 | `app_text_field.dart:48`, `report_user_screen.dart:214`, `filter_chips.dart:31`, `prayer_wall_screen.dart:202`, `my_activity_screen.dart:70`, `composer_screen.dart:197` | Fixed `height:` clips or overflows at 1.3× and 2.0× text scale. | Use `constraints: BoxConstraints(minHeight: …)` instead. Verify all three sizes × two scales in Phase D. | M |
| P1-24 | Same files plus `post_card.dart:150`, `testimonies_screen.dart:274`, `resources_screen.dart:178`, `pathway_steps_screen.dart:193,210` | Targets under 44 px: filter chips 40, pills 36, Post 38, Start/Continue/Upload 40, Like/Comment about 26, the "Read story" link, the debug links. | Give each a minimum 44×44 hit area (keep the visuals). | S |
| P1-25 | `main.dart`, `ios/Runner/Info.plist:56` | Portrait is not locked (iOS allows landscape, and there is no `SystemChrome` call). The status bar style is not set on amber headers. | Lock portrait in `main`, `Info.plist` and the manifest. Wrap the scaffolds in `AnnotatedRegion<SystemUiOverlayStyle.dark>`. | S |
| P1-26 | `conversation_screen.dart:39`, `pathway_steps_screen.dart:82`, `testimonies_screen.dart:95` | `ref` is used after an `await` in widget code. Leaving within 400 ms throws "ref used after dispose". | Move the work into controllers, or check `mounted` before every `ref` use after an await. | S |
| P1-27 | Join, Request to join, Composer, New prayer, Share testimony, Report, Block | No error handling: on exception the spinner stays forever and the error is unhandled. | Use try/finally plus one shared `showErrorSnack` helper. | S |
| P1-28 | `prayer_wall_screen.dart:129`, `testimonies_screen.dart:236` | `AvatarWithPresence(initials: authorName)` puts the full name in the 40 px circle. | Use a shared `initialsOf(name)` (it is also duplicated in `Person` and `UserProfile`). | S |
| P1-29 | `info_members_screen.dart:93` | The "Online now" `Stack` has only `Positioned` children inside a `Row`, so its width is unbounded. Verify layout and give it an explicit width. | Use `SizedBox(width: …)` computed from the count. | S |
| P1-30 | `app_text_field.dart`, `join_form_screen.dart` | No `autofillHints`, no `textInputAction` or next-field focus, `onFieldSubmitted` is missing, and the phone validator rejects `-`, `(` and `)`. | Expose these props on `AppTextField`, wire focus order, and normalize the phone separators. | S |
| P1-31 | `profile_providers.dart:8` | The profile lives only in a `StateProvider` written by the screen. The repo is write-only. A real backend would lose the session on restart. | Use a `ProfileController` (`AsyncNotifier`) that loads from and writes through the repo. | S |
| P1-32 | `community_shell.dart:49`, `general_shell.dart:43` | The scope switch `push`es General and specific feeds alternately, so the back stack grows without bound. | Use `go` (or `pushReplacement`). | S |

## P2

| # | Where | Problem | Fix | Size |
|---|---|---|---|---|
| P2-1 | `pubspec.yaml` | `material_ui` is still present. On Flutter 3.50 it is the **official** Material package; `package:flutter/material.dart` is `@Deprecated` since 3.47. | **Keep** (see Q1). Remove `cupertino_icons` if unused. | S |
| P2-2 | Feeds | `_ComposeFab` and the whole post-list body are duplicated in `community_feed_screen.dart` and `general_feed_screen.dart`. | Use a shared `FeedList` and `ComposeFab`. | S |
| P2-3 | Prayer, Testimonies | The "title + amber 44 px +" header row, `_PillButton` and the 24/w900 title style are duplicated. | Use a `TabSectionHeader` widget and a text-style token. | S |
| P2-4 | `info_members_screen.dart:17`, `messages_inbox_screen.dart:96` | The role-label switch is duplicated. | Add `PersonRole.label`. | S |
| P2-5 | Everywhere | Radii literals (12/14/16/18/20/999) bypass `AppRadii`. There are `fontSize:` overrides, `Colors.red`/`Colors.green`, and no spacing tokens. | Add `AppRadii.pill/sm`, `AppColors.error/success` and `AppSpacing`, then migrate (mechanical). | M |
| P2-6 | `activity_event.dart` | Event types are strings. | Use `enum ActivityType`. | S |
| P2-7 | Providers | No `autoDispose` on the family providers (`communityById`, `feedPosts`, `prayerRequests`, `testimonies`, `threadMessages`, `threadById`, `resources`, `members`). | Use `autoDispose` where the state can be dropped (keep the feed alive while the shell is mounted). | S |
| P2-8 | `community_header_chrome.dart:44`, `illustration_collage.dart:127`, `stories_section.dart:120`, `community_cover.dart:33` | `CustomPaint` art has no `RepaintBoundary`. | Wrap it. | S |
| P2-9 | `marquee_strip.dart` | Each frame rebuilds the two `Text`s, and `TextPainter` re-lays out on every build. | Use `AnimatedBuilder(child: …)` with `Transform` only, and cache the width. (Reduced motion ✓.) | S |
| P2-10 | `conversation_screen.dart:94` | It scrolls to the bottom after **every** rebuild. | Scroll only when the message count grows. | S |
| P2-11 | `community_repository.dart:95` | `slugify(name).substring(0, 2)` throws for a name shorter than 2 characters. | Clamp. | S |
| P2-12 | `join_form_screen.dart:228` | The edit-profile mode still shows "Step 1 of 3". | Hide it when editing (prompt 3 replaces the screen). | S |
| P2-13 | `analysis_options.yaml` | No extra lints. | Add `use_build_context_synchronously`, `prefer_const_constructors`, `unawaited_futures`, `avoid_print`, `prefer_final_locals`. | S |
| P2-14 | `date_utils.dart` | `formatRelativeTime` has no test and no injectable clock. Future dates give negative values. | Add `now` as a parameter and unit tests. | S |
| P2-15 | `pathways_screen.dart:237` | A private `firstOrNull` extension duplicates the SDK's. | Delete it. | S |
| P2-16 | Hub, Resources, Inbox | The filtering logic lives inside widget state. | Move it to pure functions with unit tests. | S |
| P2-17 | `docs/progress.md` | "Data models to add" is still unchecked although they are done. | Tidy it. | S |

---

## A2. Cross-cutting summary
- **Architecture:** feature-first layering ✓. The UI reads repositories only through providers ✓, with one exception: `messagingRepositoryProvider` is typed as `FakeMessagingRepository` (it should expose interfaces only). Duplication and tokens: P2-2…5. No dead code found. `material_ui` is the official package (P2-1).
- **State:** no `select` usage, which is fine at this size. Disposal ✓ (all controllers, focus nodes and the marquee animation are disposed). Async gaps: P1-26. Rollback: P1-14. `autoDispose`: P2-7.
- **Navigation:** guards P1-17, unknown route P1-18, `extra` params P1-19, back stack P1-32. Submit transitions are correct (`go` after join and request, `pop` after composer/prayer/testimony, `pushReplacement` after report).
- **Forms:** validation on blur and on submit ✓, inline errors ✓, keyboard types ✓. Autofill, focus order and the phone format: P1-30. Submit is disabled while loading ✓, apart from the same-frame race (P0-4). Long forms scroll ✓.
- **Performance:** P1-21, P1-22, P2-8, P2-9. The community header stays mounted across tabs ✓ (`StatefulShellRoute.indexedStack`). Profile-mode jank check is deferred to Phase D.
- **Fonts and offline:** P1-20. There is no connectivity handling at all (Phase B foundation).
- **Responsive and a11y:** P1-23, P1-24, P1-25. Icon-only buttons have semantic labels ✓. The presence dot is color-only but is paired with "Online now" text in headers (acceptable). Honey and cream chips use ink text (#111), with contrast well above 7:1 ✓.
- **Privacy:** no `print`/`debugPrint` anywhere ✓. No secrets ✓. User text is rendered with `Text` only ✓. Debug features are behind `kDebugMode` ✓. Gaps: P1-2 (release-mode anonymity), P1-1, P1-12.

## Invariants with no test today
Membership transitions and double request (repo) · profile double submit, username uniqueness and repo-side age · General feed loads · like persisted and rolled back · new post exactly once (including after refresh) · relative-time formatter · composer discard, limit and resize · route guards (deep link to feed, locked pathway, unknown route) · thread ordering · send failed and retry · block hides posts, members and the conversation route · activity recorded once per source action · resources filter combination · prayer anonymity without asserts · testimony visibility by author id.

## Localisation proposal (not implemented, your decision)
Enable Flutter's built-in `gen-l10n` (`flutter: generate: true` plus `l10n.yaml`; `flutter_localizations` is already pulled in transitively by `material_ui`, so the only new dependency is `intl`, which needs your approval). Move every user-facing string into `lib/l10n/app_en.arb` with descriptive keys (`hubFindSpecificTitle`) and ICU plurals for the counts (`{count, plural, one{1 prayed} other{{count} prayed}}`). Screens read `context.l10n.x` through a one-line extension. Swahili (`sw`), Kinyarwanda (`rw`) and Luganda (`lg`) then become new ARB files. Material has no built-in `rw`/`lg` delegates, so those two need a small fallback delegate. To keep the migration cheap, do it feature by feature after prompt 3, and write new strings in prompts 2 and 3 as `const` in one `strings.dart` per feature so they can be moved mechanically.

---

## Phase B–D outcome (prompt 1)

**Fixed:** all 4 P0 and all 32 P1. P2 done: 1 (kept `material_ui`, the official package on Flutter 3.50), 2, 3, 4, 5 (partly: new tokens `AppColors.error/success/skeletonBlock`, `AppRadii.sm/md/tile/pill`, `AppTextStyles.tabTitle`; older literal radii remain), 6, 7 (partly: `threadById`, `communityMembers`), 8, 9, 10, 11, 12, 13, 14, 15, 16 (resources only), 17. Open: the rest of the P2-5 token migration and the hub/inbox filters as pure functions.

**Found during Phase D and fixed** (not in the audit): the Resources tab threw on layout (a `Row` with `stretch` inside a `ListView`, so Resources never rendered); several overflows at 2.0× text (chips, story cards, post header and actions, Report sent, the online count); and forms squeezed by the keyboard at 320×568 / 2.0×.

### Behavior changes (and why)
| Change | Why |
|---|---|
| Profile is loaded from and written through `ProfileRepository` (`ProfileController`) | One source of truth (P1-31) |
| Join form: taken usernames rejected (`admin`, `fcu`, `davidokello` seeded as taken), checked on blur and on submit | Uniqueness invariant (P0-4) |
| Phone numbers accept spaces, `-`, `(`, `)` and `.` | Common formats were rejected (P1-30) |
| Membership: illegal transitions throw; a second request while pending or approved shows "You already have a pending request…" | Repository-level invariant (P0-3) |
| Route guards live in the router; protected deep links wait on `/loading` (skeleton), then continue or redirect | Guards in one place (P1-17) |
| Unknown routes and failed loads show `ErrorView` (Try again / Contact support) | P1-18 |
| Compose is `/community/:id/compose` and `/general-feed/compose`; edit profile is `/profile/edit` | No reliance on `extra` (P1-19) |
| The like/comment row shows on every post, including your own | Your answer to Q6 (default accepted); the "..." menu needs that row |
| Composer: discard confirmation, at most 4 attachments, photos resized to 1600px at quality 80, Post disabled while offline | P1-13 + offline foundation |
| "I prayed" stays a toggle, but activity and badges count once per request | P1-3 (Q5 default) |
| Testimonies: pending stories are visible only to their author id; new stories are always stored as pending | P1-1 |
| Pathways: only the current step can be completed; locked pathways show a locked state, even via deep link | P1-4/6 |
| Messages: threads sorted by last activity; a failed send shows "Not sent · Tap to retry" | P1-7/8 |
| Blocking hides the person in threads, feeds, prayer wall, members and conversation deep links | P1-9 |
| New message requires an *approved* membership | P1-12 |
| Scope switch (General ↔ community) replaces the route instead of stacking | P1-32 |
| Portrait locked on phones; dark status-bar icons app-wide | P1-25 |
| Amber header pages go compact (title only) while the keyboard is open | Keyboard overlap at 320×568 / 2.0× |
| Video opens are recorded once per video | Activity is recorded at the source, deduplicated by source id |
