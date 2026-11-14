/**
 * src/features/import/components/ImportStepper.tsx
 *
 * WHAT: 4-step CSV import stepper (Upload -> Map columns -> Review -> Import)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import {
  autoMatchColumns,
  validateImportRows,
  type ColumnMapping,
  type ParsedCsv,
} from "@/features/import/csv";
import { MapColumnsStep } from "./MapColumnsStep";
import { ReviewStep } from "./ReviewStep";
import { RunStep } from "./RunStep";
import { UploadStep } from "./UploadStep";

const STEPS = ["1. Upload CSV", "2. Match columns", "3. Review rows", "4. Import"] as const;

export function ImportStepper() {
  const [step, setStep] = useState(0);
  const [fileName, setFileName] = useState("");
  const [parsed, setParsed] = useState<ParsedCsv | null>(null);
  const [mapping, setMapping] = useState<ColumnMapping>({});

  const validation = parsed
    ? validateImportRows(parsed.rows, mapping)
    : { validRows: [], invalidRows: [], duplicateEmails: [] };

  return (
    <div className="space-y-6">
      <ol className="grid grid-cols-2 gap-2 sm:grid-cols-4">
        {STEPS.map((label, idx) => (
          <li
            key={label}
            className={`rounded-md border px-3 py-2 text-xs font-semibold ${
              idx === step
                ? "border-primary bg-primary-soft text-foreground"
                : idx < step
                  ? "border-emerald-300 bg-emerald-50 text-emerald-900"
                  : "border-border bg-surface text-muted-foreground"
            }`}
          >
            {label}
          </li>
        ))}
      </ol>

      <div className="rounded-card border border-border bg-white p-6">
        {step === 0 && (
          <UploadStep
            onParsed={(data, name) => {
              setParsed(data);
              setFileName(name);
              setMapping(autoMatchColumns(data.headers));
              setStep(1);
            }}
          />
        )}

        {step === 1 && parsed && (
          <div className="space-y-4">
            <p className="text-xs text-muted-foreground">
              File: <strong>{fileName}</strong> ({parsed.rows.length} rows)
            </p>
            <MapColumnsStep
              headers={parsed.headers}
              mapping={mapping}
              onChange={setMapping}
              onBack={() => setStep(0)}
              onNext={() => setStep(2)}
            />
          </div>
        )}

        {step === 2 && (
          <ReviewStep
            validation={validation}
            onBack={() => setStep(1)}
            onNext={() => setStep(3)}
          />
        )}

        {step === 3 && <RunStep rows={validation.validRows} />}
      </div>
    </div>
  );
}
