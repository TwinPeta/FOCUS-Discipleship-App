/**
 * src/features/moderation/components/ReportDetail.tsx
 *
 * WHAT: Side panel showing full report details, earlier reports count, and L1/L2 actions
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import type { ModerationReport, ReportAction } from "@/features/moderation/schemas";
import { ModerationActions } from "./ModerationActions";

interface ReportDetailProps {
  report: ModerationReport;
  onAction: (action: ReportAction, notes?: string) => Promise<void>;
  onClose: () => void;
}

export function ReportDetail({ report, onAction, onClose }: ReportDetailProps) {
  return (
    <aside className="space-y-4 rounded-card border border-border bg-white p-5">
      <div className="flex items-start justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold text-foreground">{report.reason}</h2>
          <p className="text-xs text-muted-foreground">
            {report.communityName} · {report.createdAt}
          </p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="text-xs text-muted-foreground hover:text-foreground"
        >
          Close
        </button>
      </div>

      <dl className="space-y-1.5 text-sm">
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Reported user</dt>
          <dd className="font-medium text-foreground">{report.reportedUserName}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Reporter</dt>
          <dd className="text-foreground">{report.reporterName}</dd>
        </div>
        <div className="flex justify-between gap-2">
          <dt className="text-muted-foreground">Earlier reports</dt>
          <dd className="text-foreground">{report.earlierReportsCount}</dd>
        </div>
      </dl>

      <div className="rounded-md border border-border bg-surface p-3 text-sm text-foreground">
        {report.details}
      </div>

      <ModerationActions report={report} onAction={onAction} />
    </aside>
  );
}
