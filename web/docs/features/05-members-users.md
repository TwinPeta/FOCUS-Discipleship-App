# Members, add user and import

**Design boards:** B4, B11, B24  
**BRD requirements:** FR-07, FR-10

## Problem it solves
Staff need to find, create and correct member accounts, and protect personal data and minors while doing so.

## What the web app needs
- Members: role tabs with counts (all, students, mentors, super-mentors, alumni), search, campus and status filters, last active, status (active, inactive, suspended, invited)
- Detail panel: contact, birthdate, minor flag with guardian consent, communities, participation (resources, meetings, badges); actions: change role, move community, suspend
- Add user: role, profile, institution, under-18 guardian consent checkbox, communities, optional invitation email
- Import: upload CSV, match columns (full name, email, phone, institution, community, role), review rows with problems, import

## Rules and edge cases
- Viewing personal data is recorded in the audit log
- Invited status until the user sets a password
- Import must be safe to retry and report duplicates
- Minors: guardian consent required before the account is fully active (rule from settings)

## To confirm
- CSV duplicate handling and default role
- Can system admins change roles of other system admins?

## Files for this feature
- `src/app/(backoffice)/members/page.tsx`
- `src/app/(backoffice)/members/new/page.tsx`
- `src/app/(backoffice)/members/import/page.tsx`
- `src/app/(backoffice)/members/[id]/page.tsx`
- `src/features/members/components/MemberTable.tsx`
- `src/features/members/components/MemberFilters.tsx`
- `src/features/members/components/MemberDetailPanel.tsx`
- `src/features/members/components/ChangeRoleDialog.tsx`
- `src/features/members/components/MoveCommunityDialog.tsx`
- `src/features/members/components/SuspendDialog.tsx`
- `src/features/members/components/AddUserForm.tsx`
- `src/features/members/components/RoleSelector.tsx`
- `src/features/members/components/MinorBadge.tsx`
- `src/features/members/queries.ts`
- `src/features/members/schemas.ts`
- `src/features/import/components/ImportStepper.tsx`
- `src/features/import/components/UploadStep.tsx`
- `src/features/import/components/MapColumnsStep.tsx`
- `src/features/import/components/ReviewStep.tsx`
- `src/features/import/components/RunStep.tsx`
- `src/features/import/csv.ts`
- `src/features/import/queries.ts`
