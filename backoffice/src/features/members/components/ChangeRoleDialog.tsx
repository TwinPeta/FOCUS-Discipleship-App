/**
 * src/features/members/components/ChangeRoleDialog.tsx
 *
 * WHAT: Confirmation dialog for changing a member's role
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import type { Role } from "@/types/enums";
import { RoleSelector } from "./RoleSelector";

interface ChangeRoleDialogProps {
  open: boolean;
  memberName: string;
  currentRole: Role;
  onConfirm: (newRole: Role) => Promise<void>;
  onClose: () => void;
}

export function ChangeRoleDialog({
  open,
  memberName,
  currentRole,
  onConfirm,
  onClose,
}: ChangeRoleDialogProps) {
  const [role, setRole] = useState<Role>(currentRole);
  const [submitting, setSubmitting] = useState(false);

  if (!open) return null;

  async function handleConfirm() {
    setSubmitting(true);
    try {
      await onConfirm(role);
      onClose();
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="change-role-title"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-md space-y-4 rounded-card border border-border bg-white p-6 shadow-lg">
        <h2 id="change-role-title" className="text-base font-semibold text-foreground">
          Change role for {memberName}
        </h2>

        <div className="space-y-1.5">
          <label htmlFor="new-role-select" className="block text-[13px] font-extrabold">
            New role
          </label>
          <RoleSelector id="new-role-select" value={role} onChange={setRole} />
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
            className="rounded-md bg-primary px-3 py-1.5 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
          >
            {submitting ? "Saving..." : "Confirm role change"}
          </button>
        </div>
      </div>
    </div>
  );
}
