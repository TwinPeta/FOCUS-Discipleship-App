/**
 * src/features/reports/components/ReportSummaryCards.tsx
 *
 * WHAT: Four headline numbers for the last 30 days: members, active, meetings attended, reports handled
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import type { ReportsSummary } from "../queries";

function change(pct: number) {
  return `vs previous 30 days: ${pct > 0 ? "+" : ""}${pct}%`;
}

export function ReportSummaryCards({ summary }: { summary: ReportsSummary }) {
  const cards = [
    { label: "Members", value: summary.members.value, note: change(summary.members.changePercent) },
    { label: "Active in the period", value: summary.active.value, note: change(summary.active.changePercent) },
    { label: "Meetings attended", value: summary.meetingsAttended.value, note: change(summary.meetingsAttended.changePercent) },
    { label: "Reports handled", value: summary.reportsHandled.value, note: `Average answer time: ${summary.reportsHandled.averageAnswerHours} h` },
  ];
  return (
    <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4" aria-label="Key numbers">
      {cards.map((c) => (
        <div key={c.label} className="card flex min-w-0 flex-col gap-1">
          <p className="eyebrow">{c.label}</p>
          <p className="text-[34px] font-black leading-none tracking-tight">{c.value.toLocaleString("en-US")}</p>
          <p className="mt-1 text-sm text-muted-foreground">{c.note}</p>
        </div>
      ))}
    </section>
  );
}
