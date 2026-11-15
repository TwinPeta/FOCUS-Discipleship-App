# Connecting the app to the backend

The app runs on **fake data by default** (tests, offline demo). Give it the API address at build time and it switches to the real backend:

```bash
# Android emulator talking to the API on your Mac
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/v1
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:4000/v1
# Phone testing / release against the server
flutter build apk --dart-define=API_BASE_URL=https://apis.focusuganda.org/v1
```

Start the API with `SEED_DEMO_DATA=true` (see `api/README.md`) for demo accounts, e.g. `student@fcu.test` (or username `gracen`) with `Password123!`.

## What is connected

| Area | Status |
|---|---|
| Sign in / out, session refresh, sign-up, profile, guardian, delete account | Real |
| Communities, members, membership (request, leave, result screens), join requests (super-mentor) | Real. The role (student / mentor / super-mentor) comes from the community's leadership list |
| Feed: posts, likes, comments, photo upload | Real. "Hide this post" is kept on the device only |
| Prayer wall (requests, "I prayed", replies) | Real. The server keeps anonymous authors anonymous, including replies by the owner |
| Testimonies (share a story, review status) | Real. The "Encouraged" tap is remembered for this session only (no API yet) |
| Resources, quizzes (scored on the server), pathways, My activity and badges, landing stories | Real. Quiz answers are not revealed after each question (the server never sends them) |
| Messaging (inbox, conversations, under-18 limit), blocking, reports, data export | Real. New messages appear when a screen loads (no live socket yet) |
| Notifications and their settings | Real. The server creates them (request decided, someone prayed, a reply, a response) |
| Meetings: next meeting and history, RSVP, check-in | Real. Meetings are derived from the community's weekly schedule; check-in is open from 30 min before to 2 h after, judged by the **server's** clock |
| Mentor moderation ("Reports to review"): keep, hide, warn author, escalate | Real. Reports on the same item form one case. Escalated cases go to the back office queue |
| Warnings and suspension | Real. Warning someone hides the content, records the warning and notifies them. A suspended account is read-only; a suspension without an end date lasts 7 days |

## How it is wired

- `core/config/api_config.dart`: `API_BASE_URL` switch.
- `core/network/api_client.dart`: bearer auth, one refresh on 401, errors as `ApiException`. Tokens are **in memory only**, so closing the app signs the user out (the app has no secure storage yet, by decision).
- `core/providers/repository_providers.dart`: picks the fake or remote repository. Tests keep using the fakes.
- When the backend is on, the sign-up draft holds the password itself in memory until register (the fake backend holds a digest instead). It is never stored or logged.

## Known gaps

- The FCU team's own queue (level 2) is worked in the back office, not in the app.
- Forgot password: the API emails a code but has no endpoint to set a new password with it yet.
- Profile photo is not uploaded at sign-up or edit (the post and report photos are; profile photos need the same call wired into the join form).
- Private reflections on devotionals are kept for the session only.
- Email delivery of notifications is not sent yet (in-app only).
- The school picker still uses the built-in list (`institution_data.dart`); names must exist in the API's institutions (the dev seed includes them, production needs them added in the back office).
- Android release builds need `https://` (or a network security config for plain `http://`).
