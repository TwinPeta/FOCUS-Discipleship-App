/**
 * src/components/layout/nav-config.ts
 *
 * WHAT: Nav groups (Overview, Community, Content, Safety, Privacy, Admin) with role visibility
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { ROUTES } from "@/lib/constants/routes";
import { Role } from "@/types/enums";

export interface NavLink {
  href: string;
  label: string;
  roles?: Role[];
}

export interface NavGroup {
  group: string;
  items: NavLink[];
}

export const NAV_GROUPS: NavGroup[] = [
  {
    group: "Overview",
    items: [
      { href: ROUTES.dashboard, label: "Dashboard" },
      { href: ROUTES.reports, label: "Reports" },
    ],
  },
  {
    group: "Community",
    items: [
      { href: ROUTES.joinRequests, label: "Join requests", roles: [Role.SystemAdmin] },
      { href: ROUTES.communities, label: "Communities" },
      { href: ROUTES.institutions, label: "Institutions", roles: [Role.SystemAdmin] },
      { href: ROUTES.members, label: "Members", roles: [Role.SystemAdmin] },
    ],
  },
  {
    group: "Content & Discipleship",
    items: [
      { href: ROUTES.content, label: "Content library" },
      { href: ROUTES.pathways, label: "Pathways" },
      { href: ROUTES.badges, label: "Badges" },
      { href: ROUTES.announcements, label: "Announcements" },
    ],
  },
  {
    group: "Safety & Privacy",
    items: [
      { href: ROUTES.moderationReports, label: "Moderation" },
      { href: ROUTES.guardianConsents, label: "Privacy & consents", roles: [Role.SystemAdmin] },
      { href: ROUTES.notifications, label: "Notification rules" },
    ],
  },
  {
    group: "Administration",
    items: [
      { href: ROUTES.roles, label: "Roles & matrix", roles: [Role.SystemAdmin] },
      { href: ROUTES.auditLog, label: "Audit log", roles: [Role.SystemAdmin] },
      { href: ROUTES.settings, label: "Settings", roles: [Role.SystemAdmin] },
      { href: ROUTES.account, label: "My account" },
    ],
  },
];

export const MY_COMMUNITY_NAV: NavLink[] = [
  { href: ROUTES.myCommunity, label: "Overview" },
  { href: ROUTES.myCommunityJoinRequests, label: "Join requests" },
  { href: ROUTES.myCommunityMembers, label: "Members" },
  { href: ROUTES.myCommunityModeration, label: "Moderation (L1)" },
  { href: ROUTES.myCommunityResources, label: "Resources" },
  { href: ROUTES.account, label: "My account" },
];

export function getFilteredNavGroups(userRole?: Role): NavGroup[] {
  if (!userRole) return [];

  return NAV_GROUPS.map((grp) => ({
    group: grp.group,
    items: grp.items.filter((item) => {
      if (!item.roles) return true;
      return item.roles.includes(userRole);
    }),
  })).filter((grp) => grp.items.length > 0);
}
