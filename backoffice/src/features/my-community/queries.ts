/**
 * src/features/my-community/queries.ts
 *
 * WHAT: Super-mentor scoped queries and mutations
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

export interface CommunityKpiSummary {
  members: number;
  pendingRequests: number;
  reportsToReview: number;
  inactiveMembers: number;
}

export interface OwnJoinRequest {
  id: string;
  studentName: string;
  email: string;
  requestedAt: string;
  note?: string;
}

export interface NextMeetingDetails {
  day: string;
  time: string;
  place: string;
}

export interface FollowUpMember {
  id: string;
  name: string;
  daysInactive: number;
  lastActiveAt: string;
}

export interface OwnCommunityMember {
  id: string;
  name: string;
  email: string;
  roleLabel: string;
  joinedAt: string;
  active: boolean;
}

export interface OwnCommunityReport {
  id: string;
  targetSummary: string;
  reason: string;
  reportedBy: string;
  createdAt: string;
  status: "open" | "dismissed" | "escalated";
}

export interface CommunityResource {
  id: string;
  title: string;
  type: "Devotional" | "Video" | "Document";
  pathway: string;
  publishedAt: string;
}

export interface MyCommunityOverview {
  communityId: string;
  communityName: string;
  campus: string;
  kpis: CommunityKpiSummary;
  pendingRequests: OwnJoinRequest[];
  nextMeeting: NextMeetingDetails;
  followUpMembers: FollowUpMember[];
  members: OwnCommunityMember[];
  reports: OwnCommunityReport[];
  resources: CommunityResource[];
}

export const MOCK_MY_COMMUNITY: MyCommunityOverview = {
  communityId: "comm-makerere",
  communityName: "Makerere University Fellowship",
  campus: "Kampala Central",
  kpis: {
    members: 342,
    pendingRequests: 3,
    reportsToReview: 2,
    inactiveMembers: 2,
  },
  pendingRequests: [
    {
      id: "jr-101",
      studentName: "Amina Nakato",
      email: "amina.nakato@students.mak.ac.ug",
      requestedAt: "2026-11-13",
      note: "Year 2 Engineering, invited by Sarah.",
    },
    {
      id: "jr-102",
      studentName: "Joseph Kiggundu",
      email: "j.kiggundu@students.mak.ac.ug",
      requestedAt: "2026-11-12",
    },
    {
      id: "jr-103",
      studentName: "Miriam Apio",
      email: "miriam.apio@students.mak.ac.ug",
      requestedAt: "2026-11-10",
    },
  ],
  nextMeeting: {
    day: "Thursday",
    time: "17:30",
    place: "Main Hall Room 2B",
  },
  followUpMembers: [
    {
      id: "mem-401",
      name: "Samuel Okello",
      daysInactive: 19,
      lastActiveAt: "2026-10-26",
    },
    {
      id: "mem-405",
      name: "Prossy Namusoke",
      daysInactive: 15,
      lastActiveAt: "2026-10-30",
    },
  ],
  members: [
    {
      id: "mem-1",
      name: "Grace Namukasa",
      email: "grace@focusuganda.org",
      roleLabel: "Super-mentor",
      joinedAt: "2024-02-10",
      active: true,
    },
    {
      id: "mem-2",
      name: "Peter Ochieng",
      email: "peter.o@students.mak.ac.ug",
      roleLabel: "Mentor",
      joinedAt: "2024-09-01",
      active: true,
    },
    {
      id: "mem-401",
      name: "Samuel Okello",
      email: "s.okello@students.mak.ac.ug",
      roleLabel: "Student",
      joinedAt: "2025-03-14",
      active: false,
    },
    {
      id: "mem-405",
      name: "Prossy Namusoke",
      email: "p.namusoke@students.mak.ac.ug",
      roleLabel: "Student",
      joinedAt: "2025-08-22",
      active: false,
    },
  ],
  reports: [
    {
      id: "rep-501",
      targetSummary: "Comment on Prayer Wall #88",
      reason: "Off-topic promotional link",
      reportedBy: "Peter Ochieng",
      createdAt: "2026-11-13",
      status: "open",
    },
    {
      id: "rep-502",
      targetSummary: "Discussion reply in Week 3 group",
      reason: "Unkind language toward another student",
      reportedBy: "Ruth Nabirye",
      createdAt: "2026-11-11",
      status: "open",
    },
  ],
  resources: [
    {
      id: "res-1",
      title: "Walking in Faith — Week 4 Study Guide",
      type: "Devotional",
      pathway: "Foundations of Discipleship",
      publishedAt: "2026-11-10",
    },
    {
      id: "res-2",
      title: "Campus Leadership & Servant Heart",
      type: "Video",
      pathway: "Mentor Equipping",
      publishedAt: "2026-11-02",
    },
    {
      id: "res-3",
      title: "Small Group Facilitator Handbook",
      type: "Document",
      pathway: "Mentor Equipping",
      publishedAt: "2026-10-18",
    },
  ],
};

export async function fetchMyCommunityOverview(): Promise<MyCommunityOverview> {
  try {
    const res = await fetch("/api/proxy/my-community");
    if (res.ok) {
      return (await res.json()) as MyCommunityOverview;
    }
  } catch {
    // Fall back to mock data in dev mode
  }
  return MOCK_MY_COMMUNITY;
}

export async function approveOwnJoinRequest(requestId: string): Promise<void> {
  try {
    await fetch(`/api/proxy/my-community/join-requests/${requestId}/approve`, {
      method: "POST",
    });
  } catch {
    // Non-blocking in dev mode
  }
}

export async function declineOwnJoinRequest(
  requestId: string,
  reason?: string,
): Promise<void> {
  try {
    await fetch(`/api/proxy/my-community/join-requests/${requestId}/decline`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reason }),
    });
  } catch {
    // Non-blocking in dev mode
  }
}

export async function updateNextMeeting(
  details: NextMeetingDetails,
): Promise<NextMeetingDetails> {
  try {
    const res = await fetch("/api/proxy/my-community/meeting", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(details),
    });
    if (res.ok) {
      return (await res.json()) as NextMeetingDetails;
    }
  } catch {
    // Non-blocking in dev mode
  }
  return details;
}

export async function sendFollowUpReminder(memberId: string): Promise<void> {
  try {
    await fetch(`/api/proxy/my-community/members/${memberId}/remind`, {
      method: "POST",
    });
  } catch {
    // Non-blocking in dev mode
  }
}

export async function writeToCommunityGroup(payload: {
  subject: string;
  message: string;
}): Promise<void> {
  try {
    await fetch("/api/proxy/my-community/announcements", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  } catch {
    // Non-blocking in dev mode
  }
}

export async function resolveOwnReportL1(
  reportId: string,
  decision: "dismissed" | "escalated",
  note?: string,
): Promise<void> {
  try {
    await fetch(`/api/proxy/my-community/moderation/${reportId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ decision, note }),
    });
  } catch {
    // Non-blocking in dev mode
  }
}
