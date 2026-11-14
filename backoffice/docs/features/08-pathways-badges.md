# Pathways and badges

**Design boards:** B6, B21  
**BRD requirements:** FR-15, FR-20

## Problem it solves
Gives students a guided journey and visible progress, as an engagement tool.

## What the web app needs
- Pathways: list with status, step count, learners, locked-until info; editor with name, theme, level, ordered steps (drag), required flag, add step from library, unlock rule, badge awarded, publish or save draft
- Badges: table with rule, earned count, status; editor with name, description, rule, number needed, icon, visible on profile
- Rules in design: sign in and join a community, finish N quizzes, pray for N requests, complete a pathway, attend N meetings in a row

## Rules and edge cases
- Only published content can be added as a step
- Unpublishing content used in a pathway needs a warning
- Design notes badges are a proposal to check against the spiritual context

## To confirm
- Are badges and pathways in v1?
- Rule engine: who evaluates rules (backend)

## Files for this feature
- `src/app/(backoffice)/pathways/page.tsx`
- `src/app/(backoffice)/pathways/new/page.tsx`
- `src/app/(backoffice)/pathways/[id]/page.tsx`
- `src/app/(backoffice)/badges/page.tsx`
- `src/features/pathways/components/PathwayList.tsx`
- `src/features/pathways/components/PathwayEditor.tsx`
- `src/features/pathways/components/StepList.tsx`
- `src/features/pathways/components/AddStepDialog.tsx`
- `src/features/pathways/components/UnlockRuleSelect.tsx`
- `src/features/pathways/queries.ts`
- `src/features/pathways/schemas.ts`
- `src/features/badges/components/BadgeTable.tsx`
- `src/features/badges/components/BadgeForm.tsx`
- `src/features/badges/components/RuleSelect.tsx`
- `src/features/badges/components/IconPicker.tsx`
- `src/features/badges/queries.ts`
