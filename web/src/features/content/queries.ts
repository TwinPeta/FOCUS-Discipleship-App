/**
 * src/features/content/queries.ts
 *
 * WHAT: Content library queries and create, update, workflow transition mutations
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import type { ContentInput, ContentItem } from "./schemas";
import type { ContentAction } from "./workflow";

export async function fetchContentList(): Promise<ContentItem[]> {
  const res = await fetch("/api/proxy/content", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load content library");
  const data = (await res.json()) as { items?: ContentItem[] };
  return data.items ?? [];
}

export async function fetchContentItem(id: string): Promise<ContentItem> {
  const res = await fetch(`/api/proxy/content/${id}`, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load content item");
  return (await res.json()) as ContentItem;
}

export async function createContent(
  input: ContentInput & { submitForReview?: boolean },
): Promise<ContentItem> {
  const res = await fetch("/api/proxy/content", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error("Failed to create content");
  return (await res.json()) as ContentItem;
}

export async function transitionContent(
  id: string,
  action: ContentAction,
  notes?: string,
): Promise<ContentItem> {
  const res = await fetch(`/api/proxy/content/${id}/transition`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action, notes }),
  });
  if (!res.ok) throw new Error("Failed to update content workflow");
  return (await res.json()) as ContentItem;
}
