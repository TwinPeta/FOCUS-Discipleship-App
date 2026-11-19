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
import { QueueList } from "@/components/common/QueueList";
import { formatRelativeTime } from "@/lib/format/date";
import { CommunityFilter } from "./CommunityFilter";
import { ReportDetail } from "./ReportDetail";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchModerationReports } from "@/features/moderation/queries";

interface ReportQueueProps {
  initialItems: ModerationReport[];
}

export function ReportQueue({ initialItems }: ReportQueueProps) {
  const [items, setItems] = useRemoteItems<ModerationReport>(initialItems, fetchModerationReports);
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
    <div className="flex flex-col gap-4">
      <CommunityFilter
        value={communityFilter}
        onChange={setCommunityFilter}
        communities={communities}
      />

      <div className="flex flex-wrap items-start gap-4">
        <div className="min-w-0 flex-[999_1_560px]">
          <QueueList
            items={filtered.map((r) => ({
              id: r.id,
              title: r.reason,
              status: r.status,
              variant: r.status === ReportStatus.Resolved ? "inactive" : "pending",
              lines: [`${r.reporterName} reported ${r.reportedUserName}`, `${r.screenshotUrl ? "Screenshot attached · " : ""}${formatRelativeTime(r.createdAt)}`],
            }))}
            selectedId={selected?.id}
            onSelect={(id) => setSelected(filtered.find((r) => r.id === id) ?? null)}
            emptyText="No reports in this queue."
          />
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
