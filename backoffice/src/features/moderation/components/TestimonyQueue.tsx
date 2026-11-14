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
    <div className="grid gap-6 lg:grid-cols-3">
      <div className={selected ? "lg:col-span-2" : "lg:col-span-3"}>
        <div className="overflow-x-auto rounded-card border border-border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
              <tr>
                <th className="px-4 py-3">Author</th>
                <th className="px-4 py-3">Community</th>
                <th className="px-4 py-3">Agreement</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {items.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-muted-foreground">
                    No testimonies awaiting moderation.
                  </td>
                </tr>
              ) : (
                items.map((item) => (
                  <tr key={item.id} className="hover:bg-surface/60">
                    <td className="px-4 py-3 font-medium text-foreground">
                      {item.authorName}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {item.communityName}
                    </td>
                    <td className="px-4 py-3">
                      {item.studentAgreement ? "Yes" : "No"}
                    </td>
                    <td className="px-4 py-3">{item.status}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => setSelected(item)}
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
        <TestimonyReview
          testimony={selected}
          onReview={handleReview}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  );
}
