# Sprint A1 — Agent A, 30 minutes (started 2026-11-15)

Roadmap: `docs/roadmap_v2.md`. Design: `mobile/FCU Student  Review.html` (open in a browser). Claims: `docs/collaboration.md`.

## Scope (in order of value)
| Sub-agent | Branch / worktree | Tasks | Owns these files (nobody else edits them) |
|---|---|---|---|
| **theme** | `sprint-a1-theme` | A0.1 Bricolage Grotesque + heading weights; A0.2 gradient on amber headers and primary buttons; A0.3 dark theme wired to `themeModeProvider` | `lib/core/theme/app_theme.dart`, `app_text_styles.dart`, `lib/main.dart`, `pubspec.yaml` (fonts/assets), `assets/`, `amber_header_scaffold.dart`, `app_primary_button.dart`, `community_header_chrome.dart`, `test/golden/goldens/*` |
| **nav** | `sprint-a1-nav` | A1.1 bottom nav Home \| Communities \| Messages \| Profile + centre Create button opening the Create menu (screen 66); A1.6 Settings: remove the duplicate "Edit profile" row, add Appearance (Light/Dark/System) | `core/widgets/app_bottom_nav.dart`, new `features/create/` (Create menu), `features/settings/presentation/settings_screen.dart`, `test/navigation/bottom_nav_test.dart`, settings tests; shells/hub/profile/inbox only to add or replace the nav bar |
| **feed** | `sprint-a1-feed` | A1.4 count-only likes and comments (no words); A1.3 "Learn" quick link: Resources available in the General community | `core/widgets/post_card.dart`, `features/feed/presentation/post_detail_screen.dart`, `features/feed/presentation/general_feed_screen.dart`, `features/resources/**`, feed and resources tests |

**Deferred (need the product owner's confirmation in roadmap_v2 "Please confirm"):** A1.2 Home scroll behaviour, A1.5 video auto-slider. **A1.7** full restyle follows once theme lands.

## Contracts (already on main, use them, do not redefine)
- `AppColors.amberLight` `#F5CE3E` (normal), `AppColors.amberDark` `#E5A90A` (emphasis), `AppGradients.brand` (`lib/core/theme/app_gradients.dart`).
- `themeModeProvider` (`lib/core/theme/theme_mode_provider.dart`): `ref.watch(themeModeProvider)`, `ref.read(themeModeProvider.notifier).set(ThemeMode.dark)`. In memory only.

## Rules for sub-agents
- Work only in your own worktree and branch; **commit there, do not push**; Agent A merges.
- Stage by explicit path. `flutter analyze` must show 0 issues; run only the tests for your area (memory is tight). Agent A runs the full suite after merging.
- Flutter: `F:\flutter_windows_3.50.0-stable\flutter\bin\flutter.bat`, `PUB_CACHE=F:/.pub-cache`; formatter is `dart format`.
- Record decisions in your final report; Agent A copies them into `docs/progress.md`.

## Status
| Sub-agent | Status | Commit(s) | Notes |
|---|---|---|---|
| theme | running | | |
| nav | running | | |
| feed | running | | |
| merge + full test + push | waiting | | |
