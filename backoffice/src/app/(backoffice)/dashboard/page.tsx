/**
 * src/app/(backoffice)/dashboard/page.tsx
 *
 * WHAT: B1 Dashboard: KPIs, weekly activity, needs-your-attention counts, inactive members with reminders
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { BarChart3 } from "lucide-react";
import { InactiveMembersList } from "@/features/dashboard/components/InactiveMembersList";
import { KpiCard } from "@/features/dashboard/components/KpiCard";
import { NeedsAttention } from "@/features/dashboard/components/NeedsAttention";
import { WeeklyActivityChart } from "@/features/dashboard/components/WeeklyActivityChart";
import {
  fetchDashboardData,
} from "@/features/dashboard/queries";
import { ErrorState } from "@/components/feedback/ErrorState";
import { PanelSkeleton } from "@/components/feedback/Skeletons";
import { ROUTES } from "@/lib/constants/routes";
import { useRemoteData } from "@/lib/hooks/useRemoteData";

export default function DashboardPage() {
  const { data, loading, error, reload } = useRemoteData(fetchDashboardData);

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-[34px] leading-[1.05]">Dashboard</h1>
        <Link href={ROUTES.reports} className="btn btn-primary">
          <BarChart3 className="h-[18px] w-[18px]" aria-hidden="true" />
          <span>Open reports</span>
        </Link>
      </div>

      {error && <ErrorState message={error} onRetry={reload} />}
      {!data && loading && <PanelSkeleton />}
      {data && (
        <>
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label="Key metrics">
            {data.kpis.map((kpi) => (
              <KpiCard key={kpi.id} kpi={kpi} />
            ))}
          </section>

          <div className="grid gap-4 lg:grid-cols-[1.45fr_1fr]">
            <WeeklyActivityChart data={data.weeklyActivity} />
            <NeedsAttention items={data.needsAttention} />
          </div>

          <InactiveMembersList members={data.inactiveMembers} />
        </>
      )}
    </div>
  );
}
