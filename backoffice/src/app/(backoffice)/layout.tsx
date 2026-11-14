/**
 * src/app/(backoffice)/layout.tsx
 *
 * WHAT: Back office shell for content admins and system admins: sidebar by role, header, session guard
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { requireRole } from "@/lib/auth/guards";
import { SessionProvider } from "@/providers/SessionProvider";
import { Role } from "@/types/enums";

export default async function BackofficeLayout({
  children,
}: {
  children: ReactNode;
}) {
  const session = await requireRole([Role.SystemAdmin, Role.ContentAdmin]);

  return (
    <SessionProvider session={session}>
      <AppShell>{children}</AppShell>
    </SessionProvider>
  );
}
