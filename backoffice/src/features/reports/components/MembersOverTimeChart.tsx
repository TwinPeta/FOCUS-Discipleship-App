/**
 * src/features/reports/components/MembersOverTimeChart.tsx
 *
 * WHAT: Members over time line chart
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { MembersTimePoint } from "../queries";

export function MembersOverTimeChart({ data }: { data: MembersTimePoint[] }) {
  return (
    <section className="rounded-xl border border-border bg-white p-5">
      <div className="mb-4">
        <h2 className="eyebrow">
          Members over time
        </h2>
        <p className="text-xs text-muted">
          Total registered members versus 30-day active members.
        </p>
      </div>

      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
            <XAxis dataKey="period" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            <Line
              type="monotone"
              dataKey="totalMembers"
              name="Total members"
              stroke="#1d4ed8"
              strokeWidth={2}
            />
            <Line
              type="monotone"
              dataKey="activeMembers"
              name="Active members"
              stroke="#10b981"
              strokeWidth={2}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}
