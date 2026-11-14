/**
 * src/lib/permissions/can.ts
 *
 * WHAT: can(user, resource, action) helper for hiding or showing UI
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import type { SessionUser } from "@/types/user";
import {
  PERMISSION_MATRIX,
  type PermissionAction,
  type PermissionResource,
} from "./matrix";

type UserWithRole = Pick<SessionUser, "role"> | null | undefined;

export function can(
  user: UserWithRole,
  resource: PermissionResource,
  action: PermissionAction,
): boolean {
  if (!user?.role) return false;
  const roleRules = PERMISSION_MATRIX[user.role];
  const rule = roleRules?.[resource];
  if (!rule) return false;

  if (rule.actions.includes("administer")) {
    return true;
  }

  return rule.actions.includes(action);
}

export function isOwnCommunityOnly(
  user: UserWithRole,
  resource: PermissionResource,
): boolean {
  if (!user?.role) return true;
  const rule = PERMISSION_MATRIX[user.role]?.[resource];
  return Boolean(rule?.ownOnly);
}
