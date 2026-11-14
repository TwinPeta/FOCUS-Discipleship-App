# Quiz builder

**Design boards:** B13  
**BRD requirements:** FR-01

## Problem it solves
Lets content admins create quizzes tied to a Bible character or text that feed member activity.

## What the web app needs
- Details: title, linked Bible character or text, pass mark percent, show correct answers (after each question or at the end)
- Questions with multiple options, one correct answer, optional explanation; add question and option
- Summary: question count, estimated minutes, pass mark; results are logged in each member's activity
- Same publishing card and workflow as other content

## Rules and edge cases
- Every question needs at least two options and one correct answer
- Pass mark between 0 and 100
- Reordering questions (nice to have)

## To confirm
- Question types beyond single choice?
- Retake rules

## Files for this feature
- `src/features/quiz/components/QuizBuilder.tsx`
- `src/features/quiz/components/QuestionEditor.tsx`
- `src/features/quiz/components/OptionList.tsx`
- `src/features/quiz/components/QuizSettings.tsx`
- `src/features/quiz/components/QuizSummary.tsx`
- `src/features/quiz/schemas.ts`
