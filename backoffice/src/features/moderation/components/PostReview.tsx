/**
 * src/features/moderation/components/PostReview.tsx
 *
 * WHAT: Side panel for reviewing prayer requests, feed posts, and comments
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { X } from "lucide-react";
import { StatusPill } from "@/components/data-table/StatusPill";
import type { ModerationPost, PostAction } from "@/features/moderation/schemas";

interface PostReviewProps {
  post: ModerationPost;
  onAction: (action: PostAction, notes?: string) => Promise<void>;
  onClose: () => void;
}

export function PostReview({ post, onAction, onClose }: PostReviewProps) {
  const [notes, setNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function submit(action: PostAction) {
    setSubmitting(true);
    try {
      await onAction(action, notes.trim() || undefined);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <aside className="card flex min-w-0 flex-[1_1_320px] flex-col gap-3 lg:max-w-[440px]">
      <div className="flex items-start justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-[22px] font-black">{post.kind === "PRAYER" ? "Prayer request" : post.kind === "POST" ? "Feed post" : "Comment"}</h2>
          <StatusPill status={post.hidden ? "Hidden" : "Flagged"} variant={post.hidden ? "inactive" : "pending"} />
        </div>
        <button type="button" onClick={onClose} aria-label="Close" className="btn btn-secondary btn-sm">
          <X className="h-5 w-5" aria-hidden="true" />
        </button>
      </div>

      <dl className="divide-y-[1.5px] divide-border text-[15px]">
        {[
          ["Author", post.authorName],
          ["Caregroup", post.communityName],
          ["Reports", String(post.reportCount)],
        ].map(([k, v]) => (
          <div key={k} className="flex justify-between gap-3 py-2">
            <dt>{k}</dt>
            <dd className="text-right font-extrabold">{v}</dd>
          </div>
        ))}
      </dl>

      <div className="rounded-xl bg-blue-tint p-3 text-[15px]">{post.content}</div>

      <div className="space-y-1.5">
        <label htmlFor="post-mod-notes" className="block text-[13px] font-extrabold">
          Moderation note
        </label>
        <textarea
          id="post-mod-notes"
          rows={2}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("KEEP")}
          className="btn btn-secondary btn-sm"
        >
          Keep
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("HIDE")}
          className="btn btn-secondary btn-sm"
        >
          Hide content
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("WARN_AUTHOR")}
          className="btn btn-secondary btn-sm"
        >
          Warn author
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("ESCALATE")}
          className="btn btn-secondary btn-sm"
        >
          Escalate to admin
        </button>
      </div>
    </aside>
  );
}
