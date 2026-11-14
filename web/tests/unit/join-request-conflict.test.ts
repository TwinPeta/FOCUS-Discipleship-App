/**
 * tests/unit/join-request-conflict.test.ts
 *
 * WHAT: One specific community per student: conflicts are detected and skipped on bulk approve
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import {
  hasCommunityConflict,
  partitionBulkApprove,
  type JoinRequestItem,
} from "@/features/join-requests/conflicts";
import { JoinRequestStatus } from "@/types/enums";

const baseRequest = (overrides: Partial<JoinRequestItem>): JoinRequestItem => ({
  id: "req-1",
  studentId: "stu-1",
  studentUsername: "john_doe",
  institutionName: "Makerere University",
  requestedCommunityId: "comm-2",
  requestedCommunityName: "Engineering CU",
  requestedAt: "2026-11-10",
  status: JoinRequestStatus.Pending,
  ...overrides,
});

describe("join request conflict detection", () => {
  it("flags a conflict when the student already belongs to another specific community", () => {
    const conflicting = baseRequest({
      currentSpecificCommunityId: "comm-1",
      currentSpecificCommunityName: "Science CU",
    });
    const clean = baseRequest({ id: "req-2", currentSpecificCommunityId: null });

    expect(hasCommunityConflict(conflicting)).toBe(true);
    expect(hasCommunityConflict(clean)).toBe(false);
  });

  it("skips conflicting requests during bulk approve partitioning", () => {
    const clean = baseRequest({ id: "req-1" });
    const conflicting = baseRequest({
      id: "req-2",
      currentSpecificCommunityId: "comm-9",
      currentSpecificCommunityName: "Law CU",
    });

    const result = partitionBulkApprove([clean, conflicting]);
    expect(result.approvable.map((r) => r.id)).toEqual(["req-1"]);
    expect(result.skippedConflicts.map((r) => r.id)).toEqual(["req-2"]);
  });
});
