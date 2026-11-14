/**
 * src/features/quiz/components/OptionList.tsx
 *
 * WHAT: Answer options list with single-correct radio selection and add/remove controls
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/07-quiz-builder.md
 * STATUS: implemented
 */

"use client";

import type { QuizOption } from "@/features/quiz/schemas";

interface OptionListProps {
  questionId: string;
  options: QuizOption[];
  correctOptionId: string;
  onChange: (options: QuizOption[], correctOptionId: string) => void;
}

export function OptionList({
  questionId,
  options,
  correctOptionId,
  onChange,
}: OptionListProps) {
  function updateOptionText(id: string, text: string) {
    onChange(
      options.map((opt) => (opt.id === id ? { ...opt, text } : opt)),
      correctOptionId,
    );
  }

  function addOption() {
    const newId = `opt-${Date.now()}-${options.length + 1}`;
    onChange([...options, { id: newId, text: "" }], correctOptionId);
  }

  function removeOption(id: string) {
    const next = options.filter((opt) => opt.id !== id);
    const nextCorrect = correctOptionId === id ? "" : correctOptionId;
    onChange(next, nextCorrect);
  }

  return (
    <div className="space-y-2">
      <p className="text-xs font-medium text-muted-foreground">
        Options (select the one correct answer)
      </p>

      {options.map((opt, idx) => (
        <div key={opt.id} className="flex items-center gap-2">
          <input
            type="radio"
            name={`correct-${questionId}`}
            checked={correctOptionId === opt.id}
            onChange={() => onChange(options, opt.id)}
            aria-label={`Mark option ${idx + 1} as correct`}
            className="h-4 w-4 accent-primary"
          />
          <input
            type="text"
            value={opt.text}
            onChange={(e) => updateOptionText(opt.id, e.target.value)}
            placeholder={`Option ${idx + 1}`}
            aria-label={`Option ${idx + 1} text`}
            className="flex-1 rounded-md border border-border bg-white px-3 py-1.5 text-sm"
          />
          {options.length > 2 && (
            <button
              type="button"
              onClick={() => removeOption(opt.id)}
              className="rounded border border-border px-2 py-1 text-xs text-muted-foreground hover:text-foreground"
            >
              Remove
            </button>
          )}
        </div>
      ))}

      <button
        type="button"
        onClick={addOption}
        className="text-xs font-medium text-foreground underline underline-offset-2"
      >
        + Add option
      </button>
    </div>
  );
}
