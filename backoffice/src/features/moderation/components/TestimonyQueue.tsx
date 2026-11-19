/**
 * src/features/moderation/components/TestimonyQueue.tsx
 *
 * WHAT: Testimonies moderation queue table + review panel
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { QueueList } from "@/components/common/QueueList";
import { formatRelativeTime } from "@/lib/format/date";
import { reviewTestimony } from "@/features/moderation/queries";
import type {
  ModerationTestimony,
  TestimonyAction,
} from "@/features/moderation/schemas";
import { TestimonyReview } from "./TestimonyReview";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchTestimonies } from "@/features/moderation/queries";

interface TestimonyQueueProps {
  initialItems: ModerationTestimony[];
}

export function TestimonyQueue({ initialItems }: TestimonyQueueProps) {
  const [items, setItems] = useRemoteItems<ModerationTestimony>(initialItems, fetchTestimonies);
  const [selected, setSelected] = useState<ModerationTestimony | null>(null);

  async function handleReview(action: TestimonyAction, notes?: string) {
    if (!selected) return;
    await reviewTestimony(selected.id, action, notes);
    const nextStatus =
      action === "APPROVE"
        ? "APPROVED"
        : action === "REQUEST_CHANGES"
          ? "CHANGES_REQUESTED"
          : "REJECTED";
    setItems((prev) =>
      prev.map((i) => (i.id === selected.id ? { ...i, status: nextStatus } : i)),
    );
    setSelected(null);
  }

  return (
    <div className="flex flex-wrap items-start gap-4">
      <div className="min-w-0 flex-[999_1_560px]">
        <QueueList
          items={items.map((t) => ({
            id: t.id,
            title: t.title || "Testimony",
            status: t.status === "PENDING" ? "Pending" : t.status === "APPROVED" ? "Published" : t.status === "REJECTED" ? "Rejected" : "Changes asked",
            variant: t.status === "PENDING" ? "pending" : t.status === "APPROVED" ? "active" : "inactive",
            lines: [`${t.authorName} · ${t.communityName}`, `${t.videoUrl ? "Video + text" : "Text"} · ${formatRelativeTime(t.createdAt)}`],
          }))}
          selectedId={selected?.id}
          onSelect={(id) => setSelected(items.find((t) => t.id === id) ?? null)}
          emptyText="No testimonies awaiting moderation."
        />
      </div>

      {selected && (
        <TestimonyReview
          testimony={selected}
          onReview={handleReview}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  );
}
