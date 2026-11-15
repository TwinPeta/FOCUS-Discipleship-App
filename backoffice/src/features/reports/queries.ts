/**
 * src/features/reports/queries.ts
 *
 * WHAT: Statistics, export and scheduled report queries and mutations
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import type { ReportFiltersState, ScheduleReportInput } from "./schemas";
import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";

export interface MembersTimePoint {
  period: string;
  totalMembers: number;
  activeMembers: number;
}

export interface CompletionByTypePoint {
  type: string;
  completions: number;
}

export interface ActiveCommunityStat {
  id: string;
  name: string;
  campus: string;
  memberCount: number;
  activePercent: number;
}

export interface ScheduledReport {
  id: string;
  reportType: ScheduleReportInput["reportType"];
  reportLabel: string;
  cadence: ScheduleReportInput["cadence"];
  recipientEmail: string;
  active: boolean;
}

export interface ReportsData {
  membersOverTime: MembersTimePoint[];
  completionsByType: CompletionByTypePoint[];
  activeCommunities: ActiveCommunityStat[];
  scheduledReports: ScheduledReport[];
}

export const REPORT_TYPE_LABELS: Record<ScheduleReportInput["reportType"], string> = {
  discipleship_summary: "Discipleship summary",
  community_health: "Community health & attendance",
  content_completions: "Content completions",
};

export async function fetchReportsData(
  filters: ReportFiltersState,
): Promise<ReportsData> {
  return apiClient<ReportsData>("/reports", {
    params: { range: filters.range, campus: filters.campus, community: filters.community },
  });
}

export async function exportReportFile(
  format: "csv" | "pdf",
  filters: ReportFiltersState,
  data: ReportsData,
): Promise<void> {
  try {
    // Records the export in the audit log; the file itself is built from the data already on screen
    await fetch("/api/proxy/reports/export", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ format, filters }),
    });
  } catch {
    // The download still works if the audit call cannot be made
  }

  if (format === "csv") {
    const lines = [
      "Community,Campus,Members,ActivePercent",
      ...data.activeCommunities.map(
        (c) => `"${c.name}","${c.campus}",${c.memberCount},${c.activePercent}%`,
      ),
    ];
    const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `focus-report-${filters.range}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  } else {
    window.print();
  }
}

export async function createScheduledReport(
  input: ScheduleReportInput,
): Promise<ScheduledReport> {
  return mutate<ScheduledReport>("/reports/schedules", "POST", input);
}

export async function setScheduledReportActive(id: string, active: boolean): Promise<ScheduledReport> {
  return mutate<ScheduledReport>(`/reports/schedules/${id}`, "PATCH", { active });
}
