/**
 * src/features/moderation/queries.ts
 *
 * WHAT: Moderation queries and L1/L2 actions for reports, testimonies, posts, and sanctions
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import type {
  ModerationPost,
  ModerationReport,
  ModerationTestimony,
  PostAction,
  ReportAction,
  SanctionRecord,
  TestimonyAction,
} from "./schemas";

export async function fetchModerationReports(): Promise<ModerationReport[]> {
  const res = await fetch("/api/proxy/moderation/reports", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load reports");
  const data = (await res.json()) as { items?: ModerationReport[] };
  return data.items ?? [];
}

export async function actOnReport(
  id: string,
  action: ReportAction,
  notes?: string,
): Promise<void> {
  const res = await fetch(`/api/proxy/moderation/reports/${id}/action`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action, notes }),
  });
  if (!res.ok) throw new Error("Failed to process report action");
}

export async function fetchTestimonies(): Promise<ModerationTestimony[]> {
  const res = await fetch("/api/proxy/moderation/testimonies", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load testimonies");
  const data = (await res.json()) as { items?: ModerationTestimony[] };
  return data.items ?? [];
}

export async function reviewTestimony(
  id: string,
  action: TestimonyAction,
  notes?: string,
): Promise<void> {
  const res = await fetch(`/api/proxy/moderation/testimonies/${id}/review`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action, notes }),
  });
  if (!res.ok) throw new Error("Failed to review testimony");
}

export async function fetchModerationPosts(): Promise<ModerationPost[]> {
  const res = await fetch("/api/proxy/moderation/posts", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load posts");
  const data = (await res.json()) as { items?: ModerationPost[] };
  return data.items ?? [];
}

export async function actOnPost(
  id: string,
  action: PostAction,
  notes?: string,
): Promise<void> {
  const res = await fetch(`/api/proxy/moderation/posts/${id}/action`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ action, notes }),
  });
  if (!res.ok) throw new Error("Failed to process post action");
}

export async function fetchSanctions(): Promise<SanctionRecord[]> {
  const res = await fetch("/api/proxy/moderation/sanctions", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load sanctions");
  const data = (await res.json()) as { items?: SanctionRecord[] };
  return data.items ?? [];
}

export async function reinstateSanction(id: string, reason: string): Promise<void> {
  const res = await fetch(`/api/proxy/moderation/sanctions/${id}/reinstate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ reason }),
  });
  if (!res.ok) throw new Error("Failed to reinstate user");
}
