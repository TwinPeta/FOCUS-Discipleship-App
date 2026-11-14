/**
 * src/features/content/components/WorkflowStatusBadge.tsx
 *
 * WHAT: Status badge for content workflow states (Draft, In review, Published, Archived)
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import { ContentStatus } from "@/types/enums";

const LABELS: Record<ContentStatus, string> = {
  [ContentStatus.Draft]: "Draft",
  [ContentStatus.InReview]: "In review",
  [ContentStatus.Published]: "Published",
  [ContentStatus.Archived]: "Archived",
};

const STYLES: Record<ContentStatus, string> = {
  [ContentStatus.Draft]: "bg-stone-100 text-stone-800",
  [ContentStatus.InReview]: "bg-amber-100 text-amber-900",
  [ContentStatus.Published]: "bg-emerald-100 text-emerald-800",
  [ContentStatus.Archived]: "bg-zinc-200 text-zinc-700",
};

export function WorkflowStatusBadge({ status }: { status: ContentStatus }) {
  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${STYLES[status]}`}
    >
      {LABELS[status]}
    </span>
  );
}
