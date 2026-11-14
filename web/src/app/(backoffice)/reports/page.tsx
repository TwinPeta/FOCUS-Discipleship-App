/**
 * src/app/(backoffice)/reports/page.tsx
 *
 * WHAT: B20 Reports and statistics: filters, KPIs, charts, most active communities, scheduled reports, PDF/CSV export
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { AuditNotice } from "@/components/common/AuditNotice";
import { ActiveCommunitiesList } from "@/features/reports/components/ActiveCommunitiesList";
import { CompletionsByTypeChart } from "@/features/reports/components/CompletionsByTypeChart";
import { ExportButtons } from "@/features/reports/components/ExportButtons";
import { MembersOverTimeChart } from "@/features/reports/components/MembersOverTimeChart";
import { ReportFilters } from "@/features/reports/components/ReportFilters";
import { ScheduleReportDialog } from "@/features/reports/components/ScheduleReportDialog";
import { ScheduledReportsTable } from "@/features/reports/components/ScheduledReportsTable";
import {
  fetchReportsData,
  MOCK_REPORTS_DATA,
  type ReportsData,
  type ScheduledReport,
} from "@/features/reports/queries";
import type { ReportFiltersState } from "@/features/reports/schemas";

export default function ReportsPage() {
  const [filters, setFilters] = useState<ReportFiltersState>({
    range: "30d",
    campus: "all",
    community: "all",
  });
  const [data, setData] = useState<ReportsData>(MOCK_REPORTS_DATA);

  useEffect(() => {
    let active = true;
    fetchReportsData(filters).then((res) => {
      if (active) setData(res);
    });
    return () => {
      active = false;
    };
  }, [filters]);

  function handleCreatedSchedule(schedule: ScheduledReport) {
    setData((prev) => ({
      ...prev,
      scheduledReports: [schedule, ...prev.scheduledReports],
    }));
  }

  function handleToggleSchedule(id: string) {
    setData((prev) => ({
      ...prev,
      scheduledReports: prev.scheduledReports.map((s) =>
        s.id === id ? { ...s, active: !s.active } : s,
      ),
    }));
  }

  return (
    <main className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">
            Reports &amp; statistics
          </h1>
          <p className="mt-1 text-sm text-muted">
            Track membership growth, content completions, community engagement, and scheduled exports.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <ExportButtons filters={filters} data={data} />
          <ScheduleReportDialog onCreated={handleCreatedSchedule} />
        </div>
      </div>

      <AuditNotice message="Exporting reports to CSV or PDF is recorded in the audit log." />
      <ReportFilters value={filters} onChange={setFilters} />

      <div className="grid gap-6 lg:grid-cols-2">
        <MembersOverTimeChart data={data.membersOverTime} />
        <CompletionsByTypeChart data={data.completionsByType} />
      </div>

      <ActiveCommunitiesList communities={data.activeCommunities} />

      <ScheduledReportsTable
        schedules={data.scheduledReports}
        onToggleActive={handleToggleSchedule}
      />
    </main>
  );
}
