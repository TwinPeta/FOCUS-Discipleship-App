/**
 * src/features/audit/components/ExportAuditButton.tsx
 *
 * WHAT: Export the log (the export itself is audited)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { Download } from "lucide-react";
import { recordAndBuildAuditCsv, type AuditEntry } from "../queries";

export function ExportAuditButton({ entries }: { entries: AuditEntry[] }) {
  const [exporting, setExporting] = useState(false);
  const [exportedNote, setExportedNote] = useState<string | null>(null);

  async function handleExport() {
    setExporting(true);
    setExportedNote(null);
    try {
      const csv = await recordAndBuildAuditCsv(entries);
      const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `focus-audit-log-${new Date().toISOString().slice(0, 10)}.csv`;
      link.click();
      URL.revokeObjectURL(url);
      setExportedNote(`Exported ${entries.length} entries (recorded in audit log).`);
    } finally {
      setExporting(false);
    }
  }

  return (
    <div className="flex flex-wrap items-center gap-3">
      {exportedNote && (
        <span className="text-xs text-ink" role="status">
          {exportedNote}
        </span>
      )}
      <button
        type="button"
        onClick={handleExport}
        disabled={exporting || entries.length === 0}
        className="inline-flex items-center gap-2 rounded-md border border-border bg-white px-3.5 py-2 text-sm font-medium text-foreground hover:bg-blue-tint disabled:opacity-50"
      >
        <Download className="h-4 w-4" aria-hidden="true" />
        <span>{exporting ? "Exporting…" : "Export CSV"}</span>
      </button>
    </div>
  );
}
