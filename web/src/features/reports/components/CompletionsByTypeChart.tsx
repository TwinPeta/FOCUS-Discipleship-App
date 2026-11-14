/**
 * src/features/reports/components/CompletionsByTypeChart.tsx
 *
 * WHAT: Completions by content type bar chart
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import type { CompletionByTypePoint } from "../queries";

export function CompletionsByTypeChart({
  data,
}: {
  data: CompletionByTypePoint[];
}) {
  return (
    <section className="rounded-xl border border-border bg-white p-5">
      <div className="mb-4">
        <h2 className="text-base font-semibold text-foreground">
          Completions by content type
        </h2>
        <p className="text-xs text-muted">
          Completed items across devotionals, videos, documents, and quizzes.
        </p>
      </div>

      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
            <XAxis dataKey="type" tick={{ fontSize: 12 }} />
            <YAxis tick={{ fontSize: 12 }} />
            <Tooltip />
            <Bar
              dataKey="completions"
              name="Completions"
              fill="#6366f1"
              radius={[4, 4, 0, 0]}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}
