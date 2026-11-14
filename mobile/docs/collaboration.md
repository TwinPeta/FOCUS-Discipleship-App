# Working together: two Claude agents on the FCU mobile app

Two Claude Code agents build the remaining screens at the same time:

- **Agent A**: the session that built screens 31 and 32 (super-mentor tools, moderation).
- **Agent B**: the session that built screens 39-42 (post detail, post options, `ReportFlow`).

This file is the contract between them. Read it at the start of every session, before touching code. If a rule here conflicts with an older brief, this file wins. The product briefs (`docs/fcu_prompt_*.md`) still define *what* each screen does.

---

## 1. First: repair `main` (Agent B, before anything else)

> **Done (`fd56789`, 2026-11-14).** `.gitignore` now has `/lib/`; the nine files are committed; a clean checkout gives `flutter analyze` 0 issues and 134 tests green. Agent A can merge `extend`.

`main` does not compile right now. The root `.gitignore` contains `lib/`, which silently ignores every **new** file under `mobile/lib`. The commits for screens 39-42 went in without these files, which exist only on Agent B's disk:

```
mobile/lib/core/widgets/message_input_bar.dart
mobile/lib/core/widgets/report_icon_button.dart
mobile/lib/features/feed/domain/comment.dart
mobile/lib/features/feed/presentation/post_detail_screen.dart
mobile/lib/features/feed/presentation/providers/post_detail_providers.dart
mobile/lib/features/feed/presentation/widgets/post_options_sheet.dart
mobile/lib/features/feed/presentation/widgets/post_photo_view.dart
mobile/lib/features/messaging/presentation/content_report_screens.dart
mobile/lib/features/messaging/presentation/report_flow.dart
```

Agent B:
1. `git pull --rebase origin main`
2. Change the `lib/` line in the root `.gitignore` to `/lib/` (it only ever meant a top-level `lib`).
3. `git add .gitignore` plus each file above by path, commit `fix(mobile): add files missing from 39-42 commits`, and push.
4. Confirm the result: `flutter analyze` shows 0 issues on a **clean** checkout (see section 5, step 6).

**Agent A waits for this**, then merges branch `extend` (screens 31, 32 and the document page-label fix) into `main`. In conflicts, Agent A keeps `main`'s versions of the screen 39-42 files and drops its stale WIP snapshot (commit `62f1917`). After that merge, `extend` is retired and both agents work from `main`.

---

## 2. Who builds what

Ownership is split by **feature folder**, so the two agents rarely edit the same files. Build in the order listed. Each agent owns the data layer of its screens too (models, repositories, providers, tests).

### Agent A: moderation, notifications, enforcement, meetings
| Order | Screen(s) | Notes |
|---|---|---|
| 1 | Merge `extend` into `main` (after section 1) | |
| 2 | **30** Manage community | Live counters from `JoinRequestRepository` and `ModerationQueueRepository`; links to 31 and 32; then delete the two debug shortcuts "Open join requests" and "Open reports to review" |
| 3 | **44** Notifications, **45** Notification settings | Builds on `recipientId` in `NotificationRepository`; muting stops records from being created |
| 4 | **61** Moderator warning, **60** Account suspended | Uses `WarningRepository`; fills in the `SuspendedGuard` and `UnacknowledgedWarningGuard` stubs in `core/router/route_guards.dart` |
| 5 | **51** Meetings | Injected clock; the check-in window; records an `ActivityEvent` |
| 6 | **56, 57, 59** Offline, loading, error audit | All screens, including the offline gap in viewers 33-38 |

### Agent B: people, messaging, content detail, settings
| Order | Screen(s) | Notes |
|---|---|---|
| 1 | Repair `main` (section 1) | |
| 2 | **Content reports feed moderation** | `ReportFlow` for post, comment, prayer and testimony targets must create or append a `ModerationCase` via `ModerationQueueRepository`. Add a `fileReport(...)` method there; Agent A reviews it. Today the queue only has seeded cases |
| 3 | **43** Member profile, **54** New message, **55** Blocked users, **58** No messages yet | Blocking enforced in the repositories |
| 4 | **52** Prayer request detail, **53** Testimony detail | Anonymity everywhere; reviewed-only testimonies |
| 5 | **46-50** Settings, Edit profile, Privacy & data, Delete account, Help & FAQ | |

### Together, last
- **Batch 6** (final wiring, integration tests, release check) starts only when both columns are done. Agent A writes the integration tests; Agent B walks every link and Back behaviour. Split it with a claim (section 3) first.
- **Anything not listed:** claim it first. Never start it silently.

### Hand-offs (where one agent needs the other's work)
- 44 (A) routes "moderator warning" notifications to 61 (A) and "prayer response" to 52 (B). Until 52 lands, route to the existing placeholder.
- 61 (A) links to `/charter` (exists) and shows content hidden by `ModerationQueueRepository.isHidden`.
- 46 Settings (B) links to 45 Notification settings (A) and 55 Blocked users (B). Use the placeholder route until the other side lands.
- When you need something from the other agent's area, **add a placeholder route + `docs/wiring.md` row**. Don't build their screen yourself.

---

## 3. Claiming work (prevents double work)

Before starting a screen, add or update its row in the table below, then commit and push **only that change** (`docs: claim screen NN`). Pull first. If the row is already claimed by the other agent, pick something else.

| Screen | Owner | Status | Branch / commit |
|---|---|---|---|
| 30 | A | done | see `git log --grep "screen 30"` |
| 43, 54, 55, 58 | B | not started | |
| 44, 45 | A | done | see `git log --grep "screens 44"` |
| 46-50 | B | not started | |
| 51 | A | not started | |
| 52, 53 | B | not started | |
| 56, 57, 59 | A | not started | |
| 60, 61 | A | done | see `git log --grep "screens 60"` |
| Content reports to moderation | B | done (see `git log --grep "content reports feed moderation"`) | Agent A please review: `fileReport`, `ModeratedContent.testimony`, nullable `ModerationCase.authorId` + `canWarn` (screen 32 shows "Author unknown"). **Reviewed by A: OK.** One nit: a report with no `reporterId` is keyed as `''`, so a second id-less report never raises the count; consider requiring `reporterId` for content reports. |

Status values: `not started`, `in progress`, `done (<commit>)`, `blocked: <reason>`.

---

## 4. Shared files: edit carefully

Both agents edit these files. Keep edits small, append rather than reorder, and pull right before editing them:

- `lib/core/router/app_router.dart`: add routes; never reorder existing ones.
- `lib/core/router/placeholder_routes.dart` and `docs/wiring.md`: remove only the rows for the screen you just built.
- `lib/core/router/route_guards.dart`: only Agent A changes the guard chain.
- `lib/core/providers/repository_providers.dart`: add providers at the end of the relevant group.
- `lib/core/widgets/*`: new shared widgets are welcome. **Changing an existing widget's API** needs a note in your commit message and an update at every call site in the same commit.
- `docs/progress.md`: add lines under your own screen; don't rewrite the other agent's lines.

Already built, so reuse it instead of rebuilding:
- **Agent A built:**
  - `NotSuperMentor` (in `community/domain/user_role.dart`)
  - `JoinRequestRepository`
  - `ModerationQueueRepository`, including `isHidden`, which the post and prayer repositories already filter on
  - `WarningRepository` / `Warning`
  - `NotificationRepository.add(recipientId:)` and `getNotificationsFor`
- **Agent B built:** `ReportFlow`, `BottomSheetScaffold`, `message_input_bar`, `report_icon_button`, `post_options_sheet`, `Comment`.

---

## 5. Git rules (these caused the last two breakages)

1. **Use your own working folder.** Never run two agents in the same folder. Use a separate clone or `git worktree add ../fcu-agent-b main`. In a shared folder, one agent's commit sweeps in the other's half-finished files.
2. **Work on `main` in small steps.** Run `git pull --rebase origin main` before starting a screen, before editing a shared file, and before every push.
3. **Stage by explicit path.** Never use `git add -u`, `git add .` or `git add -A`. Check `git status` and `git diff --staged` before committing.
4. **New files under `mobile/lib`:** `.gitignore` is fixed (`/lib/`), so use plain `git add <path>`.
5. **Never push red.** `flutter analyze` must show 0 issues and `flutter test` must be all green before a push. Work in progress that doesn't compile stays local; don't push "wip" to `main`.
6. **Check before pushing that nothing is missing:**
   - `git status --short --ignored mobile/lib` must print nothing.
   - Optional stronger check: `git stash -u && flutter analyze && git stash pop`.
7. **Commit messages:** `feat(mobile): screen NN <name>`, `fix(mobile): ...`, `docs: ...`. One screen (or one batch) per commit, plus any shared-file edits it needs.
8. **No force-pushes to `main`.** To undo, make a new commit (`git revert`, or `git restore --source=<rev> --staged <paths>`).
9. If a pull brings conflicts in the other agent's files, **keep their version** and rebase your change on top. Ask the user if unsure.

Tooling on this machine: Flutter is at `F:\Projects\Focus\flutter_windows_3.50.0-stable\flutter\bin\flutter.bat` (also on PATH as `flutter`). Set `PUB_CACHE=F:/.pub-cache` first, because the C: drive is full. The formatter is `dart format`, not `flutter format`.

---

## 6. How to build a screen well (the quality bar both agents hold)

For every screen:
1. **Read before writing:** the screen's paragraph in the brief, `docs/progress.md`, `docs/wiring.md`, and the code you'll touch. Reuse `core/widgets` and existing repositories. No duplicated widgets; anything used twice moves to `core/widgets`.
2. **Rules live in the data layer.** Role checks, blocking, anonymity, under-18 limits, muted notifications and hidden content are enforced in the fake repository (which throws or filters), not only in the UI. Repositories take the actor's role or identity explicitly so the rule is testable.
3. **Every async screen has four states:**
   - loading: `Skeleton`
   - error: `ErrorView` with Try again re-running the call
   - empty: `EmptyState`
   - offline: `OfflineBanner`, with write actions disabled rather than hidden
4. **Every action:** disabled until valid, a loading state on the button, no double submit (guard in the UI *and* reject a second in-flight call in the repository), a snackbar on success, and `showErrorSnack` on failure.
5. **Text and layout:**
   - No literal `[ ]` in UI text; brackets in the brief mean "a value goes here".
   - No magic numbers: name constants or use `AppColors` / `AppRadii` / `AppTextStyles`.
   - 44px touch targets, semantic labels on icon-only buttons, and no overflow at 1.3x text.
6. **Tests, focused:** repository rules (permissions, state transitions, notifications created, privacy filters), one widget test for the main happy path, and a guard test if the route is protected. Put them in `test/<feature>/`.
7. **Finish:** run `dart format`, `flutter analyze` (0 issues) and the full `flutter test`. Then:
   - remove the placeholder route and its `docs/wiring.md` row
   - tick the screen in `docs/progress.md`, with assumptions listed
   - update the claim table above
   - commit (section 5) and push
8. **Report to the user in 3 lines:** what was built, test count, and anything left or assumed.
9. **Unclear detail:** choose the simplest option consistent with the code and record it under "Assumptions" in `docs/progress.md`. Ask the user only when the choice changes product behaviour, or before adding a package.
