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
  BarChart3,
  Bell,
  BookOpen,
  Building2,
  Compass,
  Eye,
  FilePlus2,
  FileText,
  FolderKanban,
  Home,
  Inbox,
  KeyRound,
  LayoutDashboard,
  Lock,
  Megaphone,
  Plus,
  Route,
  Settings,
  ShieldAlert,
  ShieldCheck,
  Star,
  Upload,
  UserPlus,
  UserRound,
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
  /** Permission module this page belongs to; hidden when a custom or edited role lacks View on it */
  module?: string;
}

export interface NavGroup {
  group: string;
  items: NavLink[];
}

export const NAV_GROUPS: NavGroup[] = [
  {
    group: "Overview",
    items: [
      { href: ROUTES.dashboard, module: "Dashboard", label: "Dashboard", icon: LayoutDashboard, description: "Key numbers at a glance", keywords: ["home", "overview"] },
      { href: ROUTES.reports, module: "Reports & exports", label: "Reports", icon: BarChart3, description: "Engagement and growth reports", keywords: ["analytics", "stats", "export"] },
    ],
  },
  {
    group: "Caregroup",
    items: [
      { href: ROUTES.joinRequests, module: "New members", label: "New members", icon: Inbox, description: "Welcome students asking to join", keywords: ["approve", "pending", "new members"], roles: [Role.SystemAdmin] },
      { href: ROUTES.communities, module: "Caregroups & meetings", label: "Caregroups", icon: Users, description: "Caregroups and their leaders", keywords: ["groups", "campus", "communities"] },
      { href: ROUTES.institutions, module: "Campuses", label: "Campuses", icon: Building2, description: "Campuses and local churches", keywords: ["school", "university", "institutions", "church"], roles: [Role.SystemAdmin] },
      { href: ROUTES.members, module: "Members", label: "Members", icon: UserRound, description: "Students, mentors and alumni", keywords: ["people", "students", "users"], roles: [Role.SystemAdmin] },
    ],
  },
  {
    group: "Content",
    items: [
      { href: ROUTES.content, module: "Content library", label: "Content", icon: BookOpen, description: "Videos, devotionals, quizzes, documents", keywords: ["video", "devotional", "quiz", "library"] },
      { href: ROUTES.pathways, module: "Pathways & badges", label: "Pathways", icon: Route, description: "Step-by-step discipleship journeys", keywords: ["course", "journey"] },
      { href: ROUTES.badges, module: "Pathways & badges", label: "Badges", icon: Star, description: "Rewards for progress", keywords: ["achievements"] },
      { href: ROUTES.announcements, module: "Announcements", label: "Announcements", icon: Megaphone, description: "Messages to caregroups", keywords: ["news", "broadcast", "stories"] },
      { href: ROUTES.notifications, module: "Notification rules", label: "Notifications", icon: Bell, description: "When and how members are notified", keywords: ["push", "email", "alerts"] },
    ],
  },
  {
    group: "Safety",
    items: [
      { href: ROUTES.moderationReports, module: "Moderation level 1", label: "Moderation", icon: Eye, description: "Reported posts, testimonies, sanctions", keywords: ["reports", "flag", "abuse"] },
      { href: ROUTES.guardianConsents, module: "Consents & data requests", label: "Privacy", icon: Lock, description: "Guardian consents and data requests", keywords: ["gdpr", "guardian", "minor", "consents"], roles: [Role.SystemAdmin] },
    ],
  },
  {
    group: "Admin",
    items: [
      { href: ROUTES.roles, label: "Roles & permissions", icon: KeyRound, description: "Staff access and permissions", keywords: ["permissions", "staff", "access", "matrix"], roles: [Role.SystemAdmin] },
      { href: ROUTES.auditLog, module: "Audit log", label: "Audit log", icon: FileText, description: "Who changed what, and when", keywords: ["history", "activity"], roles: [Role.SystemAdmin] },
      { href: ROUTES.settings, module: "Settings", label: "Settings", icon: Settings, description: "App-wide configuration", keywords: ["config", "preferences", "charter"], roles: [Role.SystemAdmin] },
    ],
  },
];

export const MY_COMMUNITY_NAV: NavLink[] = [
  { href: ROUTES.myCommunity, label: "My caregroup", icon: Home, description: "Your caregroup at a glance", keywords: ["home", "dashboard"] },
  { href: ROUTES.myCommunityJoinRequests, label: "New members", icon: UserPlus, description: "Approve students asking to join", keywords: ["approve", "pending"] },
  { href: ROUTES.myCommunityMembers, label: "Members", icon: Users, description: "People in your caregroup", keywords: ["students", "people"] },
  { href: ROUTES.myCommunityModeration, label: "Moderation", icon: ShieldAlert, description: "First-level review of reports", keywords: ["reports", "flag"] },
  { href: ROUTES.myCommunityResources, label: "Resources", icon: FolderKanban, description: "Shared files and materials", keywords: ["files", "documents"] },
];

/** Shortcuts to "create" pages, shown in the command palette. */
export const QUICK_ACTIONS: NavLink[] = [
  { href: ROUTES.communityNew, label: "New caregroup", icon: Plus, keywords: ["new", "add"], roles: [Role.SystemAdmin] },
  { href: ROUTES.institutionNew, label: "Add campus", icon: Building2, keywords: ["new", "university", "institution"], roles: [Role.SystemAdmin] },
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
    return [{ group: "My caregroup", items: MY_COMMUNITY_NAV }];
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
