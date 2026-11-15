/**
 * src/features/bible/queries.ts
 *
 * WHAT: Bible characters and texts the content can be linked to (the API owns the list)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import { apiClient } from "@/lib/api/client";
import { unwrapList } from "@/lib/api/unwrap";

export interface BibleLinkOption {
  id: string;
  label: string;
  kind: "CHARACTER" | "TEXT";
}

export async function fetchBibleLinks(): Promise<BibleLinkOption[]> {
  const data = await apiClient<unknown>("/bible-links");
  return unwrapList<BibleLinkOption>(data);
}
