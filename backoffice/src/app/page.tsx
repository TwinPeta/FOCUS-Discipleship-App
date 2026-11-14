/**
 * src/app/page.tsx
 *
 * WHAT: Root: redirects signed-in staff to their home (dashboard or my-community), others to /login
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { redirect } from "next/navigation";
import { getServerSession } from "@/lib/auth/session";
import { getHomeRouteForRole, ROUTES } from "@/lib/constants/routes";

export default async function Home() {
  const session = await getServerSession();
  if (!session) {
    redirect(ROUTES.login);
  }
  redirect(getHomeRouteForRole(session.user.role));
}
