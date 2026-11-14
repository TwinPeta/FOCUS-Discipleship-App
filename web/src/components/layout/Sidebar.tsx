/**
 * src/components/layout/Sidebar.tsx
 *
 * WHAT: Yellow sidebar (240px) with role-filtered navigation, user summary, and sign out
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROUTES } from "@/lib/constants/routes";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Role } from "@/types/enums";

interface NavItem {
  href: string;
  label: string;
}

const BACKOFFICE_NAV: NavItem[] = [
  { href: ROUTES.dashboard, label: "Dashboard" },
  { href: ROUTES.reports, label: "Reports" },
  { href: ROUTES.joinRequests, label: "Join requests" },
  { href: ROUTES.communities, label: "Communities" },
  { href: ROUTES.institutions, label: "Institutions" },
  { href: ROUTES.members, label: "Members" },
  { href: ROUTES.content, label: "Content" },
  { href: ROUTES.moderationReports, label: "Moderation" },
  { href: ROUTES.guardianConsents, label: "Privacy & consents" },
  { href: ROUTES.roles, label: "Roles & permissions" },
  { href: ROUTES.auditLog, label: "Audit log" },
  { href: ROUTES.settings, label: "Settings" },
  { href: ROUTES.account, label: "My account" },
];

const CONTENT_ADMIN_NAV: NavItem[] = [
  { href: ROUTES.dashboard, label: "Dashboard" },
  { href: ROUTES.reports, label: "Reports" },
  { href: ROUTES.communities, label: "Communities" },
  { href: ROUTES.content, label: "Content" },
  { href: ROUTES.moderationReports, label: "Moderation" },
  { href: ROUTES.account, label: "My account" },
];

const MY_COMMUNITY_NAV: NavItem[] = [
  { href: ROUTES.myCommunity, label: "My community" },
  { href: ROUTES.myCommunityJoinRequests, label: "Join requests" },
  { href: ROUTES.myCommunityMembers, label: "Members" },
  { href: ROUTES.myCommunityModeration, label: "Moderation" },
  { href: ROUTES.myCommunityResources, label: "Resources" },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { user } = useSession();

  const items =
    user?.role === Role.SuperMentor
      ? MY_COMMUNITY_NAV
      : user?.role === Role.ContentAdmin
        ? CONTENT_ADMIN_NAV
        : BACKOFFICE_NAV;

  async function handleSignOut() {
    await fetch("/api/proxy/auth/logout", { method: "POST" });
    router.push(ROUTES.login);
    router.refresh();
  }

  return (
    <aside className="flex w-full flex-col justify-between bg-primary p-4 text-foreground md:w-sidebar md:min-h-screen md:shrink-0">
      <div className="space-y-6">
        <div className="px-2 pt-2">
          <p className="text-xs font-semibold uppercase tracking-wider text-foreground/75">
            FCU Backoffice
          </p>
          <p className="text-base font-bold text-foreground">
            {user?.role === Role.SuperMentor ? "My Community" : "Staff Portal"}
          </p>
        </div>

        <nav aria-label="Main navigation" className="space-y-1">
          {items.map((item) => {
            const active =
              pathname === item.href ||
              (item.href !== ROUTES.myCommunity && pathname.startsWith(`${item.href}/`));
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`block rounded-nav px-3 py-2 text-sm font-medium transition ${
                  active
                    ? "bg-white text-foreground shadow-sm"
                    : "text-foreground/90 hover:bg-white/40"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="mt-6 space-y-2 rounded-nav bg-white/60 p-3 text-xs">
        <div>
          <p className="font-semibold text-foreground">{user?.fullName ?? "Staff"}</p>
          <p className="text-foreground/75">
            {user?.role ? ROLE_LABELS[user.role] : ""}
          </p>
        </div>
        <button
          type="button"
          onClick={handleSignOut}
          className="w-full rounded-md border border-border bg-white px-2.5 py-1.5 text-xs font-medium text-foreground hover:bg-surface"
        >
          Sign out
        </button>
      </div>
    </aside>
  );
}
