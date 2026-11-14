# Institutions and communities

**Design boards:** B3, B14, B15  
**BRD requirements:** FR-03

## Problem it solves
Every student belongs to an institution and a community; admins keep that structure correct and presentable.

## What the web app needs
- Institutions: name, type (university or high school), country, city, general community cover, shown in the sign-up list; counts of communities and students
- A general community is created automatically per institution
- Communities: general or specific, name, description, cover photo, meeting day, time and place, super-mentor, mentors, open for join requests, status
- Cover photos are managed only here (not in the mobile app), recommended 1600 x 600, JPG or PNG

## Rules and edge cases
- A student can join only one specific community
- Changing a super-mentor affects the scope of that person
- Cover upload needs crop and size validation
- Super-mentors can edit only meeting details of their own community; admins can do everything

## To confirm
- Who can create institutions?
- What happens to members when a community is closed?

## Files for this feature
- `src/app/(backoffice)/institutions/page.tsx`
- `src/app/(backoffice)/institutions/new/page.tsx`
- `src/app/(backoffice)/communities/page.tsx`
- `src/app/(backoffice)/communities/new/page.tsx`
- `src/app/(backoffice)/communities/[id]/page.tsx`
- `src/features/institutions/components/InstitutionTable.tsx`
- `src/features/institutions/components/InstitutionForm.tsx`
- `src/features/institutions/queries.ts`
- `src/features/institutions/schemas.ts`
- `src/features/communities/components/CommunityTable.tsx`
- `src/features/communities/components/CommunityForm.tsx`
- `src/features/communities/components/CoverPhotoUploader.tsx`
- `src/features/communities/components/MeetingFields.tsx`
- `src/features/communities/components/TeamPicker.tsx`
- `src/features/communities/queries.ts`
- `src/features/communities/schemas.ts`
