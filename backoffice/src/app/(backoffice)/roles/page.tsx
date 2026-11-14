/**
 * src/app/(backoffice)/roles/page.tsx
 *
 * WHAT: B9 Roles and audit: permission matrix, add staff account, recent audit entries
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import Link from "next/link";
import { UserPlus } from "lucide-react";
import { AuditPreview } from "@/features/roles/components/AuditPreview";
import { PermissionMatrix } from "@/features/roles/components/PermissionMatrix";
import { ROUTES } from "@/lib/constants/routes";

export default function RolesPage() {
  return (
    <main className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">
            Roles &amp; permissions
          </h1>
          <p className="mt-1 text-sm text-muted">
            Review access scopes across FOCUS roles, create staff accounts, and inspect recent audit activity.
          </p>
        </div>
        <Link
          href={ROUTES.staffNew}
          className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90"
        >
          <UserPlus className="h-4 w-4" aria-hidden="true" />
          <span>Add staff account</span>
        </Link>
      </div>

      <PermissionMatrix />
      <AuditPreview />
    </main>
  );
}
