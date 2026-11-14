# Release readiness (Batch 6, report only)

Checked by Agent A on 2026-11-14. No P0 found, so nothing was changed for this report except the Android launcher label ("FCU").

## Test builds
- Debug APKs are built by GitHub Actions (`.github/workflows/mobile-apk.yml`) on every push to `main` that touches `mobile/`, or on demand (Actions > "Mobile debug APK" > Run workflow). Download the APK from the run's **Artifacts** (kept 14 days).
- **Debug on purpose:** the app runs on fake repositories, and testers need the debug scenario screen (long-press "Version" on Settings, or the name on My profile) to approve join requests, go offline, receive a warning, suspend the account, and so on.
- CI runs analyze and all tests except the goldens. Golden images are rendered on Windows and fonts differ on Linux, so run `flutter test test/golden` locally.

## Debug-only code paths (all guarded)
| Path | Guard |
|---|---|
| `/debug` route (scenario registry) | registered only `if (kDebugMode)` in `app_router.dart` |
| Debug screen body | returns nothing unless `kDebugMode` (`debug_scenarios_screen.dart`) |
| Long-press on "Version" (Settings) and on the profile name | `kDebugMode ? ... : null` |
| Fake email code shown on Verify email | `if (kDebugMode)` (`verify_email_screen.dart`) |
| `debug*` hooks (`debugApprove`, `debugSuspend`, `debugConfirmGuardian`, `debugSeedAccount`, role override) | live only on `Fake*` classes, reachable only from debug scenarios; they disappear when the fakes are replaced |

## Personal data and passwords
- No `print`, `debugPrint` or `log` calls anywhere in `lib/`.
- Passwords never enter app state in plain text: sign-up keeps a fake digest, and sign-in and delete send the password straight to `AuthRepository`. Login errors are generic (`InvalidCredentials`).
- Anonymity, blocking, private activity, reviewed-only testimonies, the under-18 messaging limit and muted notifications are enforced in the repositories (see `docs/progress.md`).

## Before a store release (not needed for phone testing)
| Item | Status |
|---|---|
| App name | Android label is "FCU" (was `focus_1`); iOS display name still to set |
| Application id | still `com.example.focus_1`. **Must change before Play Store** (renaming touches `build.gradle.kts`, `namespace` and the Kotlin package path) |
| Icon | default Flutter icon (`mipmap-*/ic_launcher.png`) |
| Splash | default white launch background |
| Release signing | release build uses the debug key; needs a real keystore |
| Version | `1.0.0+1` in pubspec, `appVersion = '1.0'` shown in Settings |
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
