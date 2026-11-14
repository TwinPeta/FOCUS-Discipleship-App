/**
 * tests/unit/content-workflow.test.ts
 *
 * WHAT: Allowed workflow transitions and who can perform them
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import {
  canTransitionContent,
  ContentAction,
  getAvailableTransitions,
} from "@/features/content/workflow";
import { ContentStatus, Role } from "@/types/enums";

describe("content validation workflow", () => {
  const contentAdmin = { role: Role.ContentAdmin };
  const systemAdmin = { role: Role.SystemAdmin };
  const superMentor = { role: Role.SuperMentor };

  it("allows draft -> in review -> published for content and system admins", () => {
    expect(
      canTransitionContent(
        ContentStatus.Draft,
        ContentAction.SubmitForReview,
        contentAdmin,
      ),
    ).toBe(true);

    expect(
      canTransitionContent(
        ContentStatus.InReview,
        ContentAction.ApproveAndPublish,
        contentAdmin,
      ),
    ).toBe(true);

    expect(
      canTransitionContent(
        ContentStatus.InReview,
        ContentAction.RequestChanges,
        systemAdmin,
      ),
    ).toBe(true);
  });

  it("prevents invalid state jumps (draft directly to published)", () => {
    expect(
      canTransitionContent(
        ContentStatus.Draft,
        ContentAction.ApproveAndPublish,
        systemAdmin,
      ),
    ).toBe(false);
  });

  it("prevents super-mentors from publishing or modifying content", () => {
    expect(
      canTransitionContent(
        ContentStatus.InReview,
        ContentAction.ApproveAndPublish,
        superMentor,
      ),
    ).toBe(false);
    expect(getAvailableTransitions(ContentStatus.Draft, superMentor)).toEqual([]);
  });
});
