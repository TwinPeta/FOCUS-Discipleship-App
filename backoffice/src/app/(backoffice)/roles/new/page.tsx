/**
 * src/app/(backoffice)/roles/new/page.tsx
 *
 * WHAT: Create role: name, how its people sign in, and which modules they can use
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { PageHeader } from "@/components/layout/PageHeader";
import { useRemoteData } from "@/lib/hooks/useRemoteData";
import { fetchRoles } from "@/features/roles/api";
import { RoleForm } from "@/features/roles/components/RoleForm";
import { ROUTES } from "@/lib/constants/routes";

export default function NewRolePage() {
  const { data } = useRemoteData(fetchRoles);
  return (
    <div className="flex flex-col gap-5">
      <PageHeader title="Create role" backHref={ROUTES.roles} backLabel="Back to roles" />
      {data && <RoleForm modules={data.modules} />}
    </div>
  );
}
