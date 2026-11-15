import { unwrapList } from "@/lib/api/unwrap";
import { readFallback, requireBackend } from "@/lib/api/mockFallback";
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

export const MOCK_NOTIFICATION_RULES: NotificationRule[] = [
  {
    id: "notif-1",
    triggerKey: "join_request_approved",
    triggerLabel: "Join request approved",
    recipient: "Student",
    channels: { inApp: true, email: true },
    enabled: true,
    template: {
      title: "Welcome to {{community_name}}!",
      message: "Hi {{member_name}}, your request to join {{community_name}} has been approved. See you at fellowship!",
    },
    updatedAt: "2026-11-01",
  },
  {
    id: "notif-2",
    triggerKey: "join_request_declined",
    triggerLabel: "Join request declined",
    recipient: "Student",
    channels: { inApp: true, email: true },
    enabled: true,
    template: {
      title: "Update on your join request",
      message: "Hi {{member_name}}, your request to join {{community_name}} could not be approved at this time.",
    },
    updatedAt: "2026-11-01",
  },
  {
    id: "notif-3",
    triggerKey: "inactivity_reminder",
    triggerLabel: "No activity for threshold period",
    recipient: "Student",
    channels: { inApp: true, email: true },
    enabled: true,
    template: {
      title: "We miss you in fellowship!",
      message: "Hi {{member_name}}, it has been a couple of weeks since your last visit. We are praying for your studies and hope to see you at the next meeting.",
    },
    updatedAt: "2026-11-05",
  },
  {
    id: "notif-4",
    triggerKey: "new_announcement",
    triggerLabel: "New announcement posted",
    recipient: "Student",
    channels: { inApp: true, email: false },
    enabled: true,
    template: {
      title: "New update from {{community_name}}",
      message: "{{item_title}}: {{message_preview}}",
    },
    updatedAt: "2026-10-20",
  },
  {
    id: "notif-5",
    triggerKey: "prayer_received",
    triggerLabel: "Someone prayed for your request",
    recipient: "Student",
    channels: { inApp: true, email: false },
    enabled: true,
    template: {
      title: "Someone is praying for you!",
      message: "A brother/sister in {{community_name}} just prayed for your prayer request '{{item_title}}'.",
    },
    updatedAt: "2026-10-18",
  },
  {
    id: "notif-6",
    triggerKey: "report_received",
    triggerLabel: "Moderation report received",
    recipient: "Super-mentor",
    channels: { inApp: true, email: true },
    enabled: true,
    template: {
      title: "New moderation report in {{community_name}}",
      message: "A new community report requires your review: {{item_title}}.",
    },
    updatedAt: "2026-11-10",
  },
  {
    id: "notif-7",
    triggerKey: "testimony_published",
    triggerLabel: "Testimony published",
    recipient: "Student",
    channels: { inApp: true, email: false },
    enabled: true,
    template: {
      title: "Your testimony has been published!",
      message: "Hi {{member_name}}, your testimony '{{item_title}}' is now live on the fellowship testimony feed.",
    },
    updatedAt: "2026-10-25",
  },
];

export async function fetchNotificationRules(): Promise<NotificationRule[]> {
  try {
    const res = await fetch("/api/proxy/notifications/rules");
    if (res.ok) {
      return unwrapList<NotificationRule>(await res.json());
    }
  } catch {
    // Dev mock fallback
  }
  return readFallback(() => MOCK_NOTIFICATION_RULES, "notification rules");
}

export async function updateNotificationRule(
  id: string,
  updates: Partial<NotificationRule>,
): Promise<NotificationRule> {
  try {
    const res = await fetch(`/api/proxy/notifications/rules/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(updates),
    });
    if (res.ok) {
      return (await res.json()) as NotificationRule;
    }
  } catch {
    // Dev mock fallback
  }
  requireBackend();

  const existing = MOCK_NOTIFICATION_RULES.find((r) => r.id === id);
  if (!existing) throw new Error("Notification rule not found");
  return { ...existing, ...updates, updatedAt: new Date().toISOString().slice(0, 10) };
}

export async function fetchInactivityDays(): Promise<number> {
  try {
    const res = await fetch("/api/proxy/settings/inactivity-threshold");
    if (res.ok) {
      const data = await res.json();
      return data.days ?? 14;
    }
  } catch {
    // Dev mock fallback
  }
  return 14;
}

export async function updateInactivityDays(days: number): Promise<number> {
  try {
    const res = await fetch("/api/proxy/settings/inactivity-threshold", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ days }),
    });
    if (res.ok) {
      const data = await res.json();
      return data.days;
    }
  } catch {
    // Dev mock fallback
  }
  requireBackend();
  return days;
}
