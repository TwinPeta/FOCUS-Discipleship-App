/**
 * src/app/(backoffice)/roles/page.tsx
 *
 * WHAT: Roles & permissions (B9): one card per role, a link to the permissions matrix and staff account creation
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import Link from "next/link";
import { UserPlus } from "lucide-react";
import { AuditPreview } from "@/features/roles/components/AuditPreview";
import { RoleCards } from "@/features/roles/components/RoleCards";
import { ROUTES } from "@/lib/constants/routes";

export default function RolesPage() {
  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Roles &amp; permissions</h1>
          <p>Review access scopes across roles, create staff accounts, and inspect recent audit activity.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2.5">
          <Link href={ROUTES.roleMatrix} className="btn btn-secondary">
            Permissions matrix
          </Link>
          <Link href={ROUTES.roleNew} className="btn btn-secondary">
            Create role
          </Link>
          <Link href={ROUTES.staffNew} className="btn btn-primary">
            <UserPlus className="h-5 w-5" aria-hidden="true" />
            Add staff account
          </Link>
        </div>
      </div>

      <p className="rounded-lg bg-blue-tint px-4 py-3 text-[15px]">
        A role decides what a person sees and can do, in the app and in the Backoffice. A person has <b>one</b> role at a
        time. Changes are recorded in the audit log.
      </p>

      <RoleCards />
      <AuditPreview />
    </div>
  );
}
