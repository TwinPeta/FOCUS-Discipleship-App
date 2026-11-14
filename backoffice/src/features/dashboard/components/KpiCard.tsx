/**
 * src/features/dashboard/components/KpiCard.tsx
 *
 * WHAT: KPI card with value and change versus previous 30 days
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import { TrendingDown, TrendingUp } from "lucide-react";
import type { DashboardKpi } from "../queries";

export function KpiCard({ kpi }: { kpi: DashboardKpi }) {
  const positive = kpi.changePercent >= 0;

  return (
    <div className="rounded-xl border border-border bg-white p-4">
      <p className="text-xs font-medium text-muted">{kpi.label}</p>
      <div className="mt-2 flex items-baseline justify-between gap-2">
        <span className="text-2xl font-semibold text-foreground">{kpi.value}</span>
        <span
          className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${
            positive
              ? "bg-emerald-50 text-emerald-700"
              : "bg-rose-50 text-rose-700"
          }`}
        >
          {positive ? (
            <TrendingUp className="h-3 w-3" aria-hidden="true" />
          ) : (
            <TrendingDown className="h-3 w-3" aria-hidden="true" />
          )}
          <span>
            {positive ? "+" : ""}
            {kpi.changePercent}%
          </span>
        </span>
      </div>
      <p className="mt-1 text-[11px] text-muted">
        {kpi.helper ?? "vs. previous 30 days"}
      </p>
    </div>
  );
}
