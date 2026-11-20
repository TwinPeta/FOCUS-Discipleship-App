/**
 * src/features/members/queries.ts
 *
 * WHAT: Member queries and role, community, suspend, add-user mutations
 * REQUIREMENTS: FR-07, FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import type { Role } from "@/types/enums";
import type { AddUserInput, Member } from "./schemas";

export async function fetchMembers(): Promise<Member[]> {
  const res = await fetch("/api/proxy/members", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load members");
  const data = (await res.json()) as { items?: Member[] };
  return data.items ?? [];
}

export async function fetchMember(id: string): Promise<Member> {
  const res = await fetch(`/api/proxy/members/${id}`, { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load member");
  return (await res.json()) as Member;
}

export async function createMember(input: AddUserInput): Promise<Member> {
  const res = await fetch("/api/proxy/members", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      ...input,
      country: input.country || undefined,
      localChurch: input.localChurch || undefined,
      yearOfStudy: input.yearOfStudy ? Number(input.yearOfStudy) : undefined,
    }),
  });
  if (!res.ok) throw new Error("Failed to create member");
  return (await res.json()) as Member;
}

export async function changeMemberRole(id: string, role: Role | { customRoleId: string }, reason?: string): Promise<Member> {
  const target = typeof role === "string" ? { role } : role;
  const res = await fetch(`/api/proxy/members/${id}/role`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(reason?.trim() ? { ...target, reason: reason.trim() } : target),
  });
  if (!res.ok) throw new Error("Failed to change member role");
  return (await res.json()) as Member;
}

export async function moveMemberCommunity(
  id: string,
  communityId: string,
): Promise<Member> {
  const res = await fetch(`/api/proxy/members/${id}/community`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ communityId }),
  });
  if (!res.ok) throw new Error("Failed to move member caregroup");
  return (await res.json()) as Member;
}

export async function suspendMember(id: string, reason: string): Promise<Member> {
  const res = await fetch(`/api/proxy/members/${id}/suspend`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ reason }),
  });
  if (!res.ok) throw new Error("Failed to suspend member");
  return (await res.json()) as Member;
}
