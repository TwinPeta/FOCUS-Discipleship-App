/**
 * src/features/import/queries.ts
 *
 * WHAT: Idempotent member CSV import mutation
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import type { MappedImportRow } from "./csv";

export interface ImportRunResult {
  createdCount: number;
  skippedCount: number;
  failedRows: { rowNumber: number; error: string }[];
}

export async function runMemberImport(
  rows: MappedImportRow[],
): Promise<ImportRunResult> {
  const res = await fetch("/api/proxy/members/import", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ rows }),
  });

  if (!res.ok) {
    throw new Error("Member import failed");
  }

  return (await res.json()) as ImportRunResult;
}
