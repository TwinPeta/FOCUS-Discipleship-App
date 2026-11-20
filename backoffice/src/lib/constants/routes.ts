/**
 * src/lib/constants/routes.ts
 *
 * WHAT: Central route map and role-to-home mapping
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { Role } from "@/types/enums";

export const ROUTES = {
  home: "/",
  forbidden: "/forbidden",

  // Auth
  login: "/login",
  forgotPassword: "/forgot-password",
  resetPassword: "/reset-password",

  // Backoffice shell
  dashboard: "/dashboard",
  joinRequests: "/join-requests",
  communities: "/communities",
  communityNew: "/communities/new",
  communityDetail: (id: string) => `/communities/${id}`,
  institutions: "/institutions",
  institutionNew: "/institutions/new",
  churches: "/institutions/churches",
  members: "/members",
  memberNew: "/members/new",
  memberImport: "/members/import",
  memberDetail: (id: string) => `/members/${id}`,
  memberChangeRole: (id: string) => `/members/${id}/change-role`,
  content: "/content",
  contentNew: "/content/new",
  contentDetail: (id: string) => `/content/${id}`,
  quizNew: "/content/new?type=quiz",
  pathways: "/pathways",
  pathwayNew: "/pathways/new",
  pathwayDetail: (id: string) => `/pathways/${id}`,
  badges: "/badges",
  moderation: "/moderation",
  moderationReports: "/moderation/reports",
  moderationTestimonies: "/moderation/testimonies",
  moderationPosts: "/moderation/posts",
  moderationSanctions: "/moderation/sanctions",
  announcements: "/announcements",
  notifications: "/notifications",
  privacy: "/privacy",
  guardianConsents: "/privacy/guardian-consents",
  dataRequests: "/privacy/data-requests",
  roles: "/roles",
  staffNew: "/roles/staff/new",
  roleMatrix: "/roles/matrix",
  roleNew: "/roles/new",
  roleDetail: (slug: string) => `/roles/${slug}`,
  auditLog: "/audit-log",
  reports: "/reports",
  settings: "/settings",
  account: "/account",

  // Super-mentor shell
  myCommunity: "/my-community",
  myCommunityJoinRequests: "/my-community/join-requests",
  myCommunityMembers: "/my-community/members",
  myCommunityModeration: "/my-community/moderation",
  myCommunityResources: "/my-community/resources",
} as const;

export const AUTH_ROUTES = [
  ROUTES.login,
  ROUTES.forgotPassword,
  ROUTES.resetPassword,
] as const;

export const MY_COMMUNITY_PREFIX = "/my-community";

export function getHomeRouteForRole(role: Role): string {
  switch (role) {
    case Role.SuperMentor:
      return ROUTES.myCommunity;
    case Role.ContentAdmin:
    case Role.SystemAdmin:
      return ROUTES.dashboard;
    default:
      return ROUTES.forbidden;
  }
}
