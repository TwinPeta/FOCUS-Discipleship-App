/**
 * src/app/(backoffice)/members/import/page.tsx
 *
 * WHAT: B24 Import users (CSV): 4-step upload, column mapping, review, and idempotent import
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import { ImportStepper } from "@/features/import/components/ImportStepper";

export default function ImportMembersPage() {
  return (
    <div className="mx-auto max-w-4xl space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Import users (CSV)</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Upload a spreadsheet, match columns, review validation results, and
          import members safely.
        </p>
      </div>

      <ImportStepper />
    </div>
  );
}
