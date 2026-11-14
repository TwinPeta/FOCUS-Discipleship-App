/**
 * src/features/dashboard/components/WeeklyActivityChart.tsx
 *
 * WHAT: Logins and completions chart (Recharts)
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { WeeklyActivityPoint } from "../queries";

export function WeeklyActivityChart({
  data,
}: {
  data: WeeklyActivityPoint[];
}) {
  return (
    <section className="rounded-xl border border-border bg-white p-5">
      <div className="mb-4">
        <h2 className="text-base font-semibold text-foreground">
          Weekly activity
        </h2>
        <p className="text-xs text-muted">
          Daily member logins and discipleship module completions over the past 7 days.
        </p>
      </div>

      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
            <XAxis dataKey="day" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            <Bar dataKey="logins" name="Logins" fill="#1d4ed8" radius={[4, 4, 0, 0]} />
            <Bar
              dataKey="completions"
              name="Completions"
              fill="#10b981"
              radius={[4, 4, 0, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}
