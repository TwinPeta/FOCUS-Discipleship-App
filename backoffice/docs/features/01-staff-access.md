# Staff access and account

**Design boards:** B10, B25, B27, B28  
**BRD requirements:** FR-07

## Problem it solves
Only authorised staff reach personal data. Sign-ins are recorded in the audit log.

## What the web app needs
- Login: work email, password, keep me signed in, forgot password link
- Forgot password: work email, send link, generic confirmation
- Reset password: single-use link that expires after 1 hour; rules: at least 10 characters, a letter and a number, different from last passwords
- My account: edit name and photo, change password, list of devices with sign-out
- Roles that can sign in: super-mentor, content admin, system admin

## Rules and edge cases
- Generic messages: no account enumeration; expired or used link gets a clear screen and a way to request a new one
- Suspended staff see an explanation, not a blank error
- Return-to URLs validated (no open redirects)
- Super-mentors are redirected to /my-community, others to /dashboard

## To confirm
- Two-factor sign-in for staff?
- Who creates staff accounts and how are they invited?

## Files for this feature
- `src/app/page.tsx`
- `src/app/(auth)/layout.tsx`
- `src/app/(auth)/login/page.tsx`
- `src/app/(auth)/forgot-password/page.tsx`
- `src/app/(auth)/reset-password/page.tsx`
- `src/app/(backoffice)/account/page.tsx`
- `src/features/auth/components/LoginForm.tsx`
- `src/features/auth/components/ForgotPasswordForm.tsx`
- `src/features/auth/components/ResetPasswordForm.tsx`
- `src/features/auth/components/PasswordRules.tsx`
- `src/features/auth/password-rules.ts`
- `src/features/auth/hooks/useSession.ts`
- `src/features/auth/schemas.ts`
- `src/features/account/components/ProfileForm.tsx`
- `src/features/account/components/ChangePasswordForm.tsx`
- `src/features/account/components/SessionsList.tsx`
- `src/features/account/queries.ts`
- `src/lib/auth/session.ts`
- `src/lib/auth/cookies.ts`
- `src/lib/auth/guards.ts`
- `src/lib/auth/redirects.ts`
- `src/middleware.ts`
- `src/app/api/proxy/[...path]/route.ts`
- `src/app/api/health/route.ts`
