/**
 * src/lib/permissions/roles.ts
 *
 * WHAT: Role definitions and which area each role enters (backoffice or my-community)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Role, StaffRoles } from "@/types/enums";

export type AppShellKind = "backoffice" | "my-community";

export const ROLE_LABELS: Record<Role, string> = {
  [Role.Student]: "Student",
  [Role.Mentor]: "Mentor",
  [Role.SuperMentor]: "Super-mentor",
  [Role.Alumni]: "Alumni",
  [Role.ContentAdmin]: "Content admin",
  [Role.SystemAdmin]: "System admin",
};

export function isStaffRole(role: Role | string | null | undefined): role is Role {
  if (!role) return false;
  return StaffRoles.includes(role as Role);
}

export function getShellForRole(role: Role | null | undefined): AppShellKind | null {
  if (!role) return null;
  if (role === Role.SuperMentor) return "my-community";
  if (role === Role.ContentAdmin || role === Role.SystemAdmin) return "backoffice";
  return null;
}
