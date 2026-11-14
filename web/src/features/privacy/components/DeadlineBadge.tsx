/**
 * src/features/privacy/components/DeadlineBadge.tsx
 *
 * WHAT: 30-day legal deadline badge with overdue, due-soon, and completed states
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

import { RequestStatus } from "@/types/enums";

interface DeadlineBadgeProps {
  deadlineAt: string;
  status: RequestStatus;
}

export function DeadlineBadge({ deadlineAt, status }: DeadlineBadgeProps) {
  if (status === RequestStatus.Done) {
    return (
      <span className="inline-flex rounded-full bg-emerald-100 px-2.5 py-0.5 text-xs font-medium text-emerald-800">
        Completed
      </span>
    );
  }

  const now = new Date();
  const deadline = new Date(deadlineAt);
  const diffDays = Math.ceil(
    (deadline.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
  );

  if (Number.isNaN(diffDays)) {
    return <span className="text-xs text-muted-foreground">{deadlineAt}</span>;
  }

  if (diffDays < 0) {
    return (
      <span className="inline-flex rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-semibold text-red-800">
        Overdue ({Math.abs(diffDays)}d)
      </span>
    );
  }

  if (diffDays <= 5) {
    return (
      <span className="inline-flex rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-semibold text-amber-900">
        Due in {diffDays}d
      </span>
    );
  }

  return (
    <span className="inline-flex rounded-full bg-stone-100 px-2.5 py-0.5 text-xs font-medium text-stone-800">
      {diffDays}d left
    </span>
  );
}
