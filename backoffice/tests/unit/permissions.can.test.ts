/**
 * tests/unit/permissions.can.test.ts
 *
 * WHAT: Permission helper matches the design matrix
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import { can, isOwnCommunityOnly } from "@/lib/permissions/can";
import { Role } from "@/types/enums";

describe("permission matrix (can)", () => {
  it("grants system admin full access to all resources", () => {
    const admin = { role: Role.SystemAdmin };
    expect(can(admin, "content", "administer")).toBe(true);
    expect(can(admin, "members", "consult")).toBe(true);
    expect(can(admin, "coverPhotos", "modify")).toBe(true);
    expect(can(admin, "reports", "reviewL2")).toBe(true);
  });

  it("limits content admin to content, pathways, cover photos, L2 review, and read-only dashboards", () => {
    const contentAdmin = { role: Role.ContentAdmin };
    expect(can(contentAdmin, "content", "modify")).toBe(true);
    expect(can(contentAdmin, "content", "validate")).toBe(true);
    expect(can(contentAdmin, "pathways", "validate")).toBe(true);
    expect(can(contentAdmin, "coverPhotos", "modify")).toBe(true);
    expect(can(contentAdmin, "reports", "reviewL2")).toBe(true);
    expect(can(contentAdmin, "dashboards", "consult")).toBe(true);
    expect(can(contentAdmin, "members", "consult")).toBe(false);
    expect(can(contentAdmin, "joinRequests", "validate")).toBe(false);
  });

  it("limits super-mentor to own-community actions and L1 moderation", () => {
    const superMentor = { role: Role.SuperMentor };
    expect(can(superMentor, "joinRequests", "validate")).toBe(true);
    expect(can(superMentor, "community", "modify")).toBe(true);
    expect(can(superMentor, "communitySpaces", "moderateL1")).toBe(true);
    expect(can(superMentor, "reports", "reviewL1")).toBe(true);
    expect(can(superMentor, "members", "consult")).toBe(true);
    expect(can(superMentor, "coverPhotos", "modify")).toBe(false);
    expect(can(superMentor, "reports", "reviewL2")).toBe(false);

    expect(isOwnCommunityOnly(superMentor, "joinRequests")).toBe(true);
    expect(isOwnCommunityOnly(superMentor, "members")).toBe(true);
  });

  it("returns false for null or unauthenticated users", () => {
    expect(can(null, "content", "consult")).toBe(false);
    expect(can(undefined, "dashboards", "consult")).toBe(false);
  });
});
