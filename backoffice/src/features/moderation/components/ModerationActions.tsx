/**
 * src/features/moderation/components/ModerationActions.tsx
 *
 * WHAT: Role-gated Level 1 and Level 2 moderation action buttons with audit note
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { AuditNotice } from "@/components/common/AuditNotice";
import { useSession } from "@/features/auth/hooks/useSession";
import {
  getAllowedReportActions,
  isReportAboutSuperMentor,
  type ModerationReport,
  type ReportAction,
} from "@/features/moderation/schemas";
import { EscalationInfo } from "./EscalationInfo";

interface ModerationActionsProps {
  report: ModerationReport;
  onAction: (action: ReportAction, notes?: string) => Promise<void>;
}

const ACTION_LABELS: Record<ReportAction, string> = {
  DISMISS: "Dismiss",
  WARN: "Warn user",
  HIDE: "Hide content",
  ESCALATE: "Escalate to admin",
  SUSPEND: "Suspend user",
  DELETE: "Delete permanently",
};

export function ModerationActions({ report, onAction }: ModerationActionsProps) {
  const { user } = useSession();
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const allowed = getAllowedReportActions(user, report);
  const superMentorTarget = isReportAboutSuperMentor(report);

  async function handleAction(action: ReportAction) {
    setSubmitting(true);
    try {
      await onAction(action, notes.trim() || undefined);
      setNotes("");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-4">
      <AuditNotice message="All moderation decisions and sanctions are permanently recorded in the audit log." />
      <EscalationInfo isSuperMentorTarget={superMentorTarget} />

      {allowed.length === 0 ? (
        <p className="text-xs text-muted-foreground">
          You do not have permission to take action on this report.
        </p>
      ) : (
        <>
          <div className="space-y-1.5">
            <label htmlFor="mod-notes" className="block text-sm font-medium text-foreground">
              Moderation note
            </label>
            <textarea
              id="mod-notes"
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Record reason or context..."
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            {allowed.map((action) => {
              const destructive = action === "SUSPEND" || action === "DELETE";
              return (
                <button
                  key={action}
                  type="button"
                  disabled={submitting}
                  onClick={() => handleAction(action)}
                  className={`rounded-md px-3 py-1.5 text-xs font-semibold disabled:opacity-60 ${
                    destructive
                      ? "bg-red-600 text-white hover:bg-red-700"
                      : action === "ESCALATE"
                        ? "bg-amber-100 text-amber-900 hover:bg-amber-200"
                        : "border border-border bg-white text-foreground hover:bg-surface"
                  }`}
                >
                  {ACTION_LABELS[action]}
                </button>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}
