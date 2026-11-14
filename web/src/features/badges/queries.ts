/**
 * src/features/badges/queries.ts
 *
 * WHAT: Badge queries and mutations
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

export type BadgeRuleType =
  | "join_community"
  | "finish_quizzes"
  | "pray_requests"
  | "complete_pathway"
  | "attend_meetings_streak";

export interface Badge {
  id: string;
  name: string;
  description: string;
  ruleType: BadgeRuleType;
  ruleTargetCount: number; // e.g. 5 quizzes, 10 prayers, 4 meetings
  ruleDescription: string;
  icon: string; // e.g. "award", "shield", "flame", "star", "sparkles", "heart", "book"
  earnedCount: number;
  visibleOnProfile: boolean;
  status: "active" | "draft" | "archived";
  updatedAt: string;
}

export interface BadgeInput {
  name: string;
  description: string;
  ruleType: BadgeRuleType;
  ruleTargetCount: number;
  icon: string;
  visibleOnProfile: boolean;
  status: "active" | "draft" | "archived";
}

export const RULE_DEFINITIONS: Record<
  BadgeRuleType,
  { label: string; formatDescription: (count: number) => string; defaultCount: number }
> = {
  join_community: {
    label: "Join a fellowship community",
    formatDescription: () => "Awarded upon successfully joining a campus community",
    defaultCount: 1,
  },
  finish_quizzes: {
    label: "Complete discipleship quizzes",
    formatDescription: (count) => `Score a passing grade on ${count} discipleship quizzes`,
    defaultCount: 5,
  },
  pray_requests: {
    label: "Pray for prayer requests",
    formatDescription: (count) => `Pray for ${count} community prayer requests on the prayer wall`,
    defaultCount: 10,
  },
  complete_pathway: {
    label: "Complete a full pathway",
    formatDescription: () => "Finish all required steps in a discipleship pathway",
    defaultCount: 1,
  },
  attend_meetings_streak: {
    label: "Attend consecutive meetings",
    formatDescription: (count) => `Attend ${count} weekly fellowship meetings in a row`,
    defaultCount: 4,
  },
};

export const MOCK_BADGES: Badge[] = [
  {
    id: "bdg-1",
    name: "Faithful Disciple",
    description: "Awarded to members who finish their core discipleship pathway.",
    ruleType: "complete_pathway",
    ruleTargetCount: 1,
    ruleDescription: "Finish all required steps in Foundations of Discipleship",
    icon: "award",
    earnedCount: 284,
    visibleOnProfile: true,
    status: "active",
    updatedAt: "2026-11-05",
  },
  {
    id: "bdg-2",
    name: "Servant Leader",
    description: "Equipped to facilitate small groups and mentor peers.",
    ruleType: "complete_pathway",
    ruleTargetCount: 1,
    ruleDescription: "Finish all required steps in Campus Leadership & Witness",
    icon: "shield",
    earnedCount: 79,
    visibleOnProfile: true,
    status: "active",
    updatedAt: "2026-11-08",
  },
  {
    id: "bdg-3",
    name: "Prayer Warrior",
    description: "Regular intercession on the community prayer wall.",
    ruleType: "pray_requests",
    ruleTargetCount: 20,
    ruleDescription: "Pray for 20 community prayer requests on the prayer wall",
    icon: "flame",
    earnedCount: 142,
    visibleOnProfile: true,
    status: "active",
    updatedAt: "2026-10-22",
  },
  {
    id: "bdg-4",
    name: "Faithful Attendee",
    description: "Consistent fellowship presence across weekly meetings.",
    ruleType: "attend_meetings_streak",
    ruleTargetCount: 4,
    ruleDescription: "Attend 4 weekly fellowship meetings in a row",
    icon: "star",
    earnedCount: 310,
    visibleOnProfile: true,
    status: "active",
    updatedAt: "2026-10-15",
  },
  {
    id: "bdg-5",
    name: "Scripture Explorer",
    description: "High achievement on Scripture study quizzes.",
    ruleType: "finish_quizzes",
    ruleTargetCount: 5,
    ruleDescription: "Score a passing grade on 5 discipleship quizzes",
    icon: "book",
    earnedCount: 195,
    visibleOnProfile: true,
    status: "active",
    updatedAt: "2026-10-18",
  },
];

export async function fetchBadges(): Promise<Badge[]> {
  try {
    const res = await fetch("/api/proxy/badges");
    if (res.ok) {
      return (await res.json()) as Badge[];
    }
  } catch {
    // Dev mock fallback
  }
  return MOCK_BADGES;
}

export async function saveBadge(input: BadgeInput, id?: string): Promise<Badge> {
  const ruleMeta = RULE_DEFINITIONS[input.ruleType];
  const ruleDescription = ruleMeta ? ruleMeta.formatDescription(input.ruleTargetCount) : "";

  try {
    const url = id ? `/api/proxy/badges/${id}` : "/api/proxy/badges";
    const method = id ? "PUT" : "POST";
    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ...input, ruleDescription }),
    });
    if (res.ok) {
      return (await res.json()) as Badge;
    }
  } catch {
    // Dev mock fallback
  }

  return {
    id: id ?? `bdg-${Date.now()}`,
    name: input.name,
    description: input.description,
    ruleType: input.ruleType,
    ruleTargetCount: input.ruleTargetCount,
    ruleDescription,
    icon: input.icon,
    earnedCount: 0,
    visibleOnProfile: input.visibleOnProfile,
    status: input.status,
    updatedAt: new Date().toISOString().slice(0, 10),
  };
}

export async function deleteBadge(id: string): Promise<void> {
  try {
    await fetch(`/api/proxy/badges/${id}`, { method: "DELETE" });
  } catch {
    // Dev mock fallback
  }
}
