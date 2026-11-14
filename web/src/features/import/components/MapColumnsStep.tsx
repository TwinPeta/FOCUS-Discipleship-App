/**
 * src/features/import/components/MapColumnsStep.tsx
 *
 * WHAT: Step 2 of CSV import: map CSV headers to member fields
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import {
  IMPORT_TARGET_FIELDS,
  type ColumnMapping,
  type ImportTargetField,
} from "@/features/import/csv";

const FIELD_LABELS: Record<ImportTargetField, string> = {
  fullName: "Full name (required)",
  email: "Email (required)",
  phone: "Phone",
  institution: "Institution",
  community: "Community",
  role: "Role",
};

interface MapColumnsStepProps {
  headers: string[];
  mapping: ColumnMapping;
  onChange: (mapping: ColumnMapping) => void;
  onBack: () => void;
  onNext: () => void;
}

export function MapColumnsStep({
  headers,
  mapping,
  onChange,
  onBack,
  onNext,
}: MapColumnsStepProps) {
  const canProceed = Boolean(mapping.fullName && mapping.email);

  return (
    <div className="space-y-4">
      <p className="text-sm text-muted-foreground">
        Match your CSV columns to the fields below.
      </p>

      <div className="grid gap-4 sm:grid-cols-2">
        {IMPORT_TARGET_FIELDS.map((field) => (
          <div key={field} className="space-y-1.5">
            <label htmlFor={`map-${field}`} className="block text-sm font-medium text-foreground">
              {FIELD_LABELS[field]}
            </label>
            <select
              id={`map-${field}`}
              value={mapping[field] ?? ""}
              onChange={(e) =>
                onChange({ ...mapping, [field]: e.target.value || undefined })
              }
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            >
              <option value="">Not mapped</option>
              {headers.map((header) => (
                <option key={header} value={header}>
                  {header}
                </option>
              ))}
            </select>
          </div>
        ))}
      </div>

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
          disabled={!canProceed}
          onClick={onNext}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          Review rows
        </button>
      </div>
    </div>
  );
}
