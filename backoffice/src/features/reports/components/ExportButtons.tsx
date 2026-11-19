/**
 * src/features/reports/components/ExportButtons.tsx
 *
 * WHAT: Export PDF and CSV for the current filters (audit logged)
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { Download, FileText } from "lucide-react";
import { exportReportFile, type ReportsData } from "../queries";
import type { ReportFiltersState } from "../schemas";

interface ExportButtonsProps {
  filters: ReportFiltersState;
  data: ReportsData;
}

export function ExportButtons({ filters, data }: ExportButtonsProps) {
  const [status, setStatus] = useState<string | null>(null);

  async function handleExport(format: "csv" | "pdf") {
    setStatus(null);
    await exportReportFile(format, filters, data);
    setStatus(`Exported ${format.toUpperCase()} (recorded in audit log).`);
  }

  return (
    <div className="flex flex-wrap items-center gap-2">
      {status && (
        <span className="text-xs text-ink" role="status">
          {status}
        </span>
      )}
      <button
        type="button"
        onClick={() => handleExport("csv")}
        className="inline-flex items-center gap-1.5 rounded-md border border-border bg-white px-3 py-2 text-xs font-medium text-foreground hover:bg-blue-tint"
      >
        <Download className="h-3.5 w-3.5" aria-hidden="true" />
        <span>Export CSV</span>
      </button>
      <button
        type="button"
        onClick={() => handleExport("pdf")}
        className="inline-flex items-center gap-1.5 rounded-md border border-border bg-white px-3 py-2 text-xs font-medium text-foreground hover:bg-blue-tint"
      >
        <FileText className="h-3.5 w-3.5" aria-hidden="true" />
        <span>Export PDF</span>
      </button>
    </div>
  );
}
