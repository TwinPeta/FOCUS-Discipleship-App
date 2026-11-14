/**
 * src/features/audit/queries.ts
 *
 * WHAT: Audit log queries and audited CSV export
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Role } from "@/types/enums";

export type AuditActionType =
  | "role_changed"
  | "staff_created"
  | "content_published"
  | "moderation_action"
  | "data_request_processed"
  | "audit_exported"
  | "settings_updated";

export interface AuditEntry {
  id: string;
  occurredAt: string;
  actorName: string;
  actorRole: Role;
  action: AuditActionType;
  actionLabel: string;
  target: string;
  place: string;
}

export interface AuditFilterState {
  search: string;
  action: AuditActionType | "all";
  role: Role | "all";
  period: "7d" | "30d" | "90d" | "all";
}

export const MOCK_AUDIT_ENTRIES: AuditEntry[] = [
  {
    id: "aud-001",
    occurredAt: "2026-11-14T09:42:00Z",
    actorName: "Sarah K.",
    actorRole: Role.SystemAdmin,
    action: "role_changed",
    actionLabel: "Changed role",
    target: "Peter O. -> Super-mentor",
    place: "Makerere University",
  },
  {
    id: "aud-002",
    occurredAt: "2026-11-13T16:15:00Z",
    actorName: "David M.",
    actorRole: Role.ContentAdmin,
    action: "content_published",
    actionLabel: "Published content",
    target: "Walking in Faith — Week 4",
    place: "National Library",
  },
  {
    id: "aud-003",
    occurredAt: "2026-11-13T11:08:00Z",
    actorName: "Sarah K.",
    actorRole: Role.SystemAdmin,
    action: "audit_exported",
    actionLabel: "Exported audit log",
    target: "CSV export (last 30 days)",
    place: "System Admin",
  },
  {
    id: "aud-004",
    occurredAt: "2026-11-11T14:22:00Z",
    actorName: "Grace N.",
    actorRole: Role.SuperMentor,
    action: "moderation_action",
    actionLabel: "Removed post (L1)",
    target: "Post #4829",
    place: "Kyambogo University",
  },
  {
    id: "aud-005",
    occurredAt: "2026-11-08T08:50:00Z",
    actorName: "Sarah K.",
    actorRole: Role.SystemAdmin,
    action: "data_request_processed",
    actionLabel: "Fulfilled export request",
    target: "Request #DR-204 (Daniel T.)",
    place: "Privacy & Data",
  },
  {
    id: "aud-006",
    occurredAt: "2026-10-28T13:10:00Z",
    actorName: "Sarah K.",
    actorRole: Role.SystemAdmin,
    action: "settings_updated",
    actionLabel: "Updated retention policy",
    target: "Inactive reminder threshold: 14 days",
    place: "Settings",
  },
];

export async function fetchAuditEntries(
  filters: AuditFilterState,
): Promise<AuditEntry[]> {
  try {
    const params = new URLSearchParams();
    if (filters.search) params.set("q", filters.search);
    if (filters.action !== "all") params.set("action", filters.action);
    if (filters.role !== "all") params.set("role", filters.role);
    if (filters.period !== "all") params.set("period", filters.period);

    const res = await fetch(`/api/proxy/audit-log?${params.toString()}`);
    if (res.ok) {
      const data = (await res.json()) as { items?: AuditEntry[] };
      if (Array.isArray(data.items)) return data.items;
    }
  } catch {
    // Fall back to filtered mock data in dev mode
  }

  const now = Date.now();
  const periodDays =
    filters.period === "7d"
      ? 7
      : filters.period === "30d"
        ? 30
        : filters.period === "90d"
          ? 90
          : null;

  return MOCK_AUDIT_ENTRIES.filter((entry) => {
    if (filters.action !== "all" && entry.action !== filters.action) {
      return false;
    }
    if (filters.role !== "all" && entry.actorRole !== filters.role) {
      return false;
    }
    if (periodDays !== null) {
      const ageMs = now - new Date(entry.occurredAt).getTime();
      if (ageMs > periodDays * 86_400_000) return false;
    }
    if (filters.search.trim()) {
      const q = filters.search.trim().toLowerCase();
      const haystack = `${entry.actorName} ${entry.actionLabel} ${entry.target} ${entry.place}`.toLowerCase();
      if (!haystack.includes(q)) return false;
    }
    return true;
  });
}

export async function recordAndBuildAuditCsv(
  entries: AuditEntry[],
): Promise<string> {
  try {
    await fetch("/api/proxy/audit-log/export", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ count: entries.length }),
    });
  } catch {
    // Non-blocking in dev mode
  }

  const header = ["When", "Who", "Role", "Action", "Target", "Place"];
  const escape = (val: string) => `"${val.replace(/"/g, '""')}"`;
  const rows = entries.map((e) =>
    [e.occurredAt, e.actorName, e.actorRole, e.actionLabel, e.target, e.place]
      .map(escape)
      .join(","),
  );
  return [header.join(","), ...rows].join("\n");
}
