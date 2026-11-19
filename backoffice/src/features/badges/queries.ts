import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";
import { unwrapList } from "@/lib/api/unwrap";
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
    label: "Join a fellowship caregroup",
    formatDescription: () => "Awarded upon successfully joining a campus caregroup",
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

export async function fetchBadges(): Promise<Badge[]> {
  return unwrapList<Badge>(await apiClient<unknown>("/badges"));
}

export async function saveBadge(input: BadgeInput, id?: string): Promise<Badge> {
  const ruleMeta = RULE_DEFINITIONS[input.ruleType];
  const ruleDescription = ruleMeta ? ruleMeta.formatDescription(input.ruleTargetCount) : "";
  const payload = { ...input, ruleDescription };
  return id ? mutate<Badge>(`/badges/${id}`, "PUT", payload) : mutate<Badge>("/badges", "POST", payload);
}

export async function deleteBadge(id: string): Promise<void> {
  await mutate(`/badges/${id}`, "DELETE");
}
