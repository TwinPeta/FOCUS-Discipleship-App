/**
 * src/app/(backoffice)/reports/page.tsx
 *
 * WHAT: B20 Reports and statistics: filters, KPIs, charts, most active communities, scheduled reports, PDF/CSV export
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { AuditNotice } from "@/components/common/AuditNotice";
import { ReportSummaryCards } from "@/features/reports/components/ReportSummaryCards";
import { ActiveCommunitiesList } from "@/features/reports/components/ActiveCommunitiesList";
import { CompletionsByTypeChart } from "@/features/reports/components/CompletionsByTypeChart";
import { ExportButtons } from "@/features/reports/components/ExportButtons";
import { MembersOverTimeChart } from "@/features/reports/components/MembersOverTimeChart";
import { ReportFilters } from "@/features/reports/components/ReportFilters";
import { ScheduleReportDialog } from "@/features/reports/components/ScheduleReportDialog";
import { ScheduledReportsTable } from "@/features/reports/components/ScheduledReportsTable";
import {
  fetchReportsData,
  setScheduledReportActive,
  type ScheduledReport,
} from "@/features/reports/queries";
import type { ReportFiltersState } from "@/features/reports/schemas";
import { ErrorState } from "@/components/feedback/ErrorState";
import { PanelSkeleton } from "@/components/feedback/Skeletons";
import { useRemoteData } from "@/lib/hooks/useRemoteData";

export default function ReportsPage() {
  const [filters, setFilters] = useState<ReportFiltersState>({
    range: "30d",
    campus: "all",
    community: "all",
  });
  const { data, setData, loading, error, reload } = useRemoteData(
    () => fetchReportsData(filters),
    [filters.range, filters.campus, filters.community],
  );

  function handleCreatedSchedule(schedule: ScheduledReport) {
    setData((prev) => prev && { ...prev, scheduledReports: [schedule, ...prev.scheduledReports] });
  }

  async function handleToggleSchedule(id: string) {
    const current = data?.scheduledReports.find((s) => s.id === id);
    if (!current) return;
    const saved = await setScheduledReportActive(id, !current.active);
    setData(
      (prev) =>
        prev && { ...prev, scheduledReports: prev.scheduledReports.map((s) => (s.id === id ? saved : s)) },
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">
            Reports &amp; statistics
          </h1>
          <p className="mt-1 text-sm text-muted">
            Track membership growth, content completions, caregroup engagement, and scheduled exports.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {data && <ExportButtons filters={filters} data={data} />}
          <ScheduleReportDialog onCreated={handleCreatedSchedule} />
        </div>
      </div>

      <AuditNotice message="Exporting reports to CSV or PDF is recorded in the audit log." />
      <ReportFilters value={filters} onChange={setFilters} />

      {error && <ErrorState message={error} onRetry={reload} />}
      {!data && loading && <PanelSkeleton />}
      {data && (
        <>
          {data.summary && <ReportSummaryCards summary={data.summary} />}
          <div className="grid gap-4 lg:grid-cols-2">
            <MembersOverTimeChart data={data.membersOverTime} />
            <CompletionsByTypeChart data={data.completionsByType} />
          </div>

          <ActiveCommunitiesList communities={data.activeCommunities} />

          <ScheduledReportsTable
            schedules={data.scheduledReports}
            onToggleActive={handleToggleSchedule}
          />
        </>
      )}
    </div>
  );
}
