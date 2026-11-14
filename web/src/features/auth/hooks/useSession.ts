/**
 * src/features/auth/hooks/useSession.ts
 *
 * WHAT: Current staff user, role, scope (community ids) from the session
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { useSessionContext } from "@/providers/SessionProvider";
import { getUserCommunityIds } from "@/lib/permissions/scope";

export function useSession() {
  const { session, user } = useSessionContext();
  const communityIds = getUserCommunityIds(user);

  return {
    session,
    user,
    role: user?.role ?? null,
    communityIds,
    isAuthenticated: Boolean(user),
  };
}
