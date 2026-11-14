/**
 * src/features/audit/components/AuditFilters.tsx
 *
 * WHAT: Search, action, role and period filters
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Role } from "@/types/enums";
import type { AuditActionType, AuditFilterState } from "../queries";

interface AuditFiltersProps {
  value: AuditFilterState;
  onChange: (next: AuditFilterState) => void;
}

const ACTION_OPTIONS: { value: AuditActionType | "all"; label: string }[] = [
  { value: "all", label: "All actions" },
  { value: "role_changed", label: "Role changed" },
  { value: "staff_created", label: "Staff created" },
  { value: "content_published", label: "Content published" },
  { value: "moderation_action", label: "Moderation action" },
  { value: "data_request_processed", label: "Data request processed" },
  { value: "audit_exported", label: "Audit exported" },
  { value: "settings_updated", label: "Settings updated" },
];

const STAFF_ROLES: Role[] = [
  Role.SystemAdmin,
  Role.ContentAdmin,
  Role.SuperMentor,
  Role.Mentor,
];

export function AuditFilters({ value, onChange }: AuditFiltersProps) {
  return (
    <div className="grid gap-3 rounded-xl border border-border bg-white p-4 sm:grid-cols-2 lg:grid-cols-4">
      <div className="space-y-1">
        <label htmlFor="audit-search" className="block text-xs font-medium text-muted">
          Search
        </label>
        <input
          id="audit-search"
          type="search"
          value={value.search}
          onChange={(e) => onChange({ ...value, search: e.target.value })}
          placeholder="Actor, target, or community…"
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        />
      </div>

      <div className="space-y-1">
        <label htmlFor="audit-action" className="block text-xs font-medium text-muted">
          Action
        </label>
        <select
          id="audit-action"
          value={value.action}
          onChange={(e) =>
            onChange({
              ...value,
              action: e.target.value as AuditFilterState["action"],
            })
          }
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          {ACTION_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1">
        <label htmlFor="audit-role" className="block text-xs font-medium text-muted">
          Role
        </label>
        <select
          id="audit-role"
          value={value.role}
          onChange={(e) =>
            onChange({
              ...value,
              role: e.target.value as AuditFilterState["role"],
            })
          }
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="all">All roles</option>
          {STAFF_ROLES.map((r) => (
            <option key={r} value={r}>
              {ROLE_LABELS[r]}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1">
        <label htmlFor="audit-period" className="block text-xs font-medium text-muted">
          Period
        </label>
        <select
          id="audit-period"
          value={value.period}
          onChange={(e) =>
            onChange({
              ...value,
              period: e.target.value as AuditFilterState["period"],
            })
          }
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="7d">Last 7 days</option>
          <option value="30d">Last 30 days</option>
          <option value="90d">Last 90 days</option>
          <option value="all">All time</option>
        </select>
      </div>
    </div>
  );
}
