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
    <aside className="space-y-4 rounded-card border border-border bg-white p-5">
      <div className="flex items-start justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold text-foreground">
            {post.kind} by {post.authorName}
          </h2>
          <p className="text-xs text-muted-foreground">
            {post.communityName} · {post.reportCount} reports
          </p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="text-xs text-muted-foreground hover:text-foreground"
        >
          Close
        </button>
      </div>

      <div className="rounded-md border border-border bg-surface p-3 text-sm text-foreground">
        {post.content}
      </div>

      <div className="space-y-1.5">
        <label htmlFor="post-mod-notes" className="block text-sm font-medium">
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
          className="rounded-md border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface"
        >
          Keep
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("HIDE")}
          className="rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-foreground hover:brightness-95"
        >
          Hide
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("WARN_AUTHOR")}
          className="rounded-md border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface"
        >
          Warn author
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("ESCALATE")}
          className="rounded-md bg-amber-100 px-3 py-1.5 text-xs font-semibold text-amber-900 hover:bg-amber-200"
        >
          Escalate
        </button>
      </div>
    </aside>
  );
}
