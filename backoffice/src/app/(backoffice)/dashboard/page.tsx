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
    <main className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">Dashboard</h1>
          <p className="mt-1 text-sm text-muted">
            Overview of discipleship activity, pending reviews, and member engagement.
          </p>
        </div>
        <Link
          href={ROUTES.reports}
          className="inline-flex items-center gap-2 rounded-md border border-border bg-white px-3.5 py-2 text-sm font-medium text-foreground hover:bg-slate-50"
        >
          <BarChart3 className="h-4 w-4" aria-hidden="true" />
          <span>Open reports</span>
        </Link>
      </div>

      {error && <ErrorState message={error} onRetry={reload} />}
      {!data && loading && <PanelSkeleton />}
      {data && (
        <>
        <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4" aria-label="Key metrics">
          {data.kpis.map((kpi) => (
            <KpiCard key={kpi.id} kpi={kpi} />
          ))}
        </section>

        <div className="grid gap-6 lg:grid-cols-3">
          <div className="lg:col-span-2">
            <WeeklyActivityChart data={data.weeklyActivity} />
          </div>
          <div>
            <NeedsAttention items={data.needsAttention} />
          </div>
        </div>

        <InactiveMembersList members={data.inactiveMembers} />
        </>
      )}
    </main>
  );
}
