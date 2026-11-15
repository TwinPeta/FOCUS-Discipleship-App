/**
 * src/features/dashboard/queries.ts
 *
 * WHAT: Dashboard KPI, activity and attention queries
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import { ROUTES } from "@/lib/constants/routes";
import { readFallback, requireBackend } from "@/lib/api/mockFallback";

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

export const MOCK_DASHBOARD_DATA: DashboardData = {
  kpis: [
    {
      id: "active-members",
      label: "Active members (30d)",
      value: "1,284",
      changePercent: 8.4,
    },
    {
      id: "completions",
      label: "Module completions",
      value: "642",
      changePercent: 12.1,
    },
    {
      id: "communities",
      label: "Active communities",
      value: "28",
      changePercent: 3.7,
    },
    {
      id: "avg-attendance",
      label: "Meeting attendance",
      value: "74%",
      changePercent: -1.8,
      helper: "Open Question #6: attendance source pending",
    },
  ],
  weeklyActivity: [
    { day: "Mon", logins: 210, completions: 64 },
    { day: "Tue", logins: 245, completions: 82 },
    { day: "Wed", logins: 290, completions: 95 },
    { day: "Thu", logins: 268, completions: 88 },
    { day: "Fri", logins: 230, completions: 71 },
    { day: "Sat", logins: 195, completions: 63 },
    { day: "Sun", logins: 312, completions: 114 },
  ],
  needsAttention: [
    {
      id: "join-requests",
      label: "Pending join requests",
      count: 14,
      href: ROUTES.joinRequests,
    },
    {
      id: "reports",
      label: "Open moderation reports",
      count: 5,
      href: ROUTES.moderationReports,
    },
    {
      id: "testimonies",
      label: "Testimonies to review",
      count: 7,
      href: ROUTES.moderationTestimonies,
    },
    {
      id: "content-review",
      label: "Content awaiting validation",
      count: 4,
      href: ROUTES.content,
    },
  ],
  inactiveMembers: [
    {
      id: "mem-401",
      name: "Samuel Okello",
      community: "Makerere University",
      daysInactive: 19,
      lastActiveAt: "2026-10-26",
    },
    {
      id: "mem-402",
      name: "Esther Namono",
      community: "Kyambogo University",
      daysInactive: 16,
      lastActiveAt: "2026-10-29",
    },
    {
      id: "mem-403",
      name: "Brian Mugisha",
      community: "MUBS Kampala",
      daysInactive: 24,
      lastActiveAt: "2026-10-21",
    },
    {
      id: "mem-404",
      name: "Joy Achen",
      community: "Gulu University",
      daysInactive: 15,
      lastActiveAt: "2026-10-30",
    },
  ],
};

export async function fetchDashboardData(): Promise<DashboardData> {
  try {
    const res = await fetch("/api/proxy/dashboard");
    if (res.ok) {
      return (await res.json()) as DashboardData;
    }
  } catch {
    // Fall back to mock data in dev mode
  }
  return readFallback(() => MOCK_DASHBOARD_DATA, "the dashboard");
}

export async function sendMemberReminder(memberId: string): Promise<void> {
  try {
    const res = await fetch(`/api/proxy/members/${memberId}/remind`, {
      method: "POST",
    });
    if (res.ok) return;
  } catch {
    // Non-blocking in dev mode
  }
  requireBackend();
}
