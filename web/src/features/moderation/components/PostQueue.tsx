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
import { actOnPost } from "@/features/moderation/queries";
import type { ModerationPost, PostAction } from "@/features/moderation/schemas";
import { PostReview } from "./PostReview";

interface PostQueueProps {
  initialItems: ModerationPost[];
}

export function PostQueue({ initialItems }: PostQueueProps) {
  const [items, setItems] = useState<ModerationPost[]>(initialItems);
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
    <div className="grid gap-6 lg:grid-cols-3">
      <div className={selected ? "lg:col-span-2" : "lg:col-span-3"}>
        <div className="overflow-x-auto rounded-card border border-border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
              <tr>
                <th className="px-4 py-3">Type</th>
                <th className="px-4 py-3">Author</th>
                <th className="px-4 py-3">Community</th>
                <th className="px-4 py-3">Reports</th>
                <th className="px-4 py-3">Visibility</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">
                    No prayer requests or posts awaiting review.
                  </td>
                </tr>
              ) : (
                items.map((post) => (
                  <tr key={post.id} className="hover:bg-surface/60">
                    <td className="px-4 py-3 font-medium text-foreground">{post.kind}</td>
                    <td className="px-4 py-3 text-muted-foreground">{post.authorName}</td>
                    <td className="px-4 py-3 text-muted-foreground">{post.communityName}</td>
                    <td className="px-4 py-3">{post.reportCount}</td>
                    <td className="px-4 py-3">{post.hidden ? "Hidden" : "Visible"}</td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => setSelected(post)}
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
        <PostReview
          post={selected}
          onAction={handleAction}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  );
}
