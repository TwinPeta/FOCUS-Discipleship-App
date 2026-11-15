import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";
import { unwrapList } from "@/lib/api/unwrap";
/**
 * src/features/announcements/queries.ts
 *
 * WHAT: Announcement queries and mutations
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

export interface Announcement {
  id: string;
  title: string;
  message: string;
  audienceType: "all" | "community";
  communityId?: string | null;
  communityName?: string | null;
  imageUrl?: string | null;
  scheduledFor?: string | null;
  status: "published" | "scheduled" | "draft";
  authorName: string;
  createdAt: string;
}

export interface AnnouncementInput {
  title: string;
  message: string;
  audienceType: "all" | "community";
  communityId?: string | null;
  imageUrl?: string | null;
  publishTiming: "now" | "scheduled";
  scheduledFor?: string | null;
}

export async function fetchAnnouncements(): Promise<Announcement[]> {
  return unwrapList<Announcement>(await apiClient<unknown>("/announcements"));
}

export async function createAnnouncement(input: AnnouncementInput): Promise<Announcement> {
  return mutate<Announcement>("/announcements", "POST", input);
}
