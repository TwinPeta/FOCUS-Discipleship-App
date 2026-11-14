/**
 * src/features/quiz/components/QuizBuilder.tsx
 *
 * WHAT: Full quiz builder with Zod validation (pass mark 0-100, >=2 options and 1 correct option per question)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/07-quiz-builder.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import {
  quizSchema,
  ShowAnswersMode,
  type QuizInput,
  type QuizQuestion,
} from "@/features/quiz/schemas";
import { QuestionEditor } from "./QuestionEditor";
import { QuizSettings } from "./QuizSettings";
import { QuizSummary } from "./QuizSummary";

interface QuizBuilderProps {
  onSave?: (quiz: QuizInput) => Promise<void>;
}

function createEmptyQuestion(index: number): QuizQuestion {
  const ts = Date.now() + index;
  return {
    id: `q-${ts}`,
    prompt: "",
    options: [
      { id: `opt-${ts}-1`, text: "" },
      { id: `opt-${ts}-2`, text: "" },
    ],
    correctOptionId: "",
    explanation: "",
  };
}

export function QuizBuilder({ onSave }: QuizBuilderProps) {
  const [title, setTitle] = useState("");
  const [bibleLink, setBibleLink] = useState("");
  const [passMark, setPassMark] = useState<number>(70);
  const [showAnswersMode, setShowAnswersMode] = useState<ShowAnswersMode>(
    ShowAnswersMode.AtEnd,
  );
  const [questions, setQuestions] = useState<QuizQuestion[]>([
    createEmptyQuestion(1),
  ]);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);
  const [saved, setSaved] = useState(false);

  function addQuestion() {
    setQuestions((prev) => [...prev, createEmptyQuestion(prev.length + 1)]);
  }

  async function handleSave() {
    setSaved(false);
    const parsed = quizSchema.safeParse({
      title,
      bibleLink,
      passMark,
      showAnswersMode,
      questions,
    });

    if (!parsed.success) {
      setValidationErrors(parsed.error.issues.map((i) => i.message));
      return;
    }

    setValidationErrors([]);
    await onSave?.(parsed.data);
    setSaved(true);
  }

  return (
    <div className="space-y-6">
      <QuizSummary
        questionCount={questions.length}
        passMark={Number.isNaN(passMark) ? 0 : passMark}
      />

      {validationErrors.length > 0 && (
        <div
          role="alert"
          className="space-y-1 rounded-md border border-red-300 bg-red-50 p-4 text-sm text-red-800"
        >
          <p className="font-semibold">Please fix the following before saving:</p>
          <ul className="list-disc pl-5 text-xs">
            {validationErrors.map((err, idx) => (
              <li key={idx}>{err}</li>
            ))}
          </ul>
        </div>
      )}

      {saved && (
        <div
          role="status"
          className="rounded-md border border-emerald-300 bg-emerald-50 px-4 py-3 text-sm text-emerald-900"
        >
          Quiz saved.
        </div>
      )}

      <QuizSettings
        title={title}
        onTitleChange={setTitle}
        bibleLink={bibleLink}
        onBibleLinkChange={setBibleLink}
        passMark={passMark}
        onPassMarkChange={setPassMark}
        showAnswersMode={showAnswersMode}
        onShowAnswersModeChange={setShowAnswersMode}
      />

      <div className="space-y-4">
        {questions.map((q, idx) => (
          <QuestionEditor
            key={q.id}
            index={idx}
            question={q}
            canRemove={questions.length > 1}
            onChange={(updated) =>
              setQuestions((prev) =>
                prev.map((item) => (item.id === q.id ? updated : item)),
              )
            }
            onRemove={() =>
              setQuestions((prev) => prev.filter((item) => item.id !== q.id))
            }
          />
        ))}
      </div>

      <div className="flex flex-wrap items-center justify-between gap-3">
        <button
          type="button"
          onClick={addQuestion}
          className="rounded-md border border-border bg-white px-4 py-2 text-sm font-medium hover:bg-surface"
        >
          + Add question
        </button>

        <button
          type="button"
          onClick={handleSave}
          className="rounded-md bg-primary px-5 py-2 text-sm font-semibold text-foreground hover:brightness-95"
        >
          Save quiz
        </button>
      </div>
    </div>
  );
}
