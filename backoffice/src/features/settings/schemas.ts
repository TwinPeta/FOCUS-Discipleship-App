/**
 * src/features/settings/schemas.ts
 *
 * WHAT: Zod schemas for charter, consent texts, minors rules, and data retention settings
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

import { z } from "zod";

export const charterSchema = z.object({
  version: z.string().trim().min(1, "Version is required"),
  effectiveDate: z.string().min(1, "Effective date is required"),
  text: z.string().trim().min(10, "Charter text is required"),
  requireAcceptance: z.boolean().default(true),
  repromptOnChange: z.boolean().default(true),
});

export type CharterSettings = z.infer<typeof charterSchema>;

export const consentTextsSchema = z.object({
  accountCreationText: z.string().trim().min(5, "Account creation consent text is required"),
  communitySpacesText: z.string().trim().min(5, "Community spaces consent text is required"),
  mentorContactText: z.string().trim().min(5, "Mentor contact consent text is required"),
});

export type ConsentTextsSettings = z.infer<typeof consentTextsSchema>;

export const minorsSchema = z.object({
  ageThreshold: z.number().int().min(13).max(21).default(18),
  requireGuardianConsent: z.boolean().default(true),
  limitAdultDirectMessages: z.boolean().default(true),
  requireVerifiedMentors: z.boolean().default(true),
});

export type MinorsSettings = z.infer<typeof minorsSchema>;

export const retentionSchema = z.object({
  inactiveRetentionMonths: z.number().int().min(1).max(120).default(24),
  deletionDeadlineDays: z.number().int().min(1).max(90).default(30),
});

export type RetentionSettings = z.infer<typeof retentionSchema>;

/** Requests to join a specific community: approved at once (default) or by a super-mentor. */
export type JoinRequestSettings = { autoApprove: boolean };
