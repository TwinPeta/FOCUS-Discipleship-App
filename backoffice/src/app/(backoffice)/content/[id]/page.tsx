/**
 * src/app/(backoffice)/content/[id]/page.tsx
 *
 * WHAT: Content item detail, validation review panel, and approval trail
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { use, useEffect, useState } from "react";
import { ApprovalTrail } from "@/features/content/components/ApprovalTrail";
import { ReviewPanel } from "@/features/content/components/ReviewPanel";
import { WorkflowStatusBadge } from "@/features/content/components/WorkflowStatusBadge";
import { fetchContentItem, transitionContent } from "@/features/content/queries";
import type { ContentItem } from "@/features/content/schemas";
import type { ContentAction } from "@/features/content/workflow";

export default function ContentDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const [item, setItem] = useState<ContentItem | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchContentItem(id)
      .then(setItem)
      .catch(() => setError("Could not load content item."))
      .finally(() => setLoading(false));
  }, [id]);

  async function handleTransition(action: ContentAction, notes?: string) {
    const updated = await transitionContent(id, action, notes);
    setItem(updated);
  }

  return (
    <div className="flex flex-col gap-5">
      {loading && <p className="text-sm text-muted-foreground">Loading content...</p>}
      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      {item && (
        <>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 className="text-[34px] leading-[1.05]">{item.title}</h1>
              <p className="mt-1 text-sm text-muted-foreground">
                {item.type} · {item.bibleLink} · Author: {item.authorName}
              </p>
            </div>
            <WorkflowStatusBadge status={item.status} />
          </div>

          {item.description && (
            <div className="rounded-card border border-border bg-white p-5 text-sm text-foreground">
              {item.description}
            </div>
          )}

          <ReviewPanel status={item.status} onTransition={handleTransition} />
          <ApprovalTrail entries={item.approvalTrail ?? []} />
        </>
      )}
    </div>
  );
}
