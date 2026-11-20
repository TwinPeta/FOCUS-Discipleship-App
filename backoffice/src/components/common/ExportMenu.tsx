/**
 * src/components/common/ExportMenu.tsx
 *
 * WHAT: Export actions (CSV, PDF) with standard audit notice
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { Download, FileText } from "lucide-react";

interface ExportMenuProps {
  onExportCsv?: () => void;
  onExportPdf?: () => void;
  disabled?: boolean;
}

export function ExportMenu({
  onExportCsv,
  onExportPdf,
  disabled = false,
}: ExportMenuProps) {
  const [exportNotice, setExportNotice] = useState<string | null>(null);

  function handleCsv() {
    setExportNotice("Exported CSV (recorded in audit log).");
    onExportCsv?.();
  }

  function handlePdf() {
    setExportNotice("Exported PDF (recorded in audit log).");
    onExportPdf?.();
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {exportNotice && (
        <span className="text-[11px] text-ink font-medium" role="status">
          {exportNotice}
        </span>
      )}
      {onExportCsv && (
        <button
          type="button"
          onClick={handleCsv}
          disabled={disabled}
          className="inline-flex items-center gap-1.5 rounded-md border border-border bg-white px-3 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint disabled:opacity-50 transition"
        >
          <Download className="h-3.5 w-3.5" />
          <span>Export CSV</span>
        </button>
      )}
      {onExportPdf && (
        <button
          type="button"
          onClick={handlePdf}
          disabled={disabled}
          className="inline-flex items-center gap-1.5 rounded-md border border-border bg-white px-3 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint disabled:opacity-50 transition"
        >
          <FileText className="h-3.5 w-3.5" />
          <span>Export PDF</span>
        </button>
      )}
    </div>
  );
}
