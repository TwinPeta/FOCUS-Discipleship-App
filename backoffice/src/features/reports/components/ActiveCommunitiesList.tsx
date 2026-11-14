/**
 * src/features/reports/components/ActiveCommunitiesList.tsx
 *
 * WHAT: Most active communities with member count and percentage
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import type { ActiveCommunityStat } from "../queries";

export function ActiveCommunitiesList({
  communities,
}: {
  communities: ActiveCommunityStat[];
}) {
  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div>
        <h2 className="text-base font-semibold text-foreground">
          Most active communities
        </h2>
        <p className="text-xs text-muted">
          Ranked by percentage of members active in the selected period.
        </p>
      </div>

      <div className="space-y-3">
        {communities.map((comm) => (
          <div key={comm.id} className="space-y-1.5">
            <div className="flex items-center justify-between text-sm">
              <div>
                <span className="font-medium text-foreground">{comm.name}</span>
                <span className="ml-2 text-xs text-muted">
                  ({comm.campus} · {comm.memberCount} members)
                </span>
              </div>
              <span className="font-semibold text-foreground">
                {comm.activePercent}%
              </span>
            </div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100">
              <div
                className="h-full rounded-full bg-primary"
                style={{ width: `${comm.activePercent}%` }}
              />
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
