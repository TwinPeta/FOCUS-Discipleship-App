# Join requests

**Design boards:** B2  
**BRD requirements:** FR-03

## Problem it solves
Students request a specific community; a human approves, keeping groups guided and safe.

## What the web app needs
- Tabs: pending, approved, declined with counts; search, community and campus filters
- Table: applicant (username, institution), requested community, requested date, current-community note
- Approve and decline per row; approve selected in bulk; export
- Rule notice: one specific community per student; super-mentors see only their own community

## Rules and edge cases
- Conflict: student already in another community shows as 'Already in X'; bulk approve skips or flags conflicts
- Approval and decline trigger notifications (see 10-notifications)
- Approvals are audited

## To confirm
- Can a decline carry a reason?
- Can a student have a pending request elsewhere while approved?

## Files for this feature
- `src/app/(backoffice)/join-requests/page.tsx`
- `src/features/join-requests/components/JoinRequestTable.tsx`
- `src/features/join-requests/components/BulkApproveBar.tsx`
- `src/features/join-requests/components/ConflictBadge.tsx`
- `src/features/join-requests/components/DeclineDialog.tsx`
- `src/features/join-requests/components/RuleNotice.tsx`
- `src/features/join-requests/queries.ts`
