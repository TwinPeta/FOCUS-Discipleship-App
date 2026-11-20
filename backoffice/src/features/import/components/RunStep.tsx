/**
 * src/features/import/components/RunStep.tsx
 *
 * WHAT: Step 4 of CSV import: run idempotent import and report results with safe retry
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import type { MappedImportRow } from "@/features/import/csv";
import { runMemberImport, type ImportRunResult } from "@/features/import/queries";
import { ROUTES } from "@/lib/constants/routes";

interface RunStepProps {
  rows: MappedImportRow[];
}

export function RunStep({ rows }: RunStepProps) {
  const [running, setRunning] = useState(true);
  const [result, setResult] = useState<ImportRunResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function execute() {
    setRunning(true);
    setError(null);
    try {
      const res = await runMemberImport(rows);
      setResult(res);
    } catch {
      setError("Import failed. You can safely retry without creating duplicates.");
    } finally {
      setRunning(false);
    }
  }

  useEffect(() => {
    void execute();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (running) {
    return (
      <p className="text-sm text-muted-foreground">
        Importing {rows.length} member{rows.length === 1 ? "" : "s"}...
      </p>
    );
  }

  if (error) {
    return (
      <div className="space-y-4">
        <div
          role="alert"
          className="rounded-md border border-danger/40 bg-danger-soft px-4 py-3 text-sm text-danger"
        >
          {error}
        </div>
        <button
          type="button"
          onClick={execute}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95"
        >
          Retry import
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div
        role="status"
        className="rounded-md border border-blue/30 bg-blue-soft px-4 py-3 text-sm text-ink"
      >
        Import complete: <strong>{result?.createdCount ?? 0}</strong> created,{" "}
        <strong>{result?.skippedCount ?? 0}</strong> skipped.
      </div>

      <Link
        href={ROUTES.members}
        className="inline-block rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground"
      >
        View members
      </Link>
    </div>
  );
}
