# Settings: charter, consent, minors, retention

**Design boards:** B19  
**BRD requirements:** FR-10

## Problem it solves
Lets FOCUS control legal text and rules without a developer release.

## What the web app needs
- Charter: text shown at sign-up, require acceptance, ask again when it changes, version and date
- Consent texts: creating an account, taking part in community spaces, being contacted by a mentor
- Users under 18: age threshold (18), guardian consent required, limit direct messages with unverified adults, mentors must be verified before contacting a student
- Data retention: keep inactive accounts for N months (24), answer deletion requests within N days (30)

## Rules and edge cases
- Versioning of charter and consent texts; the app forces re-acceptance when configured
- Changing the age threshold affects existing users (needs a warning)
- All changes audited

## To confirm
- Who may edit legal texts?
- Language versions of consent texts

## Files for this feature
- `src/app/(backoffice)/settings/page.tsx`
- `src/features/settings/components/CharterForm.tsx`
- `src/features/settings/components/ConsentTextsForm.tsx`
- `src/features/settings/components/MinorsForm.tsx`
- `src/features/settings/components/RetentionForm.tsx`
- `src/features/settings/queries.ts`
- `src/features/settings/schemas.ts`
