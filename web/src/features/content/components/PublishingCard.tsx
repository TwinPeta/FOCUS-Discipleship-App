/**
 * src/features/content/components/PublishingCard.tsx
 *
 * WHAT: Publishing sidebar card: status, author, validator, pathways, save draft & submit for review
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { ContentStatus } from "@/types/enums";
import { PathwayPicker } from "./PathwayPicker";
import { ValidatorField } from "./ValidatorField";
import { WorkflowStatusBadge } from "./WorkflowStatusBadge";

interface PublishingCardProps {
  status: ContentStatus;
  authorName: string;
  validatorName: string;
  onValidatorChange: (v: string) => void;
  pathwayIds: string[];
  onPathwaysChange: (ids: string[]) => void;
  isSubmitting?: boolean;
  onSaveDraft: () => void;
  onSubmitForReview: () => void;
}

export function PublishingCard({
  status,
  authorName,
  validatorName,
  onValidatorChange,
  pathwayIds,
  onPathwaysChange,
  isSubmitting = false,
  onSaveDraft,
  onSubmitForReview,
}: PublishingCardProps) {
  return (
    <aside className="space-y-4 rounded-card border border-border bg-white p-5">
      <div className="flex items-center justify-between">
        <h2 className="text-base font-semibold text-foreground">Publishing</h2>
        <WorkflowStatusBadge status={status} />
      </div>

      <p className="text-xs text-muted-foreground">
        Author: <strong className="text-foreground">{authorName}</strong>
      </p>

      <ValidatorField value={validatorName} onChange={onValidatorChange} />

      <PathwayPicker selectedIds={pathwayIds} onChange={onPathwaysChange} />

      <div className="flex flex-col gap-2 pt-2">
        <button
          type="button"
          disabled={isSubmitting}
          onClick={onSaveDraft}
          className="w-full rounded-md border border-border bg-white px-4 py-2 text-sm font-medium text-foreground hover:bg-surface disabled:opacity-60"
        >
          Save draft
        </button>
        <button
          type="button"
          disabled={isSubmitting}
          onClick={onSubmitForReview}
          className="w-full rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          {isSubmitting ? "Submitting..." : "Submit for review"}
        </button>
      </div>
    </aside>
  );
}
