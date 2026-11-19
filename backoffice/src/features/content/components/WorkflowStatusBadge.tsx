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
  [ContentStatus.Draft]: "bg-[#F5F6F8] text-muted-foreground",
  [ContentStatus.InReview]: "bg-primary-soft text-ink",
  [ContentStatus.Published]: "bg-blue-soft text-ink",
  [ContentStatus.Archived]: "bg-[#F5F6F8] text-muted-foreground",
};

export function WorkflowStatusBadge({ status }: { status: ContentStatus }) {
  return <span className={`chip ${STYLES[status]}`}>{LABELS[status]}</span>;
}
