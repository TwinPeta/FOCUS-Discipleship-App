/**
 * src/features/churches/queries.ts
 *
 * WHAT: Local churches list, built by the API from the home church each student gives at sign-up
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import { apiClient } from "@/lib/api/client";

export interface LocalChurch {
  id: string;
  name: string;
  location: string;
  pastor: string;
  students: number;
  mentors: number;
}

export async function fetchChurches(): Promise<LocalChurch[]> {
  const data = await apiClient<{ items?: LocalChurch[] }>("/churches");
  return data.items ?? [];
}
