# Connecting the app to the backend

The app has no fake or demo data: every screen reads and writes the real API (`https://apis.focusuganda.org/v1` unless you say otherwise). To point a build somewhere else, give it the API address at build time:

```bash
# Android emulator talking to the API on your Mac
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:4000/v1
# Staging server
flutter build apk --dart-define=API_BASE_URL=https://staging-api.focusuganda.org/v1
```

Running the API locally? It starts empty: create the first admin and add institutions and communities in the back office (see `api/README.md`). The Flutter tests use in-memory doubles from `test/support/fakes/`; none of that ships in the app.

## What is connected

| Area | Status |
|---|---|
| Sign in / out, session refresh, sign-up, profile, guardian, delete account | Real |
| Communities, members, membership (request, leave, result screens), join requests (super-mentor) | Real. The role (student / mentor / super-mentor) comes from the community's leadership list |
| Feed: posts, likes, comments, photo upload | Real. "Hide this post" is kept on the device only |
| Prayer wall (requests, "I prayed", replies) | Real. The server keeps anonymous authors anonymous, including replies by the owner |
| Testimonies (share a story, review status) | Real. The "Encouraged" tap is remembered for this session only (no API yet) |
| Resources, quizzes (scored on the server), pathways, My activity and badges, landing stories | Real. Quiz answers are not revealed after each question (the server never sends them) |
| Messaging (inbox, conversations, under-18 limit), blocking, reports, data export | Real. Live: new messages and read receipts arrive over the realtime socket (`core/realtime/`) and refresh the inbox and the open conversation |
| Notifications and their settings | Real. The server creates them (request decided, someone prayed, a reply, a response) |
| Meetings: next meeting and history, RSVP, check-in | Real. Meetings are derived from the community's weekly schedule; check-in is open from 30 min before to 2 h after, judged by the **server's** clock |
| Mentor moderation ("Reports to review"): keep, hide, warn author, escalate | Real. Reports on the same item form one case. Escalated cases go to the back office queue |
| Warnings and suspension | Real. Warning someone hides the content, records the warning and notifies them. A suspended account is read-only; a suspension without an end date lasts 7 days |

## How it is wired

- `core/config/api_config.dart`: the API address (`API_BASE_URL`, production by default).
- `core/network/api_client.dart`: bearer auth, one refresh on 401, errors as `ApiException`. Tokens are **in memory only**, so closing the app signs the user out (the app has no secure storage yet, by decision).
- `core/providers/repository_providers.dart`: every repository is the API-backed one. Tests swap them for the doubles in `test/support/fakes/` through `fakeBackend()` (`test/support/fake_backend.dart`).
- The sign-up draft holds the password itself in memory until register. It is never stored or logged.
- Video plays through `video_player` from the resource's `stream_url`. The online/offline banner pings the API's `/health`. The school picker reads `/lookups/institutions`.

## Known gaps

- The FCU team's own queue (level 2) is worked in the back office, not in the app.
- Forgot password: the API emails a code but has no endpoint to set a new password with it yet.
- Profile photo is not uploaded at sign-up or edit (the post and report photos are; profile photos need the same call wired into the join form).
- Private reflections on devotionals are kept for the session only.
- Email delivery of notifications is not sent yet (in-app only).
- Push is local only: `core/push/push_service.dart` shows a phone notification (Android channel `fcu_general`) for each live `notification.created` while the app runs. Real push (app closed) needs a Firebase project, a server sender, and a `FirebasePushTokenSource`; `POST/DELETE /devices` registration is already wired.
- The live `presence.updated` online count is stored (`liveOnlineCountsProvider`) but the community header still shows the placeholder count.
- The school picker still uses the built-in list (`institution_data.dart`); names must exist in the API's institutions (the dev seed includes them, production needs them added in the back office).
- Android release builds need `https://` (or a network security config for plain `http://`).
- Notifications permission: the service and prompt exist (`AppPermission.notifications`) but nothing asks yet; B2.2 push should call `ensurePermission` before registering. The iOS `Podfile` (not in the repo yet) needs the permission_handler macros in `post_install` once generated.
