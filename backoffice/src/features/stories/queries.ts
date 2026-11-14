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

export const MOCK_STORIES: LandingStory[] = [
  {
    id: "sty-1",
    studentName: "Joshua Mukisa",
    institution: "Makerere University",
    videoUrl: "https://storage.googleapis.com/focus-media/stories/joshua.mp4",
    duration: "1:32",
    visible: true,
    order: 0,
    consentObtained: true,
    createdAt: "2026-10-14",
  },
  {
    id: "sty-2",
    studentName: "Faith Nakintu",
    institution: "Kyambogo University",
    videoUrl: "https://storage.googleapis.com/focus-media/stories/faith.mp4",
    duration: "2:05",
    visible: true,
    order: 1,
    consentObtained: true,
    createdAt: "2026-10-28",
  },
  {
    id: "sty-3",
    studentName: "Emmanuel Otim",
    institution: "Gulu University",
    videoUrl: "https://storage.googleapis.com/focus-media/stories/emmanuel.mp4",
    duration: "1:15",
    visible: true,
    order: 2,
    consentObtained: true,
    createdAt: "2026-11-02",
  },
];

export async function fetchLandingStories(): Promise<LandingStory[]> {
  try {
    const res = await fetch("/api/proxy/stories");
    if (res.ok) {
      return unwrapList<LandingStory>(await res.json());
    }
  } catch {
    // Dev mock fallback
  }
  return MOCK_STORIES;
}

export async function saveLandingStories(stories: LandingStory[]): Promise<LandingStory[]> {
  try {
    const res = await fetch("/api/proxy/stories/reorder", {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ stories }),
    });
    if (res.ok) {
      return unwrapList<LandingStory>(await res.json());
    }
  } catch {
    // Dev mock fallback
  }
  return stories;
}

export async function createLandingStory(input: StoryInput): Promise<LandingStory> {
  try {
    const res = await fetch("/api/proxy/stories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    if (res.ok) {
      return (await res.json()) as LandingStory;
    }
  } catch {
    // Dev mock fallback
  }

  return {
    id: `sty-${Date.now()}`,
    studentName: input.studentName,
    institution: input.institution,
    videoUrl: input.videoUrl,
    duration: input.duration,
    visible: true,
    order: 99,
    consentObtained: input.consentObtained,
    createdAt: new Date().toISOString().slice(0, 10),
  };
}
