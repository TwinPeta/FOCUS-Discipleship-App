import { apiClient } from "@/lib/api/client";
import { mutate } from "@/lib/api/mutate";
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
  /** Set when the super-mentor leads more than one community. */
  communityName?: string;
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

export async function fetchMyCommunityOverview(): Promise<MyCommunityOverview> {
  return apiClient<MyCommunityOverview>("/my-community");
}

export async function approveOwnJoinRequest(requestId: string): Promise<void> {
  await mutate(`/my-community/join-requests/${requestId}/approve`, "POST");
}

export async function declineOwnJoinRequest(
  requestId: string,
  reason?: string,
): Promise<void> {
  await mutate(`/my-community/join-requests/${requestId}/decline`, "POST", { reason });
}

export async function updateNextMeeting(
  details: NextMeetingDetails,
): Promise<NextMeetingDetails> {
  return mutate<NextMeetingDetails>("/my-community/meeting", "PATCH", details);
}

export async function sendFollowUpReminder(memberId: string): Promise<void> {
  await mutate(`/my-community/members/${memberId}/remind`, "POST");
}

export async function writeToCommunityGroup(payload: {
  subject: string;
  message: string;
}): Promise<void> {
  await mutate("/my-community/announcements", "POST", payload);
}

export async function resolveOwnReportL1(
  reportId: string,
  decision: "dismissed" | "escalated",
  note?: string,
): Promise<void> {
  await mutate(`/my-community/moderation/${reportId}`, "POST", { decision, note });
}
