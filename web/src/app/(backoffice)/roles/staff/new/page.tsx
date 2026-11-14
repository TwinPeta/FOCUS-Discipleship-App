/**
 * src/app/(backoffice)/roles/staff/new/page.tsx
 *
 * WHAT: Add staff account (content admin, system admin, super-mentor)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { StaffAccountForm } from "@/features/roles/components/StaffAccountForm";

export default function NewStaffAccountPage() {
  return (
    <main className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-foreground">
          Add staff account
        </h1>
        <p className="mt-1 text-sm text-muted">
          Provision a backoffice account for a Super-mentor, Content admin, or System admin.
        </p>
      </div>

      <StaffAccountForm />
    </main>
  );
}
