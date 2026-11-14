# Moderation

**Design boards:** B7, B16, B17, B18  
**BRD requirements:** FR-09

## Problem it solves
Keeps communities safe through two levels of review with a full trail.

## What the web app needs
- Tabs with counts and community filter: reports, testimonies, prayer and posts, sanctions
- Reports: reason, reporter, reported user, community, details, screenshot, earlier reports; actions dismiss, warn, hide content, escalate, suspend
- Testimonies: full story and video, student agreement, notes; approve and publish, request changes, reject
- Prayer requests, feed posts, comments: content as members see it, report list; keep, hide, warn author, escalate
- Sanctions: user, sanction (warning or suspension), reason, date, by whom, reinstate, details

## Rules and edge cases
- Level 1 (super-mentors and mentors): hide a message, warn. Level 2 (admins): suspend, delete permanently
- Every sanction keeps reason, author and date; all actions audited
- Super-mentors see only their community's items
- A report about a super-mentor must go to an admin

## To confirm
- Can content admin suspend or delete?
- Do mentors have back office access?

## Files for this feature
- `src/app/(backoffice)/moderation/layout.tsx`
- `src/app/(backoffice)/moderation/page.tsx`
- `src/app/(backoffice)/moderation/reports/page.tsx`
- `src/app/(backoffice)/moderation/testimonies/page.tsx`
- `src/app/(backoffice)/moderation/posts/page.tsx`
- `src/app/(backoffice)/moderation/sanctions/page.tsx`
- `src/features/moderation/components/CommunityFilter.tsx`
- `src/features/moderation/components/ModerationTabs.tsx`
- `src/features/moderation/components/ReportQueue.tsx`
- `src/features/moderation/components/ReportDetail.tsx`
- `src/features/moderation/components/TestimonyQueue.tsx`
- `src/features/moderation/components/TestimonyReview.tsx`
- `src/features/moderation/components/PostQueue.tsx`
- `src/features/moderation/components/PostReview.tsx`
- `src/features/moderation/components/SanctionsTable.tsx`
- `src/features/moderation/components/ReinstateDialog.tsx`
- `src/features/moderation/components/ModerationActions.tsx`
- `src/features/moderation/components/EscalationInfo.tsx`
- `src/features/moderation/queries.ts`
- `src/features/moderation/schemas.ts`
