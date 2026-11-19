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
    <div className="mb-1.5 flex flex-wrap items-center gap-2.5">
      <div className="contents">
        <label htmlFor="audit-search" className="sr-only">
          Search
        </label>
        <input
          id="audit-search"
          type="search"
          value={value.search}
          onChange={(e) => onChange({ ...value, search: e.target.value })}
          placeholder="Search by person or action"
          className="field-soft min-w-[220px] flex-1 px-3.5"
        />
      </div>

      <div className="contents">
        <label htmlFor="audit-action" className="sr-only">
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
          className="pill-select"
        >
          {ACTION_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      </div>

      <div className="contents">
        <label htmlFor="audit-role" className="sr-only">
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
          className="pill-select"
        >
          <option value="all">All roles</option>
          {STAFF_ROLES.map((r) => (
            <option key={r} value={r}>
              {ROLE_LABELS[r]}
            </option>
          ))}
        </select>
      </div>

      <div className="contents">
        <label htmlFor="audit-period" className="sr-only">
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
          className="pill-select"
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
