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

In production the API must list this site's origin in `CORS_ORIGINS`.

## Pages

- `/` landing page. Signed-in students see "Dashboard" in place of "Log in" and "Sign up".
- `/signup`, `/login`
- `/dashboard` communities, latest campus posts, current pathway, notifications (read-only for now)
