import { unwrapList } from "@/lib/api/unwrap";
import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";
/**
 * src/features/notifications/queries.ts
 *
 * WHAT: Notification rule and template queries and mutations
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

export type NotificationTriggerKey =
  | "join_request_approved"
  | "join_request_declined"
  | "inactivity_reminder"
  | "new_announcement"
  | "prayer_received"
  | "report_received"
  | "testimony_published";

export interface NotificationTemplate {
  title: string;
  message: string;
}

export interface NotificationRule {
  id: string;
  triggerKey: NotificationTriggerKey;
  triggerLabel: string;
  recipient: "Student" | "Mentor" | "Super-mentor" | "Staff";
  channels: {
    inApp: boolean;
    email: boolean;
    sms?: boolean;
  };
  enabled: boolean;
  template: NotificationTemplate;
  updatedAt: string;
}

export async function fetchNotificationRules(): Promise<NotificationRule[]> {
  return unwrapList<NotificationRule>(await apiClient<unknown>("/notifications/rules"));
}

export async function updateNotificationRule(
  id: string,
  updates: Partial<NotificationRule>,
): Promise<NotificationRule> {
  return mutate<NotificationRule>(`/notifications/rules/${id}`, "PATCH", updates);
}

export async function fetchInactivityDays(): Promise<number> {
  const data = await apiClient<{ days: number }>("/settings/inactivity-threshold");
  return data.days;
}

export async function updateInactivityDays(days: number): Promise<number> {
  const data = await mutate<{ days: number }>("/settings/inactivity-threshold", "PUT", { days });
  return data.days;
}
