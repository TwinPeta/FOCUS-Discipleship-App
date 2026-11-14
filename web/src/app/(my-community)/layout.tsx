/**
 * src/app/(my-community)/layout.tsx
 *
 * WHAT: Super-mentor shell: My community, Join requests, Members, Moderation, Resources; scoped to one community
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { AppShell } from "@/components/layout/AppShell";
import { requireRole } from "@/lib/auth/guards";
import { SessionProvider } from "@/providers/SessionProvider";
import { Role } from "@/types/enums";

export default async function MyCommunityLayout({
  children,
}: {
  children: ReactNode;
}) {
  const session = await requireRole([Role.SuperMentor]);

  return (
    <SessionProvider session={session}>
      <AppShell>{children}</AppShell>
    </SessionProvider>
  );
}
