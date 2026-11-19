# Release readiness (Batch 6, report only)

Checked by Agent A on 2026-11-14. No P0 found, so nothing was changed for this report except the Android launcher label ("FCU").

## Builds and releases
- `.github/workflows/mobile-apk.yml` ("Mobile build") runs on every push to `main` that touches `mobile/`: analyze, all tests except the goldens, and an Android APK kept as a run artifact (14 days). Nothing is published.
- **To release:** Actions > "Mobile build" > Run workflow > tick **Publish**. One GitHub release per app version, tagged `mobile-v<version>`, with `fcu.apk` (Android; the app's update banner installs it) and `fcu-<version>-unsigned.ipa` (iPhone; sideloaded until TestFlight exists), and `mobile/docs/release-notes/<version>.md` as its text. Steps: `docs/release-notes/README.md`.
- Every mobile workflow stops before building when the version in `pubspec.yaml` has no release notes.
- The APK is a debug build signed with the fixed FCU key (repository secrets), so each version installs over the last.
- Golden images are rendered on Windows and fonts differ on Linux and macOS, so run `flutter test test/golden` on Windows.

## Debug-only code paths
None: the app has no debug screens or test hooks. The in-memory doubles and their `debug*` hooks live in `test/support/` and never ship.

## Personal data and passwords
- No `print`, `debugPrint` or `log` calls anywhere in `lib/`.
- Passwords never enter app state in plain text: sign-up keeps a fake digest, and sign-in and delete send the password straight to `AuthRepository`. Login errors are generic (`InvalidCredentials`).
- Anonymity, blocking, private activity, reviewed-only testimonies, the under-18 messaging limit and muted notifications are enforced in the repositories (see `docs/progress.md`).

## Before a store release (not needed for phone testing)
| Item | Status |
|---|---|
| App name | "FCU" on Android (label) and iOS (`CFBundleDisplayName`) |
| iOS | unsigned build check on macOS (`.github/workflows/mobile-ios.yml`); permission texts for photos, camera and microphone added. **To install on iPhones:** Apple Developer Program account, own bundle id (now `org.focusuganda.fcu`), signing via App Store Connect API key, TestFlight |
| Application id | `org.focusuganda.fcu` on Android and iPhone (was the template `com.example.focus_1`). Installed betas cannot update to it: testers uninstall and reinstall once |
| Icon | default Flutter icon (`mipmap-*/ic_launcher.png`) |
| Splash | default white launch background |
| Release signing | release build uses the debug key; needs a real keystore |
| Version | `version:` in pubspec (e.g. `1.0.0-beta.2`), passed to the app by CI and shown on Settings |
| Support email | placeholder `support@fcu.example` (`core/config/app_info.dart`) |
| Fonts | `google_fonts` downloads at runtime: the first launch needs internet; bundle the fonts for offline-first |

## Backend to-do list (every fake that must become a real call)
| Repository (fake) | What the backend must provide |
|---|---|
| `AuthRepository` | accounts, sign-in/out, email codes, password reset, guardian requests and consent, delete account (password check), sessions in secure storage |
| `ProfileRepository` | profiles, username uniqueness, update, delete |
| `CommunityRepository` | institutions, general and specific communities, members, meeting day/time/room |
| `MembershipRepository` | the user's one specific membership: request, approve/decline result, leave |
| `JoinRequestRepository` | super-mentor queue: pending requests, approve/decline (role-checked), notify the student |
| `MemberRepository` | member profiles (screen 43): public fields and earned badges only |
| `PostRepository` | feeds (paged), create, like, comments, hide-for-me, delete own post |
| `PrayerRepository` | prayer walls, create (with private owner for anonymous requests), "I prayed" once per user, responses, response notifications |
| `TestimonyRepository` | stories, pending until reviewed, reviewed-only for others, Encouraged |
| `PathwayRepository`, `LearningRepository`, `ResourceRepository` | pathways and steps, videos/devotionals/quizzes/documents, quiz scoring, private reflections, resume positions |
| `ActivityRepository` | the user's private events and badges; for super-mentors, members' last-active timestamps only |
| `MeetingRepository` | weekly meetings, RSVP, check-in within the window (server-side clock) |
| `MessagingRepository` (`ThreadRepository`, `MessageRepository`) | threads, messages, unread counts, under-18 limit |
| `ModerationRepository` | blocking and unblocking, enforced in every feed, comment list and inbox |
| `ReportRepository` | user and content reports; content reports file into the moderation queue |
| `ModerationQueueRepository` | level 1 cases, Hide/Warn/Keep/Escalate, hidden-content filter, admin queue |
| `WarningRepository` | moderator warnings and acknowledgement |
| `SuspensionRepository` | admin-set suspensions (read-only in the app) |
| `NotificationRepository` + `NotificationChannel` | per-recipient records, preferences and muting, email delivery (push can be added as another channel) |
| `PrivacyRepository` | data export by email; data retention (24 months) and deletion (30 days) |
| `StoriesRepository` | landing page stories |
| `ConnectivityService` | real network reachability (today a fake toggled from debug scenarios) |
