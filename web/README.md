# FCU Student Community: web

The student-facing website: a landing page that explains the app and links to the mobile download, plus sign up, log in and a
dashboard for students who want to use it in a browser. It talks to the same API and uses the same accounts as the mobile app.

## Run locally

```bash
pnpm install
pnpm dev
```

Opens on http://localhost:3200 and expects the API on http://localhost:4000/v1.

## Configuration

Copy `.env.example` to `.env.local` and adjust:

| Variable | Purpose |
| --- | --- |
| `NEXT_PUBLIC_API_URL` | API base URL, including `/v1` |
| `NEXT_PUBLIC_ANDROID_URL` | Where "Download for Android" points. Empty hides the button. |
| `NEXT_PUBLIC_IOS_URL` | Where "Download for iPhone" points. Empty hides the button. |
| `NEXT_PUBLIC_SUPPORT_EMAIL` | Support address shown on the Help page. Empty hides it. |

In production the API must list this site's origin in `CORS_ORIGINS`.

## Pages

Public:

- `/` landing page. Signed-in students see "Dashboard" in place of "Log in" and "Sign up".
- `/signup`, `/login`
- `/forgot-password` sets a new password with a 6-digit code sent by email (`POST /auth/password/reset`)
- `/help`, `/charter`

Signed in (everything under `src/app/(app)`, wrapped by the navigation shell in `components/AppShell.tsx`):

- `/dashboard` home
- `/community` my communities, browse and ask to join a specific community
- `/community/[id]` feed, prayer wall, testimonies, resources, meetings, members; super-mentors also get Manage (join requests, reports)
- `/post/[id]`, `/prayer/[id]`, `/testimony/[id]`
- `/pathways`, `/pathways/[id]`, `/resources/[id]`, `/quiz/[id]`
- `/messages`, `/messages/[id]`
- `/notifications`, `/profile`, `/settings` (settings also confirms the email with a code)
- `/search` communities on campus and people in my communities

The paths match the routes the API puts in notifications where the mobile app has the same screen (`lib/format.ts` maps the rest).
Live updates use polling (messages every few seconds while a conversation is open), not the realtime socket.
