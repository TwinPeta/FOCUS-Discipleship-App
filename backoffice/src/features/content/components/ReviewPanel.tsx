/**
 * src/features/content/components/ReviewPanel.tsx
 *
 * WHAT: Content validation panel with reviewer notes and approve/request-changes actions
 * REQUIREMENTS: FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { useSession } from "@/features/auth/hooks/useSession";
import { ContentAction, canTransitionContent } from "@/features/content/workflow";
import type { ContentStatus } from "@/types/enums";

interface ReviewPanelProps {
  status: ContentStatus;
  onTransition: (action: ContentAction, notes?: string) => Promise<void>;
}

export function ReviewPanel({ status, onTransition }: ReviewPanelProps) {
  const { user } = useSession();
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const canApprove = canTransitionContent(status, ContentAction.ApproveAndPublish, user);
  const canRequestChanges = canTransitionContent(status, ContentAction.RequestChanges, user);

  if (!canApprove && !canRequestChanges) {
    return null;
  }

  async function runAction(action: ContentAction) {
    setSubmitting(true);
    try {
      await onTransition(action, notes.trim() || undefined);
      setNotes("");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-4 rounded-card border border-border bg-white p-5">
      <h2 className="text-base font-semibold text-foreground">Validation review</h2>

      <div className="space-y-1.5">
        <label htmlFor="reviewer-notes" className="block text-sm font-medium text-foreground">
          Reviewer notes
        </label>
        <textarea
          id="reviewer-notes"
          rows={3}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Add theological or editorial notes..."
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <div className="flex flex-wrap gap-2">
        {canApprove && (
          <button
            type="button"
            disabled={submitting}
            onClick={() => runAction(ContentAction.ApproveAndPublish)}
            className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
          >
            Approve and publish
          </button>
        )}
        {canRequestChanges && (
          <button
            type="button"
            disabled={submitting}
            onClick={() => runAction(ContentAction.RequestChanges)}
            className="rounded-md border border-border px-4 py-2 text-sm font-medium text-foreground hover:bg-surface disabled:opacity-60"
          >
            Request changes
          </button>
        )}
      </div>
    </div>
  );
}
