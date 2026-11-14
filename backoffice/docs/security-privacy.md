# Security and privacy (back office)

- Tokens live in httpOnly, Secure, SameSite cookies set by the proxy route; never in localStorage.
- Browser calls go through `/api/proxy`; no backend URL or secrets reach the client.
- Security headers in `next.config.ts` (add CSP once upload and media hosts are known).
- Staff only: students and mentors cannot sign in; super-mentors are scope-locked.
- Personal data: viewing a member's details, exporting, sanctioning, approving and publishing are audited by the backend; the UI shows `AuditNotice`.
- No personal data in URLs or analytics; use ids. Structured logs carry a correlation id.
- Sentry must not capture personal text (scrub bodies and message content).
- Minors: guardian consent tracking, limits on contact with unverified adults, configured in settings.
- Password rules: at least 10 characters, a letter and a number, not one of the last passwords; reset links are single-use and expire in 1 hour.
- Validate return-to URLs (no open redirects); CSRF protection for cookie-authenticated mutations (SameSite plus token if needed).
- Video and image uploads: validate type and size client-side, but the backend must re-validate and scan.
