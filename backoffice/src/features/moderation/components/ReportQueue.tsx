/**
 * src/features/moderation/components/ReportQueue.tsx
 *
 * WHAT: Reports queue table + detail side panel
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { actOnReport } from "@/features/moderation/queries";
import type { ModerationReport, ReportAction } from "@/features/moderation/schemas";
import { ReportStatus } from "@/types/enums";
import { CommunityFilter } from "./CommunityFilter";
import { ReportDetail } from "./ReportDetail";

interface ReportQueueProps {
  initialItems: ModerationReport[];
}

export function ReportQueue({ initialItems }: ReportQueueProps) {
  const [items, setItems] = useState<ModerationReport[]>(initialItems);
  const [communityFilter, setCommunityFilter] = useState("ALL");
  const [selected, setSelected] = useState<ModerationReport | null>(null);

  const communities = Array.from(
    new Map(items.map((i) => [i.communityId, { id: i.communityId, name: i.communityName }])).values(),
  );

  const filtered = items.filter(
    (item) => communityFilter === "ALL" || item.communityId === communityFilter,
  );

  async function handleAction(action: ReportAction, notes?: string) {
    if (!selected) return;
    await actOnReport(selected.id, action, notes);
    setItems((prev) =>
      prev.map((i) =>
        i.id === selected.id ? { ...i, status: ReportStatus.Resolved } : i,
      ),
    );
    setSelected(null);
  }

  return (
    <div className="space-y-4">
      <CommunityFilter
        value={communityFilter}
        onChange={setCommunityFilter}
        communities={communities}
      />

      <div className="grid gap-6 lg:grid-cols-3">
        <div className={selected ? "lg:col-span-2" : "lg:col-span-3"}>
          <div className="overflow-x-auto rounded-card border border-border bg-white">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
                <tr>
                  <th className="px-4 py-3">Reason</th>
                  <th className="px-4 py-3">Reported user</th>
                  <th className="px-4 py-3">Community</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                      No reports in this queue.
                    </td>
                  </tr>
                ) : (
                  filtered.map((report) => (
                    <tr key={report.id} className="hover:bg-surface/60">
                      <td className="px-4 py-3 font-medium text-foreground">
                        {report.reason}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {report.reportedUserName}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {report.communityName}
                      </td>
                      <td className="px-4 py-3">{report.status}</td>
                      <td className="px-4 py-3 text-right">
                        <button
                          type="button"
                          onClick={() => setSelected(report)}
                          className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                        >
                          Review
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {selected && (
          <ReportDetail
            report={selected}
            onAction={handleAction}
            onClose={() => setSelected(null)}
          />
        )}
      </div>
    </div>
  );
}
