/**
 * src/features/quiz/components/QuizSummary.tsx
 *
 * WHAT: Live summary card: question count, estimated minutes, pass mark
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/07-quiz-builder.md
 * STATUS: implemented
 */

interface QuizSummaryProps {
  questionCount: number;
  passMark: number;
}

export function QuizSummary({ questionCount, passMark }: QuizSummaryProps) {
  const estimatedMinutes = Math.max(1, Math.ceil(questionCount * 1.5));

  return (
    <div className="grid grid-cols-3 gap-3 rounded-card border border-border bg-primary-soft p-4 text-center text-sm">
      <div>
        <p className="text-lg font-bold text-foreground">{questionCount}</p>
        <p className="text-xs text-muted-foreground">Questions</p>
      </div>
      <div>
        <p className="text-lg font-bold text-foreground">~{estimatedMinutes} min</p>
        <p className="text-xs text-muted-foreground">Estimated</p>
      </div>
      <div>
        <p className="text-lg font-bold text-foreground">{passMark}%</p>
        <p className="text-xs text-muted-foreground">Pass mark</p>
      </div>
    </div>
  );
}
