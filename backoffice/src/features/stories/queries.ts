import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";
import { unwrapList } from "@/lib/api/unwrap";
/**
 * src/features/stories/queries.ts
 *
 * WHAT: Landing story videos queries and mutations
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

export interface LandingStory {
  id: string;
  studentName: string;
  institution: string;
  videoUrl: string;
  duration: string; // e.g. "1:45"
  visible: boolean;
  order: number;
  consentObtained: boolean;
  createdAt: string;
}

export interface StoryInput {
  studentName: string;
  institution: string;
  videoUrl: string;
  duration: string;
  consentObtained: boolean;
}

export async function fetchLandingStories(): Promise<LandingStory[]> {
  return unwrapList<LandingStory>(await apiClient<unknown>("/stories"));
}

export async function saveLandingStories(stories: LandingStory[]): Promise<LandingStory[]> {
  return unwrapList<LandingStory>(await mutate<unknown>("/stories/reorder", "PUT", { stories }));
}

export async function createLandingStory(input: StoryInput): Promise<LandingStory> {
  return mutate<LandingStory>("/stories", "POST", input);
}
