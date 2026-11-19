/**
 * src/features/join-requests/conflicts.ts
 *
 * WHAT: Conflict detection for one-specific-community-per-student and bulk-approve partitioning
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

import type { JoinRequestStatus } from "@/types/enums";

export interface JoinRequestItem {
  id: string;
  studentId: string;
  studentUsername: string;
  institutionName: string;
  requestedCommunityId: string;
  requestedCommunityName: string;
  requestedAt: string;
  status: JoinRequestStatus;
  welcomedAt?: string | null;
  currentSpecificCommunityId?: string | null;
  currentSpecificCommunityName?: string | null;
}

export function hasCommunityConflict(request: JoinRequestItem): boolean {
  if (!request.currentSpecificCommunityId) return false;
  return request.currentSpecificCommunityId !== request.requestedCommunityId;
}

export function partitionBulkApprove(requests: JoinRequestItem[]): {
  approvable: JoinRequestItem[];
  skippedConflicts: JoinRequestItem[];
} {
  const approvable: JoinRequestItem[] = [];
  const skippedConflicts: JoinRequestItem[] = [];

  for (const req of requests) {
    if (hasCommunityConflict(req)) {
      skippedConflicts.push(req);
    } else {
      approvable.push(req);
    }
  }

  return { approvable, skippedConflicts };
}
