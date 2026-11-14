/**
 * src/lib/auth/guards.ts
 *
 * WHAT: requireStaff(), requireRole() helpers for server layouts
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { redirect } from "next/navigation";
import { getHomeRouteForRole, ROUTES } from "@/lib/constants/routes";
import { isStaffRole } from "@/lib/permissions/roles";
import { MemberStatus, type Role } from "@/types/enums";
import type { Session } from "@/types/user";
import { getServerSession } from "./session";

export async function requireStaff(): Promise<Session> {
  const session = await getServerSession();
  if (!session) {
    redirect(ROUTES.login);
  }

  if (session.user.status === MemberStatus.Suspended) {
    redirect(`${ROUTES.login}?error=suspended`);
  }

  if (!isStaffRole(session.user.role)) {
    redirect(ROUTES.forbidden);
  }

  return session;
}

export async function requireRole(allowedRoles: Role[]): Promise<Session> {
  const session = await requireStaff();

  if (!allowedRoles.includes(session.user.role)) {
    redirect(getHomeRouteForRole(session.user.role));
  }

  return session;
}
