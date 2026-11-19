/**
 * src/features/communities/schemas.ts
 *
 * WHAT: Zod schemas for community forms
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import { z } from "zod";
import { CommunityKind } from "@/types/enums";

export const CommunityStatus = {
  Active: "ACTIVE",
  Closed: "CLOSED",
} as const;
export type CommunityStatus = (typeof CommunityStatus)[keyof typeof CommunityStatus];

export const communitySchema = z.object({
  institutionId: z.string().min(1, "Campus is required"),
  kind: z.enum([CommunityKind.General, CommunityKind.Specific]).default(CommunityKind.Specific),
  name: z.string().trim().min(2, "Caregroup name is required"),
  description: z.string().trim().max(1000).optional().or(z.literal("")),
  coverPhotoUrl: z.string().optional().or(z.literal("")),
  meetingDay: z.string().trim().optional().or(z.literal("")),
  meetingTime: z.string().trim().optional().or(z.literal("")),
  meetingPlace: z.string().trim().optional().or(z.literal("")),
  superMentorId: z.string().optional().or(z.literal("")),
  mentorIds: z.array(z.string()).default([]),
  openForJoinRequests: z.boolean().default(true),
  status: z.enum([CommunityStatus.Active, CommunityStatus.Closed]).default(CommunityStatus.Active),
});

export type CommunityInput = z.infer<typeof communitySchema>;

export interface Community extends CommunityInput {
  id: string;
  institutionName?: string;
  superMentorName?: string | null;
  memberCount: number;
  createdAt: string;
}
