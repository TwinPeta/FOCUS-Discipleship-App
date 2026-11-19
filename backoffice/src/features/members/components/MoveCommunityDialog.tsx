/**
 * src/features/members/components/MoveCommunityDialog.tsx
 *
 * WHAT: Confirmation dialog for moving a member to another specific community
 * REQUIREMENTS: FR-03, FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";

interface MoveCommunityDialogProps {
  open: boolean;
  memberName: string;
  currentCommunityId?: string | null;
  communities: { id: string; name: string }[];
  onConfirm: (communityId: string) => Promise<void>;
  onClose: () => void;
}

export function MoveCommunityDialog({
  open,
  memberName,
  currentCommunityId,
  communities,
  onConfirm,
  onClose,
}: MoveCommunityDialogProps) {
  const [communityId, setCommunityId] = useState(currentCommunityId ?? "");
  const [submitting, setSubmitting] = useState(false);

  if (!open) return null;

  async function handleConfirm() {
    if (!communityId) return;
    setSubmitting(true);
    try {
      await onConfirm(communityId);
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="move-comm-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-md space-y-4 rounded-card border border-border bg-white p-6 shadow-lg">
        <h2 id="move-comm-title" className="text-base font-semibold text-foreground">
          Move {memberName} to another community
        </h2>

        <div className="space-y-1.5">
          <label htmlFor="target-community" className="block text-[13px] font-extrabold">
            Target caregroup
          </label>
          <select
            id="target-community"
            value={communityId}
            onChange={(e) => setCommunityId(e.target.value)}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          >
            <option value="">Select caregroup</option>
            {communities.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
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
            disabled={!communityId || submitting}
            onClick={handleConfirm}
            className="rounded-md bg-primary px-3 py-1.5 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
          >
            {submitting ? "Moving..." : "Move member"}
          </button>
        </div>
      </div>
    </div>
  );
}
