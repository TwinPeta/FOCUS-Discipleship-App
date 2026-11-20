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
  /** "chips" shows the roles as radio pills (Add user); "select" is the compact dropdown */
  variant?: "select" | "chips";
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
  variant = "select",
}: RoleSelectorProps) {
  if (variant === "chips") {
    return (
      <div role="radiogroup" id={id} className="flex flex-wrap gap-2.5">
        {roles.map((r) => {
          const selected = r === value;
          return (
            <button
              key={r}
              type="button"
              role="radio"
              aria-checked={selected}
              disabled={disabled}
              onClick={() => onChange(r)}
              className={`inline-flex min-h-[40px] items-center gap-2 rounded-full px-3.5 text-base font-bold ${
                selected ? "border-2 border-ink bg-grad-yellow" : "border-2 border-ink bg-white font-semibold"
              }`}
            >
              <span className="grid h-[18px] w-[18px] place-items-center rounded-full border-2 border-ink bg-white">
                {selected && <span className="h-2 w-2 rounded-full bg-ink" />}
              </span>
              {ROLE_LABELS[r]}
            </button>
          );
        })}
      </div>
    );
  }

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
