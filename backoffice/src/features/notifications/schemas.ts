/**
 * src/features/notifications/schemas.ts
 *
 * WHAT: Zod schemas for notification rules, templates, and inactivity thresholds
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

import { z } from "zod";

export const templateSchema = z.object({
  title: z.string().min(1, "Template title is required"),
  message: z.string().min(1, "Template message is required"),
  channels: z.object({
    inApp: z.boolean(),
    email: z.boolean(),
  }),
});

export type TemplateFormValues = z.infer<typeof templateSchema>;

export const inactivitySchema = z.object({
  days: z.number().int().min(1, "Threshold must be at least 1 day").max(365, "Threshold cannot exceed 365 days"),
});

export type InactivityFormValues = z.infer<typeof inactivitySchema>;
