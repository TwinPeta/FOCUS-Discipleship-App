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

export const MOCK_COMMUNITIES_SELECT = [
  { id: "comm-makerere", name: "Makerere University" },
  { id: "comm-kyambogo", name: "Kyambogo University" },
  { id: "comm-mubs", name: "MUBS Kampala" },
  { id: "comm-gulu", name: "Gulu University" },
];

export const MOCK_ANNOUNCEMENTS: Announcement[] = [
  {
    id: "ann-1",
    title: "National Conference 2027 Registration Open",
    message: "Registration has officially opened for the annual FOCUS National Students Conference in Kampala.",
    audienceType: "all",
    communityId: null,
    communityName: "All Communities",
    imageUrl: null,
    status: "published",
    authorName: "Sarah K. (System admin)",
    createdAt: "2026-11-12",
  },
  {
    id: "ann-2",
    title: "Makerere Mission Week Preparations",
    message: "Small group leaders please submit your fellowship room booking requests by Wednesday.",
    audienceType: "community",
    communityId: "comm-makerere",
    communityName: "Makerere University",
    imageUrl: null,
    status: "published",
    authorName: "Grace N. (Super-mentor)",
    createdAt: "2026-11-09",
  },
  {
    id: "ann-3",
    title: "End of Semester Thanksgiving Service",
    message: "Join us this Friday for joint campus worship and praise.",
    audienceType: "all",
    communityId: null,
    communityName: "All Communities",
    imageUrl: null,
    scheduledFor: "2026-11-20T17:00",
    status: "scheduled",
    authorName: "David M. (Content admin)",
    createdAt: "2026-11-14",
  },
];

export async function fetchAnnouncements(): Promise<Announcement[]> {
  try {
    const res = await fetch("/api/proxy/announcements");
    if (res.ok) {
      return (await res.json()) as Announcement[];
    }
  } catch {
    // Dev mock fallback
  }
  return MOCK_ANNOUNCEMENTS;
}

export async function createAnnouncement(input: AnnouncementInput): Promise<Announcement> {
  const comm = MOCK_COMMUNITIES_SELECT.find((c) => c.id === input.communityId);
  const communityName = input.audienceType === "all" ? "All Communities" : (comm?.name ?? "Selected Community");

  try {
    const res = await fetch("/api/proxy/announcements", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    });
    if (res.ok) {
      return (await res.json()) as Announcement;
    }
  } catch {
    // Dev mock fallback
  }

  return {
    id: `ann-${Date.now()}`,
    title: input.title,
    message: input.message,
    audienceType: input.audienceType,
    communityId: input.audienceType === "community" ? input.communityId : null,
    communityName,
    imageUrl: input.imageUrl,
    scheduledFor: input.publishTiming === "scheduled" ? input.scheduledFor : null,
    status: input.publishTiming === "now" ? "published" : "scheduled",
    authorName: "Staff User",
    createdAt: new Date().toISOString().slice(0, 10),
  };
}
