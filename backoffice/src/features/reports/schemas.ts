/**
 * src/features/reports/schemas.ts
 *
 * WHAT: Zod schemas for report filters and schedules
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import { z } from "zod";

export const reportFiltersSchema = z.object({
  range: z.enum(["7d", "30d", "90d", "12m"]).default("30d"),
  campus: z.string().default("all"),
  community: z.string().default("all"),
});

export type ReportFiltersState = z.infer<typeof reportFiltersSchema>;

export const scheduleReportSchema = z.object({
  reportType: z.enum(["discipleship_summary", "community_health", "content_completions"]),
  cadence: z.enum(["weekly", "monthly", "quarterly"]),
  recipientEmail: z.string().email("Enter a valid recipient email address."),
});

export type ScheduleReportInput = z.infer<typeof scheduleReportSchema>;
