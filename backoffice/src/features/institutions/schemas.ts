/**
 * src/features/institutions/schemas.ts
 *
 * WHAT: Zod schemas for institution forms
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import { z } from "zod";

export const InstitutionType = {
  University: "UNIVERSITY",
  HighSchool: "HIGH_SCHOOL",
} as const;
export type InstitutionType = (typeof InstitutionType)[keyof typeof InstitutionType];

export const institutionSchema = z.object({
  name: z.string().trim().min(2, "Institution name is required"),
  type: z.enum([InstitutionType.University, InstitutionType.HighSchool]),
  country: z.string().trim().min(2, "Country is required").default("Uganda"),
  city: z.string().trim().min(2, "City is required"),
  generalCoverUrl: z.string().trim().optional().or(z.literal("")),
  shownInSignup: z.boolean().default(true),
});

export type InstitutionInput = z.infer<typeof institutionSchema>;

export interface Institution extends InstitutionInput {
  id: string;
  communityCount: number;
  studentCount: number;
  createdAt: string;
}
