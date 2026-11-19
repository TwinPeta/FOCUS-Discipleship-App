/**
 * src/features/import/components/UploadStep.tsx
 *
 * WHAT: Step 1 of CSV import: select and parse a CSV file
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState, type ChangeEvent } from "react";
import { parseCsvText, type ParsedCsv } from "@/features/import/csv";

interface UploadStepProps {
  onParsed: (parsed: ParsedCsv, fileName: string) => void;
}

export function UploadStep({ onParsed }: UploadStepProps) {
  const [error, setError] = useState<string | null>(null);

  async function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    setError(null);
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.name.toLowerCase().endsWith(".csv")) {
      setError("Please select a .csv file.");
      return;
    }

    const text = await file.text();
    const parsed = parseCsvText(text);
    if (parsed.headers.length === 0 || parsed.rows.length === 0) {
      setError("The CSV file appears to be empty or has no header row.");
      return;
    }

    onParsed(parsed, file.name);
  }

  return (
    <div className="space-y-4">
      <div>
        <label htmlFor="csv-upload" className="block text-[13px] font-extrabold">
          Upload members CSV
        </label>
        <p className="mt-1 text-xs text-muted-foreground">
          Include columns for full name, email, phone, campus, caregroup, and role.
        </p>
      </div>

      <input
        id="csv-upload"
        type="file"
        accept=".csv,text/csv"
        onChange={handleFileChange}
        className="block w-full text-sm text-foreground file:mr-3 file:rounded-md file:border file:border-border file:bg-surface file:px-3 py-1.5 file:text-xs file:font-medium hover:file:bg-primary-soft"
      />

      {error && (
        <p role="alert" className="text-xs text-danger">
          {error}
        </p>
      )}
    </div>
  );
}
