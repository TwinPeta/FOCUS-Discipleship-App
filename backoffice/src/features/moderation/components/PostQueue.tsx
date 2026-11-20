/**
 * src/features/moderation/components/PostQueue.tsx
 *
 * WHAT: Prayer requests, feed posts, and comments moderation queue
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { QueueList } from "@/components/common/QueueList";
import { formatRelativeTime } from "@/lib/format/date";
import { actOnPost } from "@/features/moderation/queries";
import type { ModerationPost, PostAction } from "@/features/moderation/schemas";
import { PostReview } from "./PostReview";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchModerationPosts } from "@/features/moderation/queries";

interface PostQueueProps {
  initialItems: ModerationPost[];
}

export function PostQueue({ initialItems }: PostQueueProps) {
  const [items, setItems] = useRemoteItems<ModerationPost>(initialItems, fetchModerationPosts);
  const [selected, setSelected] = useState<ModerationPost | null>(null);

  async function handleAction(action: PostAction, notes?: string) {
    if (!selected) return;
    await actOnPost(selected.id, action, notes);
    if (action === "HIDE") {
      setItems((prev) =>
        prev.map((i) => (i.id === selected.id ? { ...i, hidden: true } : i)),
      );
    }
    setSelected(null);
  }

  return (
    <div className="flex flex-wrap items-start gap-4">
      <div className="min-w-0 flex-[999_1_560px]">
        <QueueList
          items={items.map((post) => ({
            id: post.id,
            title: post.kind === "PRAYER" ? "Prayer request" : post.kind === "POST" ? "Feed post" : "Comment",
            status: post.hidden ? "Hidden" : "Flagged",
            variant: post.hidden ? "inactive" : "pending",
            lines: [`${post.authorName} · ${post.communityName}`, `${post.reportCount} ${post.reportCount === 1 ? "report" : "reports"} · ${formatRelativeTime(post.createdAt)}`],
          }))}
          selectedId={selected?.id}
          onSelect={(id) => setSelected(items.find((p) => p.id === id) ?? null)}
          emptyText="No prayer requests or posts awaiting review."
        />
      </div>

      {selected && (
        <PostReview
          post={selected}
          onAction={handleAction}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  );
}
