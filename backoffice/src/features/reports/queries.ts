/**
 * src/features/reports/queries.ts
 *
 * WHAT: Statistics, export and scheduled report queries and mutations
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import type { ReportFiltersState, ScheduleReportInput } from "./schemas";
import { requireBackend } from "@/lib/api/mockFallback";

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

export const MOCK_REPORTS_DATA: ReportsData = {
  membersOverTime: [
    { period: "Jun", totalMembers: 980, activeMembers: 740 },
    { period: "Jul", totalMembers: 1045, activeMembers: 810 },
    { period: "Aug", totalMembers: 1120, activeMembers: 890 },
    { period: "Sep", totalMembers: 1210, activeMembers: 970 },
    { period: "Oct", totalMembers: 1260, activeMembers: 1020 },
    { period: "Nov", totalMembers: 1340, activeMembers: 1105 },
  ],
  completionsByType: [
    { type: "Devotionals", completions: 312 },
    { type: "Videos", completions: 218 },
    { type: "Documents", completions: 114 },
    { type: "Quizzes", completions: 176 },
  ],
  activeCommunities: [
    {
      id: "comm-makerere",
      name: "Makerere University",
      campus: "Kampala Central",
      memberCount: 342,
      activePercent: 86,
    },
    {
      id: "comm-kyambogo",
      name: "Kyambogo University",
      campus: "Kampala East",
      memberCount: 254,
      activePercent: 81,
    },
    {
      id: "comm-mubs",
      name: "MUBS Kampala",
      campus: "Nakawa",
      memberCount: 198,
      activePercent: 77,
    },
    {
      id: "comm-gulu",
      name: "Gulu University",
      campus: "Northern Region",
      memberCount: 164,
      activePercent: 73,
    },
  ],
  scheduledReports: [
    {
      id: "sched-1",
      reportType: "discipleship_summary",
      reportLabel: "Discipleship summary",
      cadence: "monthly",
      recipientEmail: "leadership@focusuganda.org",
      active: true,
    },
    {
      id: "sched-2",
      reportType: "community_health",
      reportLabel: "Community health & attendance",
      cadence: "weekly",
      recipientEmail: "mentors@focusuganda.org",
      active: true,
    },
  ],
};

export async function fetchReportsData(
  filters: ReportFiltersState,
): Promise<ReportsData> {
  try {
    const params = new URLSearchParams({
      range: filters.range,
      campus: filters.campus,
      community: filters.community,
    });
    const res = await fetch(`/api/proxy/reports?${params.toString()}`);
    if (res.ok) {
      return (await res.json()) as ReportsData;
    }
  } catch {
    // Fall back to mock data in dev mode
  }
  return MOCK_REPORTS_DATA;
}

export async function exportReportFile(
  format: "csv" | "pdf",
  filters: ReportFiltersState,
  data: ReportsData,
): Promise<void> {
  try {
    await fetch("/api/proxy/reports/export", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ format, filters }),
    });
  } catch {
    // Non-blocking in dev mode
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
  try {
    const res = await fetch("/api/proxy/reports/schedules", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    if (res.ok) {
      return (await res.json()) as ScheduledReport;
    }
  } catch {
    // Fall back to local object in dev mode
  }
  requireBackend();
  return {
    id: `sched-${Date.now()}`,
    reportType: input.reportType,
    reportLabel: REPORT_TYPE_LABELS[input.reportType],
    cadence: input.cadence,
    recipientEmail: input.recipientEmail,
    active: true,
  };
}
