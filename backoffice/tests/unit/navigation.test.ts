/**
 * tests/unit/navigation.test.ts
 *
 * WHAT: Breadcrumb building, quick-back target, active nav matching, role-filtered quick actions
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import { buildBreadcrumbs, getParentHref } from "@/components/layout/breadcrumb-trail";
import { getNavGroupsForRole, getQuickActions, isNavActive } from "@/components/layout/nav-config";
import { ROUTES } from "@/lib/constants/routes";
import { Role } from "@/types/enums";

describe("buildBreadcrumbs", () => {
  it("shows only the home crumb on the home page", () => {
    expect(buildBreadcrumbs("/dashboard", ROUTES.dashboard)).toEqual([{ label: "Dashboard", href: null }]);
  });

  it("builds a trail for a nested create page", () => {
    expect(buildBreadcrumbs("/communities/new", ROUTES.dashboard)).toEqual([
      { label: "Dashboard", href: "/dashboard" },
      { label: "Communities", href: "/communities" },
      { label: "New community", href: null },
    ]);
  });

  it("labels dynamic ids as Details", () => {
    const crumbs = buildBreadcrumbs("/members/abc-123", ROUTES.dashboard);
    expect(crumbs.at(-1)).toEqual({ label: "Details", href: null });
  });

  it("skips intermediate segments that have no page", () => {
    const labels = buildBreadcrumbs("/roles/staff/new", ROUTES.dashboard).map((c) => c.label);
    expect(labels).toEqual(["Dashboard", "Roles & matrix", "Add staff member"]);
  });

  it("does not duplicate the super-mentor home", () => {
    const labels = buildBreadcrumbs("/my-community/members", ROUTES.myCommunity).map((c) => c.label);
    expect(labels).toEqual(["My community", "Members"]);
  });

  it("quick back goes to the nearest clickable parent", () => {
    expect(getParentHref(buildBreadcrumbs("/moderation/posts", ROUTES.dashboard))).toBe("/moderation");
    expect(getParentHref(buildBreadcrumbs("/dashboard", ROUTES.dashboard))).toBeNull();
  });
});

describe("isNavActive", () => {
  it("keeps Moderation active across all moderation pages", () => {
    expect(isNavActive("/moderation/sanctions", ROUTES.moderationReports)).toBe(true);
  });

  it("does not treat the dashboard as a prefix", () => {
    expect(isNavActive("/communities", ROUTES.dashboard)).toBe(false);
  });

  it("does not confuse similar prefixes", () => {
    expect(isNavActive("/content", ROUTES.communities)).toBe(false);
    expect(isNavActive("/communities/new", ROUTES.communities)).toBe(true);
  });
});

describe("role filtering", () => {
  it("hides admin-only quick actions from content admins", () => {
    const labels = getQuickActions(Role.ContentAdmin).map((a) => a.label);
    expect(labels).toContain("New content");
    expect(labels).not.toContain("Create community");
  });

  it("gives super-mentors the my-community nav and no quick actions", () => {
    expect(getNavGroupsForRole(Role.SuperMentor)[0].items[0].href).toBe(ROUTES.myCommunity);
    expect(getQuickActions(Role.SuperMentor)).toEqual([]);
  });
});
