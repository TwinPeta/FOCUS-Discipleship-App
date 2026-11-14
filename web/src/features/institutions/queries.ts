/**
 * src/features/institutions/queries.ts
 *
 * WHAT: Institution queries and create/update mutations
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import type { Institution, InstitutionInput } from "./schemas";

export async function fetchInstitutions(): Promise<Institution[]> {
  const res = await fetch("/api/proxy/institutions", { cache: "no-store" });
  if (!res.ok) throw new Error("Failed to load institutions");
  const data = (await res.json()) as { items?: Institution[] };
  return data.items ?? [];
}

export async function createInstitution(input: InstitutionInput): Promise<Institution> {
  const res = await fetch("/api/proxy/institutions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error("Failed to create institution");
  return (await res.json()) as Institution;
}

export async function updateInstitution(
  id: string,
  input: InstitutionInput,
): Promise<Institution> {
  const res = await fetch(`/api/proxy/institutions/${id}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  if (!res.ok) throw new Error("Failed to update institution");
  return (await res.json()) as Institution;
}
