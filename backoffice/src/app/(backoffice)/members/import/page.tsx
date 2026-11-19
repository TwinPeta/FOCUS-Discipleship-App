/**
 * src/app/(backoffice)/members/import/page.tsx
 *
 * WHAT: Import users (B24): add-one / import tabs and the four-step CSV import
 * REQUIREMENTS: FR-05
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import Link from "next/link";
import { PageHeader } from "@/components/layout/PageHeader";
import { ImportStepper } from "@/features/import/components/ImportStepper";
import { ROUTES } from "@/lib/constants/routes";

export default function ImportMembersPage() {
  return (
    <div className="flex flex-col gap-5">
      <PageHeader
        title="Import users"
        description="Upload a spreadsheet, match columns, review validation results, and import members safely."
        backHref={ROUTES.members}
        backLabel="Back to members"
      />

      <div className="flex flex-wrap gap-2" role="tablist">
        <Link href={ROUTES.memberNew} role="tab" aria-selected="false" className="tab">
          Add one user
        </Link>
        <button type="button" role="tab" aria-selected="true">
          Import from a file
        </button>
      </div>

      <ImportStepper />
    </div>
  );
}
