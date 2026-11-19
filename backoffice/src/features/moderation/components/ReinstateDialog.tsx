/**
 * src/features/moderation/components/ReinstateDialog.tsx
 *
 * WHAT: Confirmation dialog for reinstating a sanctioned user
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";

interface ReinstateDialogProps {
  open: boolean;
  userName: string;
  onConfirm: (reason: string) => Promise<void>;
  onClose: () => void;
}

export function ReinstateDialog({
  open,
  userName,
  onConfirm,
  onClose,
}: ReinstateDialogProps) {
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);

  if (!open) return null;

  async function handleConfirm() {
    if (!reason.trim()) return;
    setSubmitting(true);
    try {
      await onConfirm(reason.trim());
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
      aria-labelledby="reinstate-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-md space-y-4 rounded-card border border-border bg-white p-6 shadow-lg">
        <h2 id="reinstate-title" className="text-base font-semibold text-foreground">
          Reinstate {userName}?
        </h2>

        <div className="space-y-1.5">
          <label htmlFor="reinstate-reason" className="block text-[13px] font-extrabold">
            Reason for reinstatement
          </label>
          <textarea
            id="reinstate-reason"
            rows={2}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
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
            disabled={!reason.trim() || submitting}
            onClick={handleConfirm}
            className="rounded-md bg-primary px-3 py-1.5 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
          >
            {submitting ? "Reinstating..." : "Confirm reinstate"}
          </button>
        </div>
      </div>
    </div>
  );
}
