# Super-mentor view

**Design boards:** B29  
**BRD requirements:** FR-03, FR-04, FR-05

## Problem it solves
Gives each community leader just what they need, and nothing from other communities.

## What the web app needs
- Home: community name, write to the group, KPIs (members, pending requests, reports to review, inactive members)
- Join requests with approve and decline; next meeting with edit details; members to follow up with Send reminder
- Nav: My community, Join requests, Members, Moderation (level 1), Resources
- Note: cover photos and community creation are managed by the admin team

## Rules and edge cases
- Strict scope: backend filters by the user's community; UI hides cross-community controls
- No access to exports, audit, settings or other communities
- Write to the group sends a notification to community members

## To confirm
- Can a super-mentor lead more than one community?
- Can mentors use this view?

## Files for this feature
- `src/app/(my-community)/layout.tsx`
- `src/app/(my-community)/my-community/page.tsx`
- `src/app/(my-community)/my-community/join-requests/page.tsx`
- `src/app/(my-community)/my-community/members/page.tsx`
- `src/app/(my-community)/my-community/moderation/page.tsx`
- `src/app/(my-community)/my-community/resources/page.tsx`
- `src/features/my-community/components/CommunityKpis.tsx`
- `src/features/my-community/components/PendingRequestsMini.tsx`
- `src/features/my-community/components/NextMeetingCard.tsx`
- `src/features/my-community/components/FollowUpList.tsx`
- `src/features/my-community/components/WriteToGroupDialog.tsx`
- `src/features/my-community/queries.ts`
