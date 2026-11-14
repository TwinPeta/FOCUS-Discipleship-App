/**
 * src/features/quiz/schemas.ts
 *
 * WHAT: Zod schema: at least one correct option per question, pass mark 0-100
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/07-quiz-builder.md
 * STATUS: implemented
 */

import { z } from "zod";

export const ShowAnswersMode = {
  AfterEach: "AFTER_EACH",
  AtEnd: "AT_END",
} as const;
export type ShowAnswersMode = (typeof ShowAnswersMode)[keyof typeof ShowAnswersMode];

export const quizOptionSchema = z.object({
  id: z.string().min(1),
  text: z.string().trim().min(1, "Option text cannot be empty"),
});

export const quizQuestionSchema = z
  .object({
    id: z.string().min(1),
    prompt: z.string().trim().min(3, "Question prompt is required"),
    options: z
      .array(quizOptionSchema)
      .min(2, "Each question must have at least two options"),
    correctOptionId: z.string().min(1, "Select the correct answer"),
    explanation: z.string().trim().optional().or(z.literal("")),
  })
  .refine(
    (q) => q.options.some((opt) => opt.id === q.correctOptionId),
    {
      message: "Correct answer must match one of the question options",
      path: ["correctOptionId"],
    },
  );

export const quizSchema = z.object({
  title: z.string().trim().min(2, "Quiz title is required"),
  bibleLink: z.string().trim().min(1, "Link a Bible character or text"),
  passMark: z
    .number({ invalid_type_error: "Pass mark must be a number" })
    .min(0, "Pass mark must be between 0 and 100")
    .max(100, "Pass mark must be between 0 and 100"),
  showAnswersMode: z
    .enum([ShowAnswersMode.AfterEach, ShowAnswersMode.AtEnd])
    .default(ShowAnswersMode.AtEnd),
  questions: z
    .array(quizQuestionSchema)
    .min(1, "Add at least one question to the quiz"),
});

export type QuizOption = z.infer<typeof quizOptionSchema>;
export type QuizQuestion = z.infer<typeof quizQuestionSchema>;
export type QuizInput = z.infer<typeof quizSchema>;
