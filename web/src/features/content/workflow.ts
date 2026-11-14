/**
 * src/features/content/workflow.ts
 *
 * WHAT: Allowed transitions: draft to in review to published, changes requested, archive; who may do each
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import { can } from "@/lib/permissions/can";
import { ContentStatus } from "@/types/enums";
import type { SessionUser } from "@/types/user";

export const ContentAction = {
  SubmitForReview: "SUBMIT_FOR_REVIEW",
  ApproveAndPublish: "APPROVE_AND_PUBLISH",
  RequestChanges: "REQUEST_CHANGES",
  Archive: "ARCHIVE",
  RestoreToDraft: "RESTORE_TO_DRAFT",
} as const;
export type ContentAction = (typeof ContentAction)[keyof typeof ContentAction];

export interface WorkflowTransition {
  action: ContentAction;
  label: string;
  targetStatus: ContentStatus;
}

const TRANSITIONS_BY_STATUS: Record<ContentStatus, WorkflowTransition[]> = {
  [ContentStatus.Draft]: [
    {
      action: ContentAction.SubmitForReview,
      label: "Submit for review",
      targetStatus: ContentStatus.InReview,
    },
    {
      action: ContentAction.Archive,
      label: "Archive",
      targetStatus: ContentStatus.Archived,
    },
  ],
  [ContentStatus.InReview]: [
    {
      action: ContentAction.ApproveAndPublish,
      label: "Approve and publish",
      targetStatus: ContentStatus.Published,
    },
    {
      action: ContentAction.RequestChanges,
      label: "Request changes",
      targetStatus: ContentStatus.Draft,
    },
    {
      action: ContentAction.Archive,
      label: "Archive",
      targetStatus: ContentStatus.Archived,
    },
  ],
  [ContentStatus.Published]: [
    {
      action: ContentAction.Archive,
      label: "Archive",
      targetStatus: ContentStatus.Archived,
    },
  ],
  [ContentStatus.Archived]: [
    {
      action: ContentAction.RestoreToDraft,
      label: "Restore to draft",
      targetStatus: ContentStatus.Draft,
    },
  ],
};

type UserWithRole = Pick<SessionUser, "role"> | null | undefined;

export function canPerformContentAction(
  user: UserWithRole,
  action: ContentAction,
): boolean {
  if (!user) return false;
  switch (action) {
    case ContentAction.ApproveAndPublish:
    case ContentAction.RequestChanges:
      return can(user, "content", "validate");
    case ContentAction.SubmitForReview:
    case ContentAction.Archive:
    case ContentAction.RestoreToDraft:
      return can(user, "content", "modify");
    default:
      return false;
  }
}

export function canTransitionContent(
  fromStatus: ContentStatus,
  action: ContentAction,
  user: UserWithRole,
): boolean {
  const allowedFromStatus = TRANSITIONS_BY_STATUS[fromStatus]?.some(
    (t) => t.action === action,
  );
  if (!allowedFromStatus) return false;
  return canPerformContentAction(user, action);
}

export function getAvailableTransitions(
  status: ContentStatus,
  user: UserWithRole,
): WorkflowTransition[] {
  return (TRANSITIONS_BY_STATUS[status] ?? []).filter((t) =>
    canPerformContentAction(user, t.action),
  );
}
