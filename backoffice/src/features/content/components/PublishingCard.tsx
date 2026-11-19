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
    <aside className="card flex min-w-0 flex-col gap-3">
      <div className="flex items-center justify-between">
        <h2 className="eyebrow">Publishing</h2>
        <WorkflowStatusBadge status={status} />
      </div>

      <p className="text-[15px]">
        Author: <strong>{authorName}</strong>
      </p>

      <ValidatorField value={validatorName} onChange={onValidatorChange} />

      <PathwayPicker selectedIds={pathwayIds} onChange={onPathwaysChange} />

      <div className="flex flex-col gap-2 pt-2">
        <button
          type="button"
          disabled={isSubmitting}
          onClick={onSaveDraft}
          className="btn btn-secondary w-full"
        >
          Save draft
        </button>
        <button
          type="button"
          disabled={isSubmitting}
          onClick={onSubmitForReview}
          className="btn btn-primary w-full"
        >
          {isSubmitting ? "Submitting..." : "Submit for review"}
        </button>
      </div>

      <p className="notice">
        <span>Draft → In review → Published. The validator is recorded.</span>
      </p>
    </aside>
  );
}
