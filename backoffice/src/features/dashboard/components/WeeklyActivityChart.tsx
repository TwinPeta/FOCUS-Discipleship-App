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
    <section className="card h-full">
      <div className="mb-3 flex items-baseline justify-between gap-3">
        <h2 className="eyebrow">Weekly activity</h2>
        <p className="text-sm font-extrabold">Logins and completions</p>
      </div>

      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} barGap={4}>
            <CartesianGrid strokeDasharray="3 3" stroke="#CFE0F3" vertical={false} />
            <XAxis dataKey="day" tick={{ fontSize: 13, fontWeight: 800, fill: "#1F2D3D" }} axisLine={{ stroke: "#1F2D3D", strokeWidth: 2 }} tickLine={false} />
            <YAxis allowDecimals={false} tick={{ fontSize: 12, fill: "#4F6074" }} axisLine={false} tickLine={false} width={28} />
            <Tooltip cursor={{ fill: "rgba(227,240,253,0.6)" }} />
            <Legend wrapperStyle={{ fontSize: 13, fontWeight: 700 }} />
            <Bar dataKey="logins" name="Logins" fill="#F4B400" stroke="#1F2D3D" strokeWidth={2} radius={[6, 6, 0, 0]} />
            <Bar dataKey="completions" name="Completions" fill="#4C98E6" stroke="#1F2D3D" strokeWidth={2} radius={[6, 6, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}
