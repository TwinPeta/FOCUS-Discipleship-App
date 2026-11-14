/**
 * src/features/members/components/RoleSelector.tsx
 *
 * WHAT: Role select dropdown with human-readable labels
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Role } from "@/types/enums";

interface RoleSelectorProps {
  id?: string;
  value: Role;
  onChange: (role: Role) => void;
  roles?: Role[];
  disabled?: boolean;
}

const DEFAULT_ROLES: Role[] = [
  Role.Student,
  Role.Mentor,
  Role.SuperMentor,
  Role.Alumni,
  Role.ContentAdmin,
  Role.SystemAdmin,
];

export function RoleSelector({
  id = "role-selector",
  value,
  onChange,
  roles = DEFAULT_ROLES,
  disabled = false,
}: RoleSelectorProps) {
  return (
    <select
      id={id}
      value={value}
      disabled={disabled}
      onChange={(e) => onChange(e.target.value as Role)}
      className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm disabled:bg-surface"
    >
      {roles.map((r) => (
        <option key={r} value={r}>
          {ROLE_LABELS[r]}
        </option>
      ))}
    </select>
  );
}
