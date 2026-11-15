/**
 * src/features/dashboard/queries.ts
 *
 * WHAT: Dashboard KPI, activity and attention queries
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";

export interface DashboardKpi {
  id: string;
  label: string;
  value: string;
  changePercent: number;
  helper?: string;
}

export interface WeeklyActivityPoint {
  day: string;
  logins: number;
  completions: number;
}

export interface AttentionItem {
  id: string;
  label: string;
  count: number;
  href: string;
}

export interface InactiveMember {
  id: string;
  name: string;
  community: string;
  daysInactive: number;
  lastActiveAt: string;
}

export interface DashboardData {
  kpis: DashboardKpi[];
  weeklyActivity: WeeklyActivityPoint[];
  needsAttention: AttentionItem[];
  inactiveMembers: InactiveMember[];
}

export async function fetchDashboardData(): Promise<DashboardData> {
  return apiClient<DashboardData>("/dashboard");
}

export async function sendMemberReminder(memberId: string): Promise<void> {
  await mutate(`/members/${memberId}/remind`, "POST", undefined, "send the reminder");
}
