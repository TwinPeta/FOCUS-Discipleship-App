/**
 * src/features/audit/queries.ts
 *
 * WHAT: Audit log queries and audited CSV export
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { apiClient } from "@/lib/api/client";
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

export async function fetchAuditEntries(
  filters: AuditFilterState,
): Promise<AuditEntry[]> {
  const data = await apiClient<{ items?: AuditEntry[] }>("/audit-log", {
    params: {
      q: filters.search || undefined,
      action: filters.action !== "all" ? filters.action : undefined,
      role: filters.role !== "all" ? filters.role : undefined,
      period: filters.period !== "all" ? filters.period : undefined,
    },
  });
  return data.items ?? [];
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
