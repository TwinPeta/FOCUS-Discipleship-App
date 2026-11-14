/**
 * src/features/quiz/components/QuizSettings.tsx
 *
 * WHAT: Quiz title, linked Bible character/text, pass mark (0-100), and answer reveal mode
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/07-quiz-builder.md
 * STATUS: implemented
 */

"use client";

import { BibleLinkSelect } from "@/features/bible/components/BibleLinkSelect";
import { ShowAnswersMode } from "@/features/quiz/schemas";

interface QuizSettingsProps {
  title: string;
  onTitleChange: (v: string) => void;
  bibleLink: string;
  onBibleLinkChange: (v: string) => void;
  passMark: number;
  onPassMarkChange: (v: number) => void;
  showAnswersMode: ShowAnswersMode;
  onShowAnswersModeChange: (v: ShowAnswersMode) => void;
}

export function QuizSettings({
  title,
  onTitleChange,
  bibleLink,
  onBibleLinkChange,
  passMark,
  onPassMarkChange,
  showAnswersMode,
  onShowAnswersModeChange,
}: QuizSettingsProps) {
  return (
    <div className="space-y-4 rounded-card border border-border bg-white p-5">
      <h2 className="text-base font-semibold text-foreground">Quiz details</h2>

      <div className="space-y-1.5">
        <label htmlFor="quiz-title" className="block text-sm font-medium text-foreground">
          Quiz title
        </label>
        <input
          id="quiz-title"
          type="text"
          value={title}
          onChange={(e) => onTitleChange(e.target.value)}
          placeholder="e.g. Life of David — Faithfulness"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="space-y-1.5">
          <label htmlFor="quiz-bible-link" className="block text-sm font-medium text-foreground">
            Bible character or text
          </label>
          <BibleLinkSelect
            id="quiz-bible-link"
            value={bibleLink}
            onChange={onBibleLinkChange}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="quiz-pass-mark" className="block text-sm font-medium text-foreground">
            Pass mark (%)
          </label>
          <input
            id="quiz-pass-mark"
            type="number"
            min={0}
            max={100}
            value={Number.isNaN(passMark) ? "" : passMark}
            onChange={(e) => onPassMarkChange(Number(e.target.value))}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="quiz-show-answers" className="block text-sm font-medium text-foreground">
            Show correct answers
          </label>
          <select
            id="quiz-show-answers"
            value={showAnswersMode}
            onChange={(e) => onShowAnswersModeChange(e.target.value as ShowAnswersMode)}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          >
            <option value={ShowAnswersMode.AtEnd}>At the end</option>
            <option value={ShowAnswersMode.AfterEach}>After each question</option>
          </select>
        </div>
      </div>
    </div>
  );
}
