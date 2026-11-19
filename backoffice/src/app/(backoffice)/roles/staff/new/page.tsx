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
    <div className="flex max-w-3xl flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">
          Add staff account
        </h1>
        <p className="mt-1 text-sm text-muted">
          Provision a backoffice account for a Super-mentor, Content admin, or System admin.
        </p>
      </div>

      <StaffAccountForm />
    </div>
  );
}
