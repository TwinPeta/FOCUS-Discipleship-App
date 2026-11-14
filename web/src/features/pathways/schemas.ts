/**
 * src/features/pathways/schemas.ts
 *
 * WHAT: Zod schemas for pathways and pathway steps
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

import { z } from "zod";

export const pathwayStepSchema = z.object({
  id: z.string(),
  contentId: z.string().min(1, "Content item is required"),
  title: z.string().min(1, "Step title is required"),
  contentType: z.enum(["video", "devotional", "document", "quiz"]),
  order: z.number().int().min(0),
  required: z.boolean().default(true),
});

export type PathwayStepInput = z.infer<typeof pathwayStepSchema>;

export const pathwaySchema = z.object({
  name: z.string().min(2, "Pathway name must be at least 2 characters"),
  theme: z.string().min(2, "Theme is required"),
  level: z.enum(["Beginner", "Intermediate", "Advanced"]).default("Beginner"),
  description: z.string().optional(),
  steps: z.array(pathwayStepSchema).min(1, "Pathway must contain at least one step"),
  unlockRule: z.enum(["none", "previous_pathway", "profile_complete", "mentor_assigned"]).default("none"),
  badgeAwardedId: z.string().nullable().optional(),
  published: z.boolean().default(false),
});

export type PathwayFormValues = z.infer<typeof pathwaySchema>;
