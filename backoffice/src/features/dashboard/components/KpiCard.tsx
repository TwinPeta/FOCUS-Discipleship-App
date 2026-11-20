/**
 * src/features/dashboard/components/KpiCard.tsx
 *
 * WHAT: KPI card with value and change versus previous 30 days
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import type { DashboardKpi } from "../queries";

export function KpiCard({ kpi }: { kpi: DashboardKpi }) {
  const sign = kpi.changePercent > 0 ? "+" : "";

  return (
    <div className="card flex min-w-0 flex-col gap-1">
      <p className="eyebrow">{kpi.label}</p>
      <p className="text-[34px] font-black leading-none tracking-tight">{kpi.value}</p>
      <p className="mt-1 text-sm text-muted-foreground">
        {kpi.helper ?? "vs previous 30 days"}: {sign}
        {kpi.changePercent}%
      </p>
    </div>
  );
}
