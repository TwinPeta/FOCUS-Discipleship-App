/**
 * tests/unit/scope.test.ts
 *
 * WHAT: Super-mentors only reach their own community data
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import {
  canAccessCommunity,
  filterByScope,
  shouldHideCrossCommunityControls,
} from "@/lib/permissions/scope";
import { Role } from "@/types/enums";

describe("community scope", () => {
  const superMentor = {
    role: Role.SuperMentor,
    communityId: "comm-1",
  };
  const systemAdmin = { role: Role.SystemAdmin };
  const contentAdmin = { role: Role.ContentAdmin };

  it("restricts super-mentors to their own community", () => {
    expect(canAccessCommunity(superMentor, "comm-1")).toBe(true);
    expect(canAccessCommunity(superMentor, "comm-2")).toBe(false);
    expect(canAccessCommunity(superMentor, null)).toBe(false);
    expect(shouldHideCrossCommunityControls(superMentor)).toBe(true);
  });

  it("allows admins across all communities", () => {
    expect(canAccessCommunity(systemAdmin, "comm-1")).toBe(true);
    expect(canAccessCommunity(systemAdmin, "comm-2")).toBe(true);
    expect(canAccessCommunity(contentAdmin, "comm-2")).toBe(true);
    expect(shouldHideCrossCommunityControls(systemAdmin)).toBe(false);
  });

  it("filters list items to the user's community for super-mentors", () => {
    const items = [
      { id: "1", communityId: "comm-1" },
      { id: "2", communityId: "comm-2" },
      { id: "3", communityId: null },
    ];
    expect(filterByScope(superMentor, items)).toEqual([
      { id: "1", communityId: "comm-1" },
    ]);
    expect(filterByScope(systemAdmin, items)).toHaveLength(3);
  });
});
