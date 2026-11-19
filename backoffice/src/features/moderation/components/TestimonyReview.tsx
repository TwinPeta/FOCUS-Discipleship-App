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
import { X } from "lucide-react";
import { StatusPill } from "@/components/data-table/StatusPill";
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
    <aside className="card flex min-w-0 flex-[1_1_320px] flex-col gap-3 lg:max-w-[420px]">
      <div className="flex items-start justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-[22px] font-black">{testimony.title || "Testimony"}</h2>
          <StatusPill status={testimony.status === "PENDING" ? "Pending" : testimony.status === "APPROVED" ? "Published" : testimony.status === "REJECTED" ? "Rejected" : "Changes asked"} variant={testimony.status === "PENDING" ? "pending" : testimony.status === "APPROVED" ? "active" : "inactive"} />
        </div>
        <button type="button" onClick={onClose} aria-label="Close" className="rounded-md p-1 hover:bg-blue-soft">
          <X className="h-5 w-5" aria-hidden="true" />
        </button>
      </div>

      <dl className="divide-y-[1.5px] divide-border text-[15px]">
        {[
          ["Author", testimony.authorName],
          ["Caregroup", testimony.communityName],
          ["Submitted", testimony.createdAt],
        ].map(([k, v]) => (
          <div key={k} className="flex justify-between gap-3 py-2">
            <dt>{k}</dt>
            <dd className="text-right font-extrabold">{v}</dd>
          </div>
        ))}
      </dl>

      <p className="eyebrow">Story</p>
      <div className="rounded-xl bg-blue-tint p-3 text-[15px] leading-relaxed">
        {testimony.story}
      </div>

      <p className="notice">
        <span>{testimony.studentAgreement ? "The student agreed to share this story with the caregroup." : "The student has not confirmed they agree to share this story."}</span>
      </p>

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
        <label htmlFor="testimony-notes" className="block text-[13px] font-extrabold">
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
          className="rounded-md border border-danger/40 px-3 py-1.5 text-xs font-medium text-danger hover:bg-danger-soft disabled:opacity-60"
        >
          Reject
        </button>
      </div>
    </aside>
  );
}
