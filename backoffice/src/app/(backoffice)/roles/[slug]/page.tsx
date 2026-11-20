/**
 * src/app/(backoffice)/roles/[slug]/page.tsx
 *
 * WHAT: Role details (B32): edit a role's permissions; custom roles can also be renamed or deleted
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { use, useCallback } from "react";
import Link from "next/link";
import { PageHeader } from "@/components/layout/PageHeader";
import { ErrorState } from "@/components/feedback/ErrorState";
import { fetchRoleDef, fetchRoles } from "@/features/roles/api";
import { RoleForm } from "@/features/roles/components/RoleForm";
import { ROUTES } from "@/lib/constants/routes";
import { useRemoteData } from "@/lib/hooks/useRemoteData";

export default function RoleDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = use(params);
  const load = useCallback(async () => {
    const [role, all] = await Promise.all([fetchRoleDef(slug), fetchRoles()]);
    return { role, modules: all.modules };
  }, [slug]);
  const { data, error, reload } = useRemoteData(load);

  return (
    <div className="flex flex-col gap-5">
      <PageHeader title={data?.role.name ?? "Role"} backHref={ROUTES.roles} backLabel="Back to roles">
        <Link href={ROUTES.roleMatrix} className="btn btn-secondary">
          Permissions matrix
        </Link>
      </PageHeader>
      {error && <ErrorState message={error} onRetry={reload} />}
      {data && <RoleForm key={data.role.id + data.role.people} modules={data.modules} role={data.role} />}
    </div>
  );
}
