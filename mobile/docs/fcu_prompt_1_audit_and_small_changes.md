# FCU app, Prompt 1 of 3: audit and harden screens 1-20, then apply the small design changes

The design grew from 22 to 63 screens. It is being delivered in three prompts. **This is prompt 1.** Prompt 2 builds screens 21-42 and prompt 3 builds 43-61, so **do not build those screens here**. This prompt makes the existing 20 screens correct, efficient and ready for the rest.

The existing code is the source of truth. The earlier briefs (`docs/fcu_flutter_first5_prompt.md`, `docs/fcu_flutter_next15_prompt.md`) are reference only: consult them to check intent, do not re-read them end to end. Rules unchanged: no new packages without asking, fake repositories behind interfaces, `flutter analyze` clean, small commits.

## 0. Working method (keep token use low)
1. Read `lib/` and `test/` once. Don't print large files back to me.
2. Phase A (audit) is **read-only**. Write findings to `docs/audit.md` before changing any code. Phase B onward changes code.
3. Reply after the audit with: counts by severity, the top 10 findings, and the questions you need answered. Then **wait for my "go"** before Phase B. Afterwards, no more stopping unless blocked.
4. After each phase: analyze, tests, commit, report in **3 lines max**. No code in chat.
5. Track everything in `docs/progress.md` (checklist) and resume from it.

## Phase A: audit (read-only, write `docs/audit.md`)
Grade every finding **P0** (wrong behavior, data/privacy leak, crash), **P1** (bug-prone, slow, inaccessible, hard to change) or **P2** (consistency, cleanup). For each: file, problem, fix, estimated size.

**A1. Function review: is each one built the best way?** For every row, verify the invariant in code (repository level, not only UI), then decide **keep / change** with a one-line reason. If something simpler or more robust exists within the current stack, say so.

| Function | What must always be true |
|---|---|
| Create profile | Required fields; email/phone/username formats; age at least 13; username uniqueness check; photo optional; double submit creates one profile |
| General community | Joined automatically from the institution; cannot be left; shown first |
| Specific membership | Maximum one; request rejected at repository level when one is pending/approved; two rapid taps create one request; legal transitions only: none -> pending -> approved or rejected -> none (illegal ones throw) |
| Hub search | Local, case-insensitive on name, day and room; disabled while pending; empty state |
| Route guards | Feed/community routes require `approved`; deep links and Back can't bypass; guards live in the router, not scattered in screens |
| Feed | Paging-ready repository API; `ListView.builder`/slivers; like is optimistic with rollback; a new post appears exactly once; one relative-time formatter, unit-tested |
| Composer | Discard confirmation if there is content; Post disabled when empty; images resized/compressed on pick (e.g. max 1600 px, quality 80); a sensible attachment limit |
| Prayer wall | "I prayed" once per user and per request; count consistent after refresh; anonymous requests carry **no author id** in the model, logs or UI |
| Testimonies | New story is `pending`; only the author sees pending; others see `reviewed` only |
| Pathways | Strictly sequential; progress derived from step states (not stored twice); later pathways unlock by a configurable rule |
| Resources | Filters combine (type x topic); empty state |
| Messaging | Threads ordered by last activity; unread count accurate; opening marks read; send has sending/sent/failed states; blocked users hidden |
| Report / block | One generic report path; reason required; reports are stored; blocking hides threads, posts and comments everywhere |
| Activity / badges | Events recorded at the source; badge rules deterministic and tested; activity never exposed to other users |

**A2. Cross-cutting checklist**
- **Architecture:** feature-first layering respected; UI never touches fakes directly (only repository interfaces via providers); no duplicated widgets (headers, cards, buttons, chips); no magic numbers (tokens only); dead code and unused dependencies removed (confirm `material_ui` is gone); consistent naming.
- **State management:** provider scoping and `autoDispose`; narrow rebuilds (`select`, `const`); no async gaps using `BuildContext` without `mounted` checks; controllers, focus nodes and animations disposed; optimistic updates roll back on failure.
- **Navigation:** go_router redirects/guards; correct back stack after submits (`go`/`replace`); no double-pops; route params validated; unknown route shows `ErrorView`.
- **Forms:** validation timing, inline errors, correct keyboard types, autofill hints, focus order, submit disabled while loading, nothing hidden by the keyboard, long forms scroll.
- **Performance:** long lists virtualized; header does not rebuild on tab switch (the community shell stays mounted); `RepaintBoundary` on `CustomPaint` art; marquee is cheap and respects reduced motion; images cached/resized; profile feed scrolling in profile mode and note any jank.
- **Fonts and offline:** Source Sans 3 must render with **no network**. Bundle the weights used (google_fonts supports bundled assets) and disable runtime fetching.
- **Responsive and accessible:** test 320x568, 390x844, 430x932; text scale 1.3 and 2.0 with no overflow; safe areas and gesture bars; portrait locked unless I say otherwise; status-bar icons readable on amber; 44px targets; semantic labels on icon-only buttons; no color-only meaning; contrast on honey/cream chips.
- **Privacy and security hygiene:** no PII or passwords in logs; anonymous data truly anonymous; no secrets in code; user text displayed safely; debug-only features guarded by `kDebugMode`.
- **Tests:** list which invariants in A1 lack tests. Add `analysis_options.yaml` strictness if not set (`flutter_lints` + `use_build_context_synchronously`, `prefer_const_constructors`, `unawaited_futures`).
- **Localisation:** do **not** implement. Propose in one paragraph how to externalise strings now so Swahili/Kinyarwanda/Luganda can come later (Flutter `gen-l10n` + ARB). I decide.

## Phase B: fix
- Fix all **P0** and **P1**; do **P2** only when cheap. **No redesigns:** keep visuals and behavior unless a finding says it is wrong, and record every behavior change in `docs/audit.md`. Each behavior fix gets a test first or alongside. Commit as `fix(...)` / `refactor(...)`.
- **Build these foundations now**, because prompts 2 and 3 depend on them, then migrate existing screens to them:
  - `Skeleton` (animated opacity, no package): amber header block 120 high with bottom radius 28 and a 160x24 translucent white bar, then two white cards (radius 16) with `#EEEDE8` blocks (radius 8): 40px circle avatar, 50% and 30% width lines, two text lines (100%, 80%), a 90 high media block.
  - `ErrorView`: icon, "Something went wrong", "We could not load this page. Please try again.", amber **Try again** (re-runs the failed call), outlined **Contact support** (route `/help`, a placeholder until prompt 3).
  - `EmptyState` (icon, title, body, optional amber action) and `OfflineBanner` ("You are offline", "Showing saved content. Posting is paused.", **Retry**) plus a fake `ConnectivityService` (ask before adding `connectivity_plus`).
  - **Roles and guards:** `UserRole { student, mentor, superMentor }` per community membership; a router guard chain with ordered, empty extension points for later: suspended -> unacknowledged warning -> signed out -> onboarding incomplete -> membership. Only the membership guard exists today.
  - **Debug scenario registry** (`kDebugMode`): a Settings-independent screen (opened by long-pressing the profile name for now) where features register named scenarios (e.g. "Approve my request"). Seed it with the scenarios that already exist.
  - **`PlaceholderScreen(owner: 2|3, title)`** ("Coming soon" + back button) and the **wiring ledger** (below).

## Phase C: small changes to existing screens
All soft style. Each new control navigates to a **registered placeholder route** (not a dead tap) and is recorded in **`docs/wiring.md`** as `source screen | control | temporary route | resolved in prompt N`. Prompts 2 and 3 will resolve their rows and delete them.

| Screen | Change | Route (resolved in) |
|---|---|---|
| 1 Landing | White pill **Sign in** (44 high, 2.5px ink border, bold style) at the right end of the logo row | `/login` (2) |
| 2 Join form | Button label becomes **Continue**. **Keep current behavior** (creates profile -> hub) until prompt 2 replaces it; mark with a `TODO(prompt2)` | `/join/password` (2) |
| 2b Profile | Replace Edit button with two: **Edit profile** and **Settings** (white 44px round icon buttons) | `/settings/profile` (3), `/settings` (3) |
| 3 / 3b Hub | Notification bell next to the avatar (48px white circle row; unread dot hidden for now) | `/notifications` (3) |
| 3b Pending | Debug link target becomes the approved result screen | `/request/approved` (2) |
| 5 Feed | For **super-mentors only**: white 44px rounded **Manage** icon button in the header row. Add a post type with a **photo** (150 high, radius 12) above the caption. Every post gets a 44px "..." button; tapping the body/photo opens the post | `/community/:id/manage` (2), post options sheet (2), `/post/:id` (2) |
| 6 Info | **View meetings** button; **Leave community** (outlined, destructive wording; hidden for super-mentors) | `/community/:id/meetings` (3), leave sheet (2) |
| 7 Resources | Rows open the future viewers (video, devotional, quiz via **Start**, document) | `/resources/video/:id`, `/devotional/:id`, `/quiz/:id`, `/document/:id` (2) |
| 9 Messages | New-message button targets the full screen; **keep the current bottom sheet working until prompt 3 replaces it** | `/messages/new` (3) |
| 10 Conversation | Header avatar tappable | `/members/:id` (3) |
| 14 Prayer | **Respond** opens the request page | `/prayer/:id` (3) |
| 16 Testimonies | **Read story** opens the story | `/testimony/:id` (3) |

Also seed a post with a photo in the fake feed (vector placeholder art, no bitmaps) and a super-mentor test account switch in the debug registry.

## Phase D: verify
- `flutter analyze` zero; `dart format` clean; all tests green; new tests exist for every A1 invariant that lacked one.
- Run on the three sizes and at 1.3x/2.0 text scale; no overflow, no keyboard overlap; profile-mode scroll on the feed.
- **Golden tests** for screens 1, 2, 3, 4, 5 at 390x844 as a regression baseline (fonts must be bundled for this to work).
- Final reply: top fixes made, behavior changes (with reasons), open questions, and the contents of `docs/wiring.md`.
