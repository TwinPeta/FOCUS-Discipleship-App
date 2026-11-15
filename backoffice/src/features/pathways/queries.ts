/**
 * src/features/pathways/queries.ts
 *
 * WHAT: Pathway queries and mutations
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

import type { PathwayFormValues, PathwayStepInput } from "./schemas";
import { apiClient } from "@/lib/api/client";
import { ApiError } from "@/lib/api/errors";
import { mutate } from "@/lib/api/mutate";
import { unwrapList } from "@/lib/api/unwrap";

export type PathwayLevel = "Beginner" | "Intermediate" | "Advanced";
export type UnlockRuleType = "none" | "previous_pathway" | "profile_complete" | "mentor_assigned";

export type PathwayStep = PathwayStepInput;

export interface Pathway {
  id: string;
  name: string;
  theme: string;
  level: PathwayLevel;
  description?: string;
  steps: PathwayStep[];
  unlockRule: UnlockRuleType;
  badgeAwardedId?: string | null;
  badgeName?: string | null;
  learnersCount: number;
  published: boolean;
  lockedUntilInfo?: string;
  updatedAt: string;
}

export interface AvailableContentItem {
  id: string;
  title: string;
  type: "video" | "devotional" | "document" | "quiz";
  published: boolean;
}

export async function fetchPathways(): Promise<Pathway[]> {
  return unwrapList<Pathway>(await apiClient<unknown>("/pathways"));
}

export async function fetchPathway(id: string): Promise<Pathway | null> {
  try {
    return await apiClient<Pathway>(`/pathways/${id}`);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) return null;
    throw error;
  }
}

export async function fetchAvailableContent(): Promise<AvailableContentItem[]> {
  const data = await apiClient<unknown>("/content", { params: { status: "published" } });
  return Array.isArray(data) ? (data as AvailableContentItem[]) : unwrapList<AvailableContentItem>(data);
}

export async function savePathway(
  values: PathwayFormValues,
  id?: string,
): Promise<Pathway> {
  return id ? mutate<Pathway>(`/pathways/${id}`, "PUT", values) : mutate<Pathway>("/pathways", "POST", values);
}

export async function deletePathway(id: string): Promise<void> {
  await mutate(`/pathways/${id}`, "DELETE");
}
