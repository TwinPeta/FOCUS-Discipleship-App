/**
 * src/features/reports/components/ScheduledReportsTable.tsx
 *
 * WHAT: Scheduled reports list: cadence, recipients, active toggle
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import type { ScheduledReport } from "../queries";

interface ScheduledReportsTableProps {
  schedules: ScheduledReport[];
  onToggleActive: (id: string) => void | Promise<void>;
}

export function ScheduledReportsTable({
  schedules,
  onToggleActive,
}: ScheduledReportsTableProps) {
  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div>
        <h2 className="text-base font-semibold text-foreground">
          Scheduled reports
        </h2>
        <p className="text-xs text-muted">
          Automated summary emails delivered to FOCUS leadership and regional coordinators.
        </p>
      </div>

      {schedules.length === 0 ? (
        <p className="text-sm text-muted">No scheduled reports configured yet.</p>
      ) : (
        <div className="overflow-x-auto rounded-lg border border-border">
          <table className="w-full border-collapse text-left text-sm">
            <thead>
              <tr className="border-b border-border bg-slate-50 text-xs font-semibold uppercase tracking-wide text-muted">
                <th className="px-4 py-2.5">Report</th>
                <th className="px-4 py-2.5">Cadence</th>
                <th className="px-4 py-2.5">Recipient</th>
                <th className="px-4 py-2.5 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {schedules.map((s) => (
                <tr key={s.id}>
                  <td className="px-4 py-2.5 font-medium text-foreground">
                    {s.reportLabel}
                  </td>
                  <td className="px-4 py-2.5 capitalize text-muted">{s.cadence}</td>
                  <td className="px-4 py-2.5 text-foreground">{s.recipientEmail}</td>
                  <td className="px-4 py-2.5 text-right">
                    <button
                      type="button"
                      onClick={() => onToggleActive(s.id)}
                      className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        s.active
                          ? "bg-emerald-50 text-emerald-800"
                          : "bg-slate-100 text-muted"
                      }`}
                    >
                      {s.active ? "Active" : "Paused"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
