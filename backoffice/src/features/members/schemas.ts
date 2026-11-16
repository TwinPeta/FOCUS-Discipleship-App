/**
 * src/features/members/schemas.ts
 *
 * WHAT: Zod schemas for add user and member filters
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import { z } from "zod";
import { GuardianConsentStatus, MemberStatus, Role } from "@/types/enums";

export const DEFAULT_MINOR_AGE_THRESHOLD = 18;

export function isMinorBirthdate(
  birthdate: string | undefined | null,
  ageThreshold = DEFAULT_MINOR_AGE_THRESHOLD,
): boolean {
  if (!birthdate) return false;
  const dob = new Date(birthdate);
  if (Number.isNaN(dob.getTime())) return false;
  const today = new Date();
  let age = today.getFullYear() - dob.getFullYear();
  const monthDiff = today.getMonth() - dob.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
    age--;
  }
  return age < ageThreshold;
}

export interface Member {
  id: string;
  fullName: string;
  username: string;
  email: string;
  phone?: string | null;
  birthdate?: string | null;
  isMinor: boolean;
  guardianConsentStatus?: GuardianConsentStatus | null;
  /** Minors: the guardian the student entered in the app (screen 24). */
  guardian?: {
    name: string | null;
    relationship: string | null;
    phone: string | null;
    email: string | null;
  } | null;
  role: Role;
  status: MemberStatus;
  institutionId: string;
  institutionName: string;
  communityId?: string | null;
  communityName?: string | null;
  lastActiveAt?: string | null;
  participation?: {
    resourcesCompleted: number;
    meetingsAttended: number;
    badgesEarned: number;
  };
}

export const addUserSchema = z.object({
  fullName: z.string().trim().min(2, "Full name is required"),
  email: z.string().trim().email("Valid email is required"),
  phone: z.string().trim().optional().or(z.literal("")),
  birthdate: z.string().optional().or(z.literal("")),
  role: z.enum([
    Role.Student,
    Role.Mentor,
    Role.SuperMentor,
    Role.Alumni,
    Role.ContentAdmin,
    Role.SystemAdmin,
  ]),
  institutionId: z.string().min(1, "Institution is required"),
  communityId: z.string().optional().or(z.literal("")),
  guardianConsentReceived: z.boolean().default(false),
  sendInvitation: z.boolean().default(true),
});

export type AddUserInput = z.infer<typeof addUserSchema>;

export const suspendMemberSchema = z.object({
  reason: z.string().trim().min(5, "Please provide a reason for suspension"),
});

export type SuspendMemberInput = z.infer<typeof suspendMemberSchema>;
