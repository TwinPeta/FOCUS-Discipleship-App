/**
 * src/lib/permissions/scope.ts
 *
 * WHAT: Scope rules: super-mentors limited to their own community
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Role } from "@/types/enums";
import type { SessionUser } from "@/types/user";

type ScopedUser =
  | Pick<SessionUser, "role" | "communityId" | "communityIds">
  | null
  | undefined;

export function isCommunityScopedRole(role: Role | null | undefined): boolean {
  return role === Role.SuperMentor || role === Role.Mentor;
}

export function getUserCommunityIds(user: ScopedUser): string[] {
  if (!user) return [];
  const ids = new Set<string>();
  if (user.communityId) ids.add(user.communityId);
  for (const id of user.communityIds ?? []) {
    if (id) ids.add(id);
  }
  return Array.from(ids);
}

export function canAccessCommunity(
  user: ScopedUser,
  targetCommunityId: string | null | undefined,
): boolean {
  if (!user) return false;
  if (user.role === Role.SystemAdmin || user.role === Role.ContentAdmin) {
    return true;
  }
  if (!isCommunityScopedRole(user.role) || !targetCommunityId) {
    return false;
  }
  return getUserCommunityIds(user).includes(targetCommunityId);
}

export function filterByScope<T extends { communityId?: string | null }>(
  user: ScopedUser,
  items: T[],
): T[] {
  if (!user) return [];
  if (user.role === Role.SystemAdmin || user.role === Role.ContentAdmin) {
    return items;
  }
  if (!isCommunityScopedRole(user.role)) {
    return [];
  }
  const allowed = new Set(getUserCommunityIds(user));
  return items.filter((item) => item.communityId && allowed.has(item.communityId));
}

export function shouldHideCrossCommunityControls(user: ScopedUser): boolean {
  if (!user) return true;
  return isCommunityScopedRole(user.role);
}
