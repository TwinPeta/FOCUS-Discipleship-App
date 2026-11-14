/**
 * src/features/quiz/components/QuestionEditor.tsx
 *
 * WHAT: Single quiz question editor (prompt, options, correct answer, optional explanation)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/07-quiz-builder.md
 * STATUS: implemented
 */

"use client";

import type { QuizQuestion } from "@/features/quiz/schemas";
import { OptionList } from "./OptionList";

interface QuestionEditorProps {
  index: number;
  question: QuizQuestion;
  canRemove: boolean;
  onChange: (updated: QuizQuestion) => void;
  onRemove: () => void;
}

export function QuestionEditor({
  index,
  question,
  canRemove,
  onChange,
  onRemove,
}: QuestionEditorProps) {
  return (
    <div className="space-y-4 rounded-card border border-border bg-white p-5">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-foreground">
          Question {index + 1}
        </h3>
        {canRemove && (
          <button
            type="button"
            onClick={onRemove}
            className="text-xs text-red-700 hover:underline"
          >
            Remove question
          </button>
        )}
      </div>

      <div className="space-y-1.5">
        <label
          htmlFor={`q-prompt-${question.id}`}
          className="block text-sm font-medium text-foreground"
        >
          Question prompt
        </label>
        <input
          id={`q-prompt-${question.id}`}
          type="text"
          value={question.prompt}
          onChange={(e) => onChange({ ...question, prompt: e.target.value })}
          placeholder="Ask a clear question..."
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <OptionList
        questionId={question.id}
        options={question.options}
        correctOptionId={question.correctOptionId}
        onChange={(options, correctOptionId) =>
          onChange({ ...question, options, correctOptionId })
        }
      />

      <div className="space-y-1.5">
        <label
          htmlFor={`q-exp-${question.id}`}
          className="block text-xs font-medium text-muted-foreground"
        >
          Explanation (optional)
        </label>
        <input
          id={`q-exp-${question.id}`}
          type="text"
          value={question.explanation ?? ""}
          onChange={(e) => onChange({ ...question, explanation: e.target.value })}
          placeholder="Shown to the student with the correct answer..."
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm"
        />
      </div>
    </div>
  );
}
