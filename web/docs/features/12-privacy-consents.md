# Consents and data requests

**Design boards:** B23  
**BRD requirements:** FR-10

## Problem it solves
Meets legal duties for minors and personal data rights (Uganda Data Protection and Privacy Act 2019).

## What the web app needs
- Guardian consents: student, guardian, status (received or pending), date; view and send reminder
- Data requests: member, type (export or deletion), requested date, deadline, status (open, in progress, done); process action

## Rules and edge cases
- Deadline of 30 days (setting) with overdue state
- Exports and deletions are audited
- Deletion needs a confirmation and clarity on what is kept (for example audit entries)

## To confirm
- How is guardian consent collected and verified?
- Retention after deletion for legal reasons

## Files for this feature
- `src/app/(backoffice)/privacy/layout.tsx`
- `src/app/(backoffice)/privacy/page.tsx`
- `src/app/(backoffice)/privacy/guardian-consents/page.tsx`
- `src/app/(backoffice)/privacy/data-requests/page.tsx`
- `src/features/privacy/components/GuardianConsentTable.tsx`
- `src/features/privacy/components/DataRequestsTable.tsx`
- `src/features/privacy/components/ProcessRequestDialog.tsx`
- `src/features/privacy/components/DeadlineBadge.tsx`
- `src/features/privacy/queries.ts`
