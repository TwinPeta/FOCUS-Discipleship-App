/**
 * src/features/join-requests/queries.ts
 *
 * WHAT: Join request queries and approve, decline, bulk mutations
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

import type { JoinRequestItem } from "./conflicts";

export async function fetchJoinRequests(): Promise<JoinRequestItem[]> {
  const res = await fetch("/api/proxy/join-requests", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load join requests");
  const data = (await res.json()) as { items?: JoinRequestItem[] };
  return data.items ?? [];
}

export async function approveJoinRequest(id: string): Promise<void> {
  const res = await fetch(`/api/proxy/join-requests/${id}/approve`, {
    method: "POST",
  });
  if (!res.ok) throw new Error("Failed to approve join request");
}

export async function declineJoinRequest(id: string, reason?: string): Promise<void> {
  const res = await fetch(`/api/proxy/join-requests/${id}/decline`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ reason }),
  });
  if (!res.ok) throw new Error("Failed to decline join request");
}

export async function bulkApproveJoinRequests(ids: string[]): Promise<void> {
  const res = await fetch("/api/proxy/join-requests/bulk-approve", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ids }),
  });
  if (!res.ok) throw new Error("Failed to bulk approve join requests");
}
