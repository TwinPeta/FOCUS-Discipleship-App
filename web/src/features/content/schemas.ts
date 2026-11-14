/**
 * src/features/content/schemas.ts
 *
 * WHAT: Zod schemas and types for content items, video, devotional, and document forms
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import { z } from "zod";
import { ContentStatus, ContentType } from "@/types/enums";

export const MAX_VIDEO_BYTES = 500 * 1024 * 1024; // 500 MB

export const contentBaseSchema = z.object({
  title: z.string().trim().min(2, "Title is required"),
  type: z.enum([
    ContentType.Video,
    ContentType.Devotional,
    ContentType.Quiz,
    ContentType.Document,
  ]),
  bibleLink: z.string().trim().min(1, "Link a Bible character or text"),
  language: z.string().trim().min(2).default("English"),
  tags: z.array(z.string()).default([]),
  description: z.string().trim().optional().or(z.literal("")),
  validatorName: z.string().trim().optional().or(z.literal("")),
  pathwayIds: z.array(z.string()).default([]),
  body: z.string().optional().or(z.literal("")),
  videoUrl: z.string().optional().or(z.literal("")),
  thumbnailUrl: z.string().optional().or(z.literal("")),
  documentUrl: z.string().optional().or(z.literal("")),
});

export type ContentInput = z.infer<typeof contentBaseSchema>;

export interface ApprovalTrailEntry {
  id: string;
  action: string;
  actorName: string;
  notes?: string | null;
  createdAt: string;
}

export interface ContentItem extends ContentInput {
  id: string;
  status: ContentStatus;
  authorName: string;
  validatedAt?: string | null;
  updatedAt: string;
  approvalTrail?: ApprovalTrailEntry[];
}
