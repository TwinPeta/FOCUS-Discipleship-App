/**
 * src/features/communities/queries.ts
 *
 * WHAT: Community queries and create/update mutations
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import type { Community, CommunityInput } from "./schemas";

export async function fetchCommunities(): Promise<Community[]> {
  const res = await fetch("/api/proxy/communities", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load communities");
  const data = (await res.json()) as { items?: Community[] };
  return data.items ?? [];
}

export async function fetchCommunity(id: string): Promise<Community> {
  const res = await fetch(`/api/proxy/communities/${id}`, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load community");
  return (await res.json()) as Community;
}

export async function createCommunity(input: CommunityInput): Promise<Community> {
  const res = await fetch("/api/proxy/communities", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error("Failed to create community");
  return (await res.json()) as Community;
}

export async function updateCommunity(
  id: string,
  input: Partial<CommunityInput>,
): Promise<Community> {
  const res = await fetch(`/api/proxy/communities/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error("Failed to update community");
  return (await res.json()) as Community;
}
