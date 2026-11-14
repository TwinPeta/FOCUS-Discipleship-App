/**
 * src/components/layout/breadcrumb-trail.ts
 *
 * WHAT: Turns a pathname into human-readable breadcrumb segments (pure function, unit tested)
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { ROUTES } from "@/lib/constants/routes";

export interface Crumb {
  label: string;
  /** Null when the segment has no page of its own (not clickable). */
  href: string | null;
}

/** Human labels for every static page. Intermediate paths not listed here are skipped. */
export const ROUTE_LABELS: Record<string, string> = {
  [ROUTES.dashboard]: "Dashboard",
  [ROUTES.reports]: "Reports",
  [ROUTES.joinRequests]: "Join requests",
  [ROUTES.communities]: "Communities",
  [ROUTES.communityNew]: "New community",
  [ROUTES.institutions]: "Institutions",
  [ROUTES.institutionNew]: "New institution",
  [ROUTES.members]: "Members",
  [ROUTES.memberNew]: "Add member",
  [ROUTES.memberImport]: "Import CSV",
  [ROUTES.content]: "Content library",
  [ROUTES.contentNew]: "New content",
  [ROUTES.pathways]: "Pathways",
  [ROUTES.pathwayNew]: "New pathway",
  [ROUTES.badges]: "Badges",
  [ROUTES.announcements]: "Announcements",
  [ROUTES.moderation]: "Moderation",
  [ROUTES.moderationReports]: "Reports",
  [ROUTES.moderationTestimonies]: "Testimonies",
  [ROUTES.moderationPosts]: "Posts",
  [ROUTES.moderationSanctions]: "Sanctions",
  [ROUTES.notifications]: "Notification rules",
  [ROUTES.privacy]: "Privacy",
  [ROUTES.guardianConsents]: "Guardian consents",
  [ROUTES.dataRequests]: "Data requests",
  [ROUTES.roles]: "Roles & matrix",
  [ROUTES.staffNew]: "Add staff member",
  [ROUTES.auditLog]: "Audit log",
  [ROUTES.settings]: "Settings",
  [ROUTES.account]: "My account",
  [ROUTES.myCommunity]: "My community",
  [ROUTES.myCommunityJoinRequests]: "Join requests",
  [ROUTES.myCommunityMembers]: "Members",
  [ROUTES.myCommunityModeration]: "Moderation",
  [ROUTES.myCommunityResources]: "Resources",
};

function humanize(segment: string) {
  const text = decodeURIComponent(segment).replace(/[-_]+/g, " ");
  return text.charAt(0).toUpperCase() + text.slice(1);
}

/**
 * Builds the trail for `pathname`, always starting at the role's home page.
 * e.g. "/communities/abc123" -> Dashboard / Communities / Details
 */
export function buildBreadcrumbs(pathname: string, homeHref: string): Crumb[] {
  const clean = pathname.split(/[?#]/)[0].replace(/\/+$/, "") || "/";
  const homeCrumb: Crumb = { label: ROUTE_LABELS[homeHref] ?? "Home", href: homeHref };
  if (clean === "/" || clean === homeHref) return [{ ...homeCrumb, href: null }];

  const segments = clean.split("/").filter(Boolean);
  const crumbs: Crumb[] = [homeCrumb];

  segments.forEach((segment, index) => {
    const href = "/" + segments.slice(0, index + 1).join("/");
    if (href === homeHref) return;
    const isLast = index === segments.length - 1;
    const known = ROUTE_LABELS[href];

    if (known) {
      crumbs.push({ label: known, href: isLast ? null : href });
    } else if (isLast) {
      // Dynamic id (e.g. /communities/abc123) or an unlisted page.
      const parentKnown = index > 0 && ROUTE_LABELS["/" + segments.slice(0, index).join("/")];
      crumbs.push({ label: parentKnown ? "Details" : humanize(segment), href: null });
    }
    // Unknown intermediate segments (e.g. /roles/staff) have no page, so they are skipped.
  });

  return crumbs;
}

/** Nearest clickable ancestor, used by the quick-back button. */
export function getParentHref(crumbs: Crumb[]): string | null {
  for (let i = crumbs.length - 2; i >= 0; i--) {
    if (crumbs[i].href) return crumbs[i].href;
  }
  return null;
}
