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
| Feed: posts, questions, likes, comments, photo upload, search | Real. "Hide this post" and "Pass" on a question are saved on the server for that member only (`/posts/{id}/hide`, `/posts/{id}/pass`) |
| Prayer wall (requests, "I prayed", replies) | Real. The server keeps anonymous authors anonymous, including replies by the owner |
| Testimonies (share a story, review status, "Encouraged") | Real. "Encouraged" is one per member on published stories (`/testimonies/{id}/encourage`) |
| Resources, quizzes (scored on the server), pathways, My activity and badges, landing stories | Real. Quiz answers are not revealed after each question (the server never sends them); the last attempt and the member's own choices come back with the quiz. Private reflections on devotionals are kept on the server (`/resources/{id}/reflection`). Documents open from their real link in the phone's viewer |
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
- Search for communities and people is done in the app over `/communities` and the member lists (it only finds people in the member's own communities); posts are searched by the server (`/search/posts`).
- Students cannot upload documents (staff add them in the back office).
- Android release builds need `https://` (or a network security config for plain `http://`).
- The iOS `Podfile` (not in the repo yet) needs the permission_handler macros in `post_install` once generated.
