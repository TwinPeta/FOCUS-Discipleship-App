/**
 * src/features/privacy/components/ProcessRequestDialog.tsx
 *
 * WHAT: Confirmation dialog for processing export or deletion requests with retention clarity
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import type { DataRequestRecord } from "@/features/privacy/queries";
import { DataRequestType } from "@/types/enums";

interface ProcessRequestDialogProps {
  request: DataRequestRecord | null;
  onConfirm: (id: string) => Promise<void>;
  onClose: () => void;
}

export function ProcessRequestDialog({
  request,
  onConfirm,
  onClose,
}: ProcessRequestDialogProps) {
  const [submitting, setSubmitting] = useState(false);

  if (!request) return null;

  const isDeletion = request.type === DataRequestType.Deletion;

  async function handleConfirm() {
    if (!request) return;
    setSubmitting(true);
    try {
      await onConfirm(request.id);
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="process-req-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-md space-y-4 rounded-card border border-border bg-white p-6 shadow-lg">
        <h2 id="process-req-title" className="text-base font-semibold text-foreground">
          {isDeletion ? "Confirm account data deletion" : "Generate personal data export"}
        </h2>

        <p className="text-sm text-muted-foreground">
          Member: <strong className="text-foreground">{request.memberName}</strong> (
          {request.memberEmail})
        </p>

        {isDeletion ? (
          <div className="rounded-md border border-primary bg-primary-soft p-3 text-xs text-ink">
            Personal profile data will be deleted or anonymised. Immutable audit log
            entries required for legal compliance are retained without personal
            contact details.
          </div>
        ) : (
          <p className="text-xs text-muted-foreground">
            An export package will be prepared and this action will be recorded in
            the audit log.
          </p>
        )}

        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onClose}
            className="rounded-md border border-border px-3 py-1.5 text-sm font-medium hover:bg-surface"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={submitting}
            onClick={handleConfirm}
            className={`rounded-md px-3 py-1.5 text-sm font-semibold disabled:opacity-60 ${
              isDeletion
                ? "bg-danger text-white hover:brightness-95"
                : "bg-primary text-foreground hover:brightness-95"
            }`}
          >
            {submitting
              ? "Processing..."
              : isDeletion
                ? "Confirm deletion"
                : "Export data"}
          </button>
        </div>
      </div>
    </div>
  );
}
