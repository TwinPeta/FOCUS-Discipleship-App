/**
 * src/features/reports/components/ReportFilters.tsx
 *
 * WHAT: Date range, campus and community filters kept in URL params
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import type { ReportFiltersState } from "../schemas";

interface ReportFiltersProps {
  value: ReportFiltersState;
  onChange: (next: ReportFiltersState) => void;
}

export function ReportFilters({ value, onChange }: ReportFiltersProps) {
  return (
    <div className="grid gap-3 rounded-xl border border-border bg-white p-4 sm:grid-cols-3">
      <div className="space-y-1">
        <label htmlFor="report-range" className="block text-xs font-medium text-muted">
          Date range
        </label>
        <select
          id="report-range"
          value={value.range}
          onChange={(e) =>
            onChange({
              ...value,
              range: e.target.value as ReportFiltersState["range"],
            })
          }
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="7d">Last 7 days</option>
          <option value="30d">Last 30 days</option>
          <option value="90d">Last 90 days</option>
          <option value="12m">Last 12 months</option>
        </select>
      </div>

      <div className="space-y-1">
        <label htmlFor="report-campus" className="block text-xs font-medium text-muted">
          Campus / Region
        </label>
        <select
          id="report-campus"
          value={value.campus}
          onChange={(e) => onChange({ ...value, campus: e.target.value })}
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="all">All campuses</option>
          <option value="kampala-central">Kampala Central</option>
          <option value="kampala-east">Kampala East</option>
          <option value="northern">Northern Region</option>
        </select>
      </div>

      <div className="space-y-1">
        <label htmlFor="report-community" className="block text-xs font-medium text-muted">
          Community
        </label>
        <select
          id="report-community"
          value={value.community}
          onChange={(e) => onChange({ ...value, community: e.target.value })}
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="all">All communities</option>
          <option value="comm-makerere">Makerere University</option>
          <option value="comm-kyambogo">Kyambogo University</option>
          <option value="comm-mubs">MUBS Kampala</option>
          <option value="comm-gulu">Gulu University</option>
        </select>
      </div>
    </div>
  );
}
