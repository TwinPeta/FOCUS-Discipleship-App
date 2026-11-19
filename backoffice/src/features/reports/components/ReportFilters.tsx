/**
 * src/features/reports/components/ReportFilters.tsx
 *
 * WHAT: Date range, campus and community filters kept in URL params
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import { useLookups } from "@/lib/hooks/useLookups";
import type { ReportFiltersState } from "../schemas";

interface ReportFiltersProps {
  value: ReportFiltersState;
  onChange: (next: ReportFiltersState) => void;
}

export function ReportFilters({ value, onChange }: ReportFiltersProps) {
  const { institutions, communities } = useLookups();
  return (
    <div className="grid gap-3 rounded-xl border border-border bg-white p-4 sm:grid-cols-3">
      <div className="space-y-1">
        <label htmlFor="report-range" className="block text-[13px] font-extrabold">
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
        <label htmlFor="report-campus" className="block text-[13px] font-extrabold">
          Campus
        </label>
        <select
          id="report-campus"
          value={value.campus}
          onChange={(e) => onChange({ ...value, campus: e.target.value })}
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="all">All campuses</option>
          {institutions.map((i) => (
            <option key={i.id} value={i.id}>
              {i.name}
            </option>
          ))}
        </select>
      </div>

      <div className="space-y-1">
        <label htmlFor="report-community" className="block text-[13px] font-extrabold">
          Caregroup
        </label>
        <select
          id="report-community"
          value={value.community}
          onChange={(e) => onChange({ ...value, community: e.target.value })}
          className="w-full rounded-md border border-border bg-white px-3 py-1.5 text-sm text-foreground"
        >
          <option value="all">All caregroups</option>
          {communities.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}
