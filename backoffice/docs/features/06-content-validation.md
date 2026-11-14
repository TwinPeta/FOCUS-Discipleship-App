# Content library and validation

**Design boards:** B5, B12  
**BRD requirements:** FR-01, FR-08

## Problem it solves
Prevents inconsistent or polarized teaching by requiring validation before anything is shown in the app.

## What the web app needs
- Library: status tabs (all, draft, in review, published, archived) with counts; search by title or Bible character or text; filters by type and Bible link
- New content: type switch (video, devotional, quiz, document); details: title, linked Bible character or text, language, tags, description
- Video: upload up to 500 MB (lighter versions created automatically), optional thumbnail
- Publishing: status, author, validator (pastor or committee), add to pathway, submit for review, save draft
- Review panel: workflow, reviewer notes, approve and publish, request changes
- Published content keeps author, validator and validation date

## Rules and edge cases
- Draft to in review to published; request changes returns to draft with notes
- Editing published content should create a new version that is reviewed again (confirm)
- Large uploads need resume, progress and failure handling
- Shown in the app under resources and the linked Bible character or text

## To confirm
- Validator model (user or recorded name)?
- Upload protocol and hosting
- Source of Bible characters and texts

## Files for this feature
- `src/app/(backoffice)/content/page.tsx`
- `src/app/(backoffice)/content/new/page.tsx`
- `src/app/(backoffice)/content/[id]/page.tsx`
- `src/features/content/components/ContentTable.tsx`
- `src/features/content/components/ContentFilters.tsx`
- `src/features/content/components/ContentTypeSwitch.tsx`
- `src/features/content/components/ReviewPanel.tsx`
- `src/features/content/components/WorkflowStatusBadge.tsx`
- `src/features/content/components/ApprovalTrail.tsx`
- `src/features/content/components/ValidatorField.tsx`
- `src/features/content/components/DetailsFields.tsx`
- `src/features/content/components/VideoForm.tsx`
- `src/features/content/components/VideoUploader.tsx`
- `src/features/content/components/ThumbnailUploader.tsx`
- `src/features/content/components/DevotionalForm.tsx`
- `src/features/content/components/DocumentForm.tsx`
- `src/features/content/components/PathwayPicker.tsx`
- `src/features/content/components/PublishingCard.tsx`
- `src/features/content/workflow.ts`
- `src/features/content/queries.ts`
- `src/features/content/schemas.ts`
- `src/features/bible/components/BibleLinkSelect.tsx`
- `src/features/bible/queries.ts`
