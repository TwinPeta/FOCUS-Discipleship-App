/**
 * src/features/moderation/schemas.ts
 *
 * WHAT: Moderation types, Zod schemas, and Level 1 / Level 2 role action helpers
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import { z } from "zod";
import { can } from "@/lib/permissions/can";
import { ReportStatus, Role, SanctionType } from "@/types/enums";
import type { SessionUser } from "@/types/user";

export type ReportAction =
  | "DISMISS"
  | "WARN"
  | "HIDE"
  | "ESCALATE"
  | "SUSPEND"
  | "DELETE";

export type TestimonyAction = "APPROVE" | "REQUEST_CHANGES" | "REJECT";
export type PostAction = "KEEP" | "HIDE" | "WARN_AUTHOR" | "ESCALATE";

export interface ModerationReport {
  id: string;
  reason: string;
  reporterName: string;
  reportedUserId: string;
  reportedUserName: string;
  reportedUserRole: Role;
  communityId: string;
  communityName: string;
  details: string;
  screenshotUrl?: string | null;
  earlierReportsCount: number;
  status: ReportStatus;
  createdAt: string;
}

export interface ModerationTestimony {
  id: string;
  authorName: string;
  communityId: string;
  communityName: string;
  title?: string;
  story: string;
  /** Photos attached by the student. */
  photoUrls?: string[];
  /** The story video (at most 2 minutes). */
  videoUrl?: string | null;
  studentAgreement: boolean;
  notes?: string | null;
  status: "PENDING" | "APPROVED" | "CHANGES_REQUESTED" | "REJECTED";
  createdAt: string;
}

export interface ModerationPost {
  id: string;
  kind: "PRAYER" | "POST" | "COMMENT";
  authorName: string;
  communityId: string;
  communityName: string;
  content: string;
  reportCount: number;
  hidden: boolean;
  createdAt: string;
}

export interface SanctionRecord {
  id: string;
  userId: string;
  userName: string;
  communityId: string;
  communityName: string;
  type: SanctionType;
  reason: string;
  issuedBy: string;
  issuedAt: string;
  active: boolean;
}

export const moderationNoteSchema = z.object({
  notes: z.string().trim().min(3, "Please add a short note for the audit log"),
});

export function isReportAboutSuperMentor(report: ModerationReport): boolean {
  return report.reportedUserRole === Role.SuperMentor;
}

export function getAllowedReportActions(
  user: Pick<SessionUser, "role"> | null | undefined,
  report: ModerationReport,
): ReportAction[] {
  if (!user) return [];

  // Reports about a super-mentor must be handled by an admin
  if (isReportAboutSuperMentor(report) && user.role !== Role.SystemAdmin) {
    return [];
  }

  if (can(user, "reports", "administer")) {
    return ["DISMISS", "WARN", "HIDE", "SUSPEND", "DELETE"];
  }

  if (can(user, "reports", "reviewL2")) {
    return ["DISMISS", "WARN", "HIDE", "ESCALATE"];
  }

  if (can(user, "reports", "reviewL1")) {
    return ["DISMISS", "WARN", "HIDE", "ESCALATE"];
  }

  return [];
}
