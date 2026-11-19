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
import { X } from "lucide-react";
import { StatusPill } from "@/components/data-table/StatusPill";
import { ReportStatus } from "@/types/enums";
import { ModerationActions } from "./ModerationActions";

interface ReportDetailProps {
  report: ModerationReport;
  onAction: (action: ReportAction, notes?: string) => Promise<void>;
  onClose: () => void;
}

export function ReportDetail({ report, onAction, onClose }: ReportDetailProps) {
  return (
    <aside className="card flex min-w-0 flex-[1_1_320px] flex-col gap-3 lg:max-w-[440px]">
      <div className="flex items-start justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-[22px] font-black">Report</h2>
          <StatusPill status={report.status} variant={report.status === ReportStatus.Resolved ? "inactive" : "pending"} />
        </div>
        <button type="button" onClick={onClose} aria-label="Close" className="rounded-md p-1 hover:bg-blue-soft">
          <X className="h-5 w-5" aria-hidden="true" />
        </button>
      </div>

      <dl className="divide-y-[1.5px] divide-border text-[15px]">
        {[
          ["Reason", report.reason],
          ["Reported user", report.reportedUserName],
          ["Reported by", report.reporterName],
          ["Caregroup", report.communityName],
        ].map(([k, v]) => (
          <div key={k} className="flex justify-between gap-3 py-2">
            <dt>{k}</dt>
            <dd className="text-right font-extrabold">{v}</dd>
          </div>
        ))}
      </dl>

      <div>
        <p className="eyebrow mb-1">Details from the reporter</p>
        <p className="text-[15px]">{report.details}</p>
      </div>

      {report.earlierReportsCount > 0 && (
        <p className="notice">
          <span>{report.earlierReportsCount} earlier reports about this user.</span>
        </p>
      )}

      <ModerationActions report={report} onAction={onAction} />
    </aside>
  );
}
