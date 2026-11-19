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

const STEPS = ["Upload", "Match columns", "Review", "Import"] as const;

export function ImportStepper() {
  const [step, setStep] = useState(0);
  const [fileName, setFileName] = useState("");
  const [parsed, setParsed] = useState<ParsedCsv | null>(null);
  const [mapping, setMapping] = useState<ColumnMapping>({});

  const validation = parsed
    ? validateImportRows(parsed.rows, mapping)
    : { validRows: [], invalidRows: [], duplicateEmails: [] };

  return (
    <div className="flex flex-col gap-5">
      <ol className="flex flex-wrap items-center gap-x-5 gap-y-2" aria-label="Import steps">
        {STEPS.map((label, idx) => (
          <li key={label} aria-current={idx === step ? "step" : undefined} className="flex items-center gap-2.5">
            <span
              className={`grid h-8 w-8 place-items-center rounded-full border-2 border-ink text-sm font-black ${
                idx === step ? "bg-grad-yellow" : idx < step ? "bg-blue text-white" : "bg-white"
              }`}
            >
              {idx + 1}
            </span>
            <span className={`text-base ${idx === step ? "font-extrabold" : "font-semibold"}`}>{label}</span>
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
