/**
 * src/features/moderation/components/TestimonyReview.tsx
 *
 * WHAT: Side panel for reviewing student testimonies (approve & publish, request changes, reject)
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import type {
  ModerationTestimony,
  TestimonyAction,
} from "@/features/moderation/schemas";

interface TestimonyReviewProps {
  testimony: ModerationTestimony;
  onReview: (action: TestimonyAction, notes?: string) => Promise<void>;
  onClose: () => void;
}

export function TestimonyReview({
  testimony,
  onReview,
  onClose,
}: TestimonyReviewProps) {
  const [notes, setNotes] = useState(testimony.notes ?? "");
  const [submitting, setSubmitting] = useState(false);

  async function submit(action: TestimonyAction) {
    setSubmitting(true);
    try {
      await onReview(action, notes.trim() || undefined);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <aside className="space-y-4 rounded-card border border-border bg-white p-5">
      <div className="flex items-start justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold text-foreground">
            {testimony.authorName}
          </h2>
          <p className="text-xs text-muted-foreground">
            {testimony.communityName} · {testimony.createdAt}
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

      <p className="text-xs font-medium text-foreground">
        Student agreement:{" "}
        {testimony.studentAgreement ? "Confirmed" : "Missing"}
      </p>

      {testimony.title && (
        <h3 className="text-sm font-semibold text-foreground">{testimony.title}</h3>
      )}

      <div className="rounded-md border border-border bg-surface p-3 text-sm leading-relaxed text-foreground">
        {testimony.story}
      </div>

      {testimony.videoUrl && (
        <div className="space-y-1">
          <p className="text-xs font-medium text-muted-foreground">Video (up to 2 minutes)</p>
          <video
            src={testimony.videoUrl}
            controls
            preload="metadata"
            className="w-full rounded-md border border-border bg-black"
          />
        </div>
      )}

      {testimony.photoUrls && testimony.photoUrls.length > 0 && (
        <div className="space-y-1">
          <p className="text-xs font-medium text-muted-foreground">
            {testimony.photoUrls.length === 1 ? "Photo" : `${testimony.photoUrls.length} photos`}
          </p>
          <div className="grid grid-cols-2 gap-2">
            {testimony.photoUrls.map((url) => (
              <a key={url} href={url} target="_blank" rel="noreferrer">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={url}
                  alt="Attached to the story"
                  className="h-32 w-full rounded-md border border-border object-cover"
                />
              </a>
            ))}
          </div>
        </div>
      )}

      <div className="space-y-1.5">
        <label htmlFor="testimony-notes" className="block text-sm font-medium">
          Reviewer notes
        </label>
        <textarea
          id="testimony-notes"
          rows={2}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          disabled={submitting || !testimony.studentAgreement}
          onClick={() => submit("APPROVE")}
          className="rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          Approve and publish
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("REQUEST_CHANGES")}
          className="rounded-md border border-border px-3 py-1.5 text-xs font-medium hover:bg-surface disabled:opacity-60"
        >
          Request changes
        </button>
        <button
          type="button"
          disabled={submitting}
          onClick={() => submit("REJECT")}
          className="rounded-md border border-red-300 px-3 py-1.5 text-xs font-medium text-red-700 hover:bg-red-50 disabled:opacity-60"
        >
          Reject
        </button>
      </div>
    </aside>
  );
}
