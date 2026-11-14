# Announcements and landing stories

**Design boards:** B8  
**BRD requirements:** -

## Problem it solves
Staff can reach communities and show real student voices on the app landing page.

## What the web app needs
- Announcements: audience (general community or a specific community), publish now or scheduled, title, message, image; recent list with status
- Landing stories: upload videos shown in 'Hear it from students', drag to reorder, visible toggle, student, institution and duration

## Rules and edge cases
- Get the student's written consent before publishing a story
- Announcement audience for super-mentors is limited to their community
- Story video upload reuses the resumable uploader

## To confirm
- How is story consent recorded?
- Can announcements target all institutions?

## Files for this feature
- `src/app/(backoffice)/announcements/page.tsx`
- `src/features/announcements/components/AnnouncementForm.tsx`
- `src/features/announcements/components/AnnouncementList.tsx`
- `src/features/announcements/queries.ts`
- `src/features/stories/components/StoryList.tsx`
- `src/features/stories/components/StoryUploader.tsx`
- `src/features/stories/components/ConsentReminder.tsx`
- `src/features/stories/queries.ts`
