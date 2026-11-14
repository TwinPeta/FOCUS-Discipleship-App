/**
 * src/components/layout/nav-config.ts
 *
 * WHAT: Nav groups (Overview, Community, Content, Safety, Privacy, Admin) with role visibility and icons,
 *       plus quick actions for the command palette. Single source of truth for sidebar + Ctrl/Cmd+K.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import {
  Award,
  BarChart3,
  BellRing,
  BookOpen,
  Building2,
  Compass,
  ContactRound,
  FileKey,
  FilePlus2,
  FolderKanban,
  History,
  Home,
  LayoutDashboard,
  Megaphone,
  Plus,
  Settings,
  ShieldAlert,
  ShieldCheck,
  Upload,
  UserCircle,
  UserPlus,
  Users,
  type LucideIcon,
} from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";
import { Role } from "@/types/enums";

export interface NavLink {
  href: string;
  label: string;
  icon: LucideIcon;
  /** Short explanation shown in the command palette */
  description?: string;
  /** Extra search terms for the command palette */
  keywords?: string[];
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
      { href: ROUTES.dashboard, label: "Dashboard", icon: LayoutDashboard, description: "Key numbers at a glance", keywords: ["home", "overview"] },
      { href: ROUTES.reports, label: "Reports", icon: BarChart3, description: "Engagement and growth reports", keywords: ["analytics", "stats", "export"] },
    ],
  },
  {
    group: "Community",
    items: [
      { href: ROUTES.joinRequests, label: "Join requests", icon: UserPlus, description: "Approve students asking to join", keywords: ["approve", "pending"], roles: [Role.SystemAdmin] },
      { href: ROUTES.communities, label: "Communities", icon: Users, description: "Campus communities and their leaders", keywords: ["groups", "campus"] },
      { href: ROUTES.institutions, label: "Institutions", icon: Building2, description: "Universities and colleges", keywords: ["school", "university"], roles: [Role.SystemAdmin] },
      { href: ROUTES.members, label: "Members", icon: ContactRound, description: "Students, mentors and alumni", keywords: ["people", "students", "users"], roles: [Role.SystemAdmin] },
    ],
  },
  {
    group: "Content & Discipleship",
    items: [
      { href: ROUTES.content, label: "Content library", icon: BookOpen, description: "Videos, devotionals, quizzes, documents", keywords: ["video", "devotional", "quiz"] },
      { href: ROUTES.pathways, label: "Pathways", icon: Compass, description: "Step-by-step discipleship journeys", keywords: ["course", "journey"] },
      { href: ROUTES.badges, label: "Badges", icon: Award, description: "Rewards for progress", keywords: ["achievements"] },
      { href: ROUTES.announcements, label: "Announcements", icon: Megaphone, description: "Messages to communities", keywords: ["news", "broadcast"] },
    ],
  },
  {
    group: "Safety & Privacy",
    items: [
      { href: ROUTES.moderationReports, label: "Moderation", icon: ShieldAlert, description: "Reported posts, testimonies, sanctions", keywords: ["reports", "flag", "abuse"] },
      { href: ROUTES.guardianConsents, label: "Privacy & consents", icon: FileKey, description: "Guardian consents and data requests", keywords: ["gdpr", "guardian", "minor"], roles: [Role.SystemAdmin] },
      { href: ROUTES.notifications, label: "Notification rules", icon: BellRing, description: "When and how members are notified", keywords: ["push", "email", "alerts"] },
    ],
  },
  {
    group: "Administration",
    items: [
      { href: ROUTES.roles, label: "Roles & matrix", icon: ShieldCheck, description: "Staff access and permissions", keywords: ["permissions", "staff", "access"], roles: [Role.SystemAdmin] },
      { href: ROUTES.auditLog, label: "Audit log", icon: History, description: "Who changed what, and when", keywords: ["history", "activity"], roles: [Role.SystemAdmin] },
      { href: ROUTES.settings, label: "Settings", icon: Settings, description: "App-wide configuration", keywords: ["config", "preferences"], roles: [Role.SystemAdmin] },
      { href: ROUTES.account, label: "My account", icon: UserCircle, description: "Profile, password and sessions", keywords: ["profile", "password", "me"] },
    ],
  },
];

export const MY_COMMUNITY_NAV: NavLink[] = [
  { href: ROUTES.myCommunity, label: "Overview", icon: Home, description: "Your community at a glance", keywords: ["home", "dashboard"] },
  { href: ROUTES.myCommunityJoinRequests, label: "Join requests", icon: UserPlus, description: "Approve students asking to join", keywords: ["approve", "pending"] },
  { href: ROUTES.myCommunityMembers, label: "Members", icon: Users, description: "People in your community", keywords: ["students", "people"] },
  { href: ROUTES.myCommunityModeration, label: "Moderation (L1)", icon: ShieldAlert, description: "First-level review of reports", keywords: ["reports", "flag"] },
  { href: ROUTES.myCommunityResources, label: "Resources", icon: FolderKanban, description: "Shared files and materials", keywords: ["files", "documents"] },
  { href: ROUTES.account, label: "My account", icon: UserCircle, description: "Profile, password and sessions", keywords: ["profile", "password", "me"] },
];

/** Shortcuts to "create" pages, shown in the command palette. */
export const QUICK_ACTIONS: NavLink[] = [
  { href: ROUTES.communityNew, label: "Create community", icon: Plus, keywords: ["new", "add"], roles: [Role.SystemAdmin] },
  { href: ROUTES.institutionNew, label: "Add institution", icon: Building2, keywords: ["new", "university"], roles: [Role.SystemAdmin] },
  { href: ROUTES.memberNew, label: "Add member", icon: UserPlus, keywords: ["new", "student"], roles: [Role.SystemAdmin] },
  { href: ROUTES.memberImport, label: "Import members from CSV", icon: Upload, keywords: ["bulk", "upload", "spreadsheet"], roles: [Role.SystemAdmin] },
  { href: ROUTES.contentNew, label: "New content", icon: FilePlus2, keywords: ["video", "devotional", "document", "create"], roles: [Role.SystemAdmin, Role.ContentAdmin] },
  { href: ROUTES.quizNew, label: "New quiz", icon: FilePlus2, keywords: ["create", "questions"], roles: [Role.SystemAdmin, Role.ContentAdmin] },
  { href: ROUTES.pathwayNew, label: "Create pathway", icon: Compass, keywords: ["new", "journey"], roles: [Role.SystemAdmin, Role.ContentAdmin] },
  { href: ROUTES.staffNew, label: "Add staff member", icon: ShieldCheck, keywords: ["new", "admin", "invite"], roles: [Role.SystemAdmin] },
];

function allowed(item: NavLink, role: Role) {
  return !item.roles || item.roles.includes(role);
}

export function getFilteredNavGroups(userRole?: Role): NavGroup[] {
  if (!userRole) return [];

  return NAV_GROUPS.map((grp) => ({
    group: grp.group,
    items: grp.items.filter((item) => allowed(item, userRole)),
  })).filter((grp) => grp.items.length > 0);
}

/** Navigation groups for whichever shell the role uses. */
export function getNavGroupsForRole(userRole?: Role): NavGroup[] {
  if (!userRole) return [];
  if (userRole === Role.SuperMentor) {
    return [{ group: "My community", items: MY_COMMUNITY_NAV }];
  }
  return getFilteredNavGroups(userRole);
}

export function getQuickActions(userRole?: Role): NavLink[] {
  if (!userRole) return [];
  return QUICK_ACTIONS.filter((item) => item.roles && item.roles.includes(userRole));
}

const ROOT_HREFS: string[] = [ROUTES.home, ROUTES.dashboard, ROUTES.myCommunity];
/** Nav items that point at a sub-page but represent the whole section (e.g. Moderation -> /moderation/reports). */
const SECTION_ROOTS: string[] = [ROUTES.moderation, ROUTES.privacy];

/** Whether `pathname` should highlight the nav item `href`. */
export function isNavActive(pathname: string, href: string): boolean {
  if (pathname === href) return true;
  if (ROOT_HREFS.includes(href)) return false;
  const section = SECTION_ROOTS.find((root) => href.startsWith(`${root}/`)) ?? href;
  return pathname === section || pathname.startsWith(`${section}/`);
}
