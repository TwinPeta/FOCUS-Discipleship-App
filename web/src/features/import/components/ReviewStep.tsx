/**
 * src/features/import/components/ReviewStep.tsx
 *
 * WHAT: Step 3 of CSV import: review valid rows and rows with validation problems
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import type { ImportValidationResult } from "@/features/import/csv";

interface ReviewStepProps {
  validation: ImportValidationResult;
  onBack: () => void;
  onNext: () => void;
}

export function ReviewStep({ validation, onBack, onNext }: ReviewStepProps) {
  const { validRows, invalidRows } = validation;

  return (
    <div className="space-y-4">
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="rounded-md border border-emerald-200 bg-emerald-50 p-3 text-sm">
          <p className="font-semibold text-emerald-900">
            {validRows.length} ready to import
          </p>
        </div>
        <div className="rounded-md border border-amber-200 bg-amber-50 p-3 text-sm">
          <p className="font-semibold text-amber-900">
            {invalidRows.length} skipped (problems found)
          </p>
        </div>
      </div>

      {invalidRows.length > 0 && (
        <div className="overflow-x-auto rounded-md border border-border">
          <table className="w-full text-left text-xs">
            <thead className="border-b border-border bg-surface text-muted-foreground">
              <tr>
                <th className="px-3 py-2">Row</th>
                <th className="px-3 py-2">Problems</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {invalidRows.map((row) => (
                <tr key={row.rowNumber}>
                  <td className="px-3 py-2 font-medium">#{row.rowNumber}</td>
                  <td className="px-3 py-2 text-red-700">{row.errors.join("; ")}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="flex items-center justify-between pt-2">
        <button
          type="button"
          onClick={onBack}
          className="rounded-md border border-border px-4 py-2 text-sm font-medium hover:bg-surface"
        >
          Back
        </button>
        <button
          type="button"
          disabled={validRows.length === 0}
          onClick={onNext}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          Import {validRows.length} member{validRows.length === 1 ? "" : "s"}
        </button>
      </div>
    </div>
  );
}
