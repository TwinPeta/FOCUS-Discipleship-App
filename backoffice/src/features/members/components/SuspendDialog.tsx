/**
 * src/features/members/components/SuspendDialog.tsx
 *
 * WHAT: Confirmation dialog for suspending a member with required reason
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";

interface SuspendDialogProps {
  open: boolean;
  memberName: string;
  onConfirm: (reason: string) => Promise<void>;
  onClose: () => void;
}

export function SuspendDialog({
  open,
  memberName,
  onConfirm,
  onClose,
}: SuspendDialogProps) {
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (!open) return null;

  async function handleConfirm() {
    if (reason.trim().length < 5) {
      setError("Please provide a reason (at least 5 characters).");
      return;
    }
    setError(null);
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
      aria-labelledby="suspend-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-md space-y-4 rounded-card border border-border bg-white p-6 shadow-lg">
        <h2 id="suspend-title" className="text-base font-semibold text-foreground">
          Suspend {memberName}?
        </h2>
        <p className="text-xs text-muted-foreground">
          Suspended users cannot sign in. This action is recorded in the audit log.
        </p>

        <div className="space-y-1.5">
          <label htmlFor="suspend-reason" className="block text-sm font-medium">
            Reason
          </label>
          <textarea
            id="suspend-reason"
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          />
          {error && (
            <p role="alert" className="text-xs text-red-700">
              {error}
            </p>
          )}
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
            className="rounded-md bg-red-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60"
          >
            {submitting ? "Suspending..." : "Confirm suspension"}
          </button>
        </div>
      </div>
    </div>
  );
}
