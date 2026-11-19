/**
 * src/features/join-requests/components/DeclineDialog.tsx
 *
 * WHAT: Confirmation dialog for declining a join request with an optional reason
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";

interface DeclineDialogProps {
  open: boolean;
  studentName: string;
  onConfirm: (reason?: string) => Promise<void>;
  onClose: () => void;
}

export function DeclineDialog({
  open,
  studentName,
  onConfirm,
  onClose,
}: DeclineDialogProps) {
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (!open) return null;

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm(reason.trim() || undefined);
      setReason("");
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="decline-dialog-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-md space-y-4 rounded-card border border-border bg-white p-6 shadow-lg">
        <h2 id="decline-dialog-title" className="text-base font-semibold text-foreground">
          Decline join request for {studentName}?
        </h2>

        <div className="space-y-1.5">
          <label htmlFor="decline-reason" className="block text-[13px] font-extrabold">
            Reason (optional)
          </label>
          <textarea
            id="decline-reason"
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Share a brief note for the student..."
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          />
        </div>

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
            className="rounded-md bg-danger px-3 py-1.5 text-sm font-semibold text-white hover:brightness-95 disabled:opacity-60"
          >
            {submitting ? "Declining..." : "Decline request"}
          </button>
        </div>
      </div>
    </div>
  );
}
