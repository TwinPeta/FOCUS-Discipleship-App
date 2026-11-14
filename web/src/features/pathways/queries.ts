/**
 * src/features/pathways/queries.ts
 *
 * WHAT: Pathway queries and mutations
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

import type { PathwayFormValues, PathwayStepInput } from "./schemas";

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

export const MOCK_AVAILABLE_CONTENT: AvailableContentItem[] = [
  { id: "c-101", title: "Knowing Christ Personally", type: "devotional", published: true },
  { id: "c-102", title: "Prayer and Fasting Basics", type: "devotional", published: true },
  { id: "c-103", title: "Foundations of Fellowship", type: "video", published: true },
  { id: "c-104", title: "Quiet Time Journal Guide", type: "document", published: true },
  { id: "c-105", title: "Discipleship Quiz 1", type: "quiz", published: true },
  { id: "c-106", title: "Walking in Integrity", type: "video", published: true },
  { id: "c-107", title: "Biblical Stewardship", type: "devotional", published: true },
];

export const MOCK_PATHWAYS: Pathway[] = [
  {
    id: "pw-1",
    name: "Foundations of Discipleship",
    theme: "Spiritual Growth",
    level: "Beginner",
    description: "Core steps every new FOCUS member completes during their first semester.",
    steps: [
      { id: "s-1", contentId: "c-101", title: "Knowing Christ Personally", contentType: "devotional", order: 0, required: true },
      { id: "s-2", contentId: "c-104", title: "Quiet Time Journal Guide", contentType: "document", order: 1, required: true },
      { id: "s-3", contentId: "c-105", title: "Discipleship Quiz 1", contentType: "quiz", order: 2, required: true },
    ],
    unlockRule: "none",
    badgeAwardedId: "bdg-1",
    badgeName: "Faithful Disciple",
    learnersCount: 412,
    published: true,
    lockedUntilInfo: "Available immediately upon sign-in",
    updatedAt: "2026-11-10",
  },
  {
    id: "pw-2",
    name: "Campus Leadership & Witness",
    theme: "Leadership",
    level: "Intermediate",
    description: "Training for small group leaders, mentors, and executive committee members.",
    steps: [
      { id: "s-4", contentId: "c-103", title: "Foundations of Fellowship", contentType: "video", order: 0, required: true },
      { id: "s-5", contentId: "c-106", title: "Walking in Integrity", contentType: "video", order: 1, required: true },
    ],
    unlockRule: "previous_pathway",
    badgeAwardedId: "bdg-2",
    badgeName: "Servant Leader",
    learnersCount: 168,
    published: true,
    lockedUntilInfo: "Requires completion of Foundations of Discipleship",
    updatedAt: "2026-11-04",
  },
];

export async function fetchPathways(): Promise<Pathway[]> {
  try {
    const res = await fetch("/api/proxy/pathways");
    if (res.ok) {
      return (await res.json()) as Pathway[];
    }
  } catch {
    // Dev mock fallback
  }
  return MOCK_PATHWAYS;
}

export async function fetchPathway(id: string): Promise<Pathway | null> {
  try {
    const res = await fetch(`/api/proxy/pathways/${id}`);
    if (res.ok) {
      return (await res.json()) as Pathway;
    }
  } catch {
    // Dev mock fallback
  }
  return MOCK_PATHWAYS.find((p) => p.id === id) ?? null;
}

export async function fetchAvailableContent(): Promise<AvailableContentItem[]> {
  try {
    const res = await fetch("/api/proxy/content?status=published");
    if (res.ok) {
      const data = await res.json();
      if (Array.isArray(data)) return data;
    }
  } catch {
    // Dev mock fallback
  }
  return MOCK_AVAILABLE_CONTENT.filter((c) => c.published);
}

export async function savePathway(
  values: PathwayFormValues,
  id?: string,
): Promise<Pathway> {
  try {
    const url = id ? `/api/proxy/pathways/${id}` : "/api/proxy/pathways";
    const method = id ? "PUT" : "POST";
    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(values),
    });
    if (res.ok) {
      return (await res.json()) as Pathway;
    }
  } catch {
    // Dev mock fallback
  }

  return {
    id: id ?? `pw-${Date.now()}`,
    name: values.name,
    theme: values.theme,
    level: values.level,
    description: values.description,
    steps: values.steps,
    unlockRule: values.unlockRule,
    badgeAwardedId: values.badgeAwardedId,
    badgeName: values.badgeAwardedId ? "Faithful Disciple" : null,
    learnersCount: 0,
    published: values.published,
    lockedUntilInfo: values.unlockRule === "none" ? "Available immediately" : "Locked by prerequisite",
    updatedAt: new Date().toISOString().slice(0, 10),
  };
}

export async function deletePathway(id: string): Promise<void> {
  try {
    await fetch(`/api/proxy/pathways/${id}`, { method: "DELETE" });
  } catch {
    // Dev mock fallback
  }
}
