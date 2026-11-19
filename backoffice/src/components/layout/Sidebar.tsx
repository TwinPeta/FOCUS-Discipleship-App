/**
 * src/components/layout/Sidebar.tsx
 *
 * WHAT: Cream navigation sidebar (240px) with labelled groups, a blue active item and the signed-in user chip with
 *       Sign out at the bottom. Below the md breakpoint it is a slide-in drawer opened from the mobile header.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { LogOut, X } from "lucide-react";
import { getNavGroupsForRole, isNavActive } from "./nav-config";
import { useShell } from "./ShellContext";
import { useSession } from "@/features/auth/hooks/useSession";
import { useSignOut } from "@/features/auth/hooks/useSignOut";
import { getInitials as initialsOf } from "@/components/common/InitialsAvatar";
import { ROUTES } from "@/lib/constants/routes";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Role } from "@/types/enums";

export function Sidebar() {
  const pathname = usePathname();
  const { user } = useSession();
  const { mobileNavOpen, setMobileNavOpen } = useShell();
  const { signOut, signingOut } = useSignOut();

  const isSuperMentor = user?.role === Role.SuperMentor;
  const access = user?.access;
  // A custom or edited role hides the pages it cannot view
  const navGroups = getNavGroupsForRole(user?.role)
    .map((g) => ({ ...g, items: g.items.filter((i) => !access || !i.module || access[i.module]?.includes("V")) }))
    .filter((g) => g.items.length > 0);

  // Close the mobile drawer after navigating.
  useEffect(() => {
    setMobileNavOpen(false);
  }, [pathname, setMobileNavOpen]);

  // Esc closes the mobile drawer.
  useEffect(() => {
    if (!mobileNavOpen) return;
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setMobileNavOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [mobileNavOpen, setMobileNavOpen]);

  return (
    <>
      {mobileNavOpen && (
        <div
          className="fixed inset-0 z-40 bg-ink/40 backdrop-blur-[2px] md:hidden"
          onClick={() => setMobileNavOpen(false)}
          aria-hidden="true"
        />
      )}

      <aside
        id="app-sidebar"
        aria-label="Sidebar"
        className={`fixed inset-y-0 left-0 z-50 flex w-[260px] flex-col gap-1 overflow-y-auto bg-gradient-to-b from-[#FFF1CC] via-[#FFF8E6] to-[#FFFBF2] px-3.5 py-[22px] text-ink shadow-xl transition-transform duration-200 ease-out
          ${mobileNavOpen ? "translate-x-0" : "-translate-x-full"}
          md:sticky md:top-0 md:z-20 md:h-dvh md:w-sidebar md:shrink-0 md:translate-x-0 md:shadow-none`}
      >
        {/* Brand */}
        <div className="flex items-center justify-between gap-2.5 px-1.5 pb-4">
          <Link
            href={isSuperMentor ? ROUTES.myCommunity : ROUTES.dashboard}
            className="flex min-w-0 items-center gap-2.5 rounded-lg"
          >
            <span className="grid h-[42px] w-[42px] shrink-0 place-items-center rounded-xl bg-white text-[15px] font-black text-ink">
              FCU
            </span>
            <span className="min-w-0 text-base font-extrabold leading-[1.05]">
              {isSuperMentor ? "My caregroup" : "Backoffice"}
              <span className="mt-0.5 block text-[13px] font-medium">
                {isSuperMentor ? "Super-mentor view" : "Student caregroups"}
              </span>
            </span>
          </Link>
          <button
            type="button"
            onClick={() => setMobileNavOpen(false)}
            aria-label="Close navigation menu"
            className="grid h-9 w-9 place-items-center rounded-lg hover:bg-black/10 md:hidden"
          >
            <X className="h-5 w-5" aria-hidden="true" />
          </button>
        </div>

        <nav aria-label="Main navigation" className="flex flex-col gap-1">
          {navGroups.map((group) => (
            <div key={group.group} role="group" aria-label={group.group} className="flex flex-col gap-1">
              {!isSuperMentor && (
                <p className="px-3.5 pb-0.5 pt-3 text-xs font-extrabold uppercase tracking-[0.08em] opacity-70">
                  {group.group}
                </p>
              )}
              {group.items.map((item) => {
                const active = isNavActive(pathname, item.href);
                const Icon = item.icon;
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    aria-current={active ? "page" : undefined}
                    className={`flex h-[42px] items-center gap-3 rounded-nav px-3.5 text-base transition ${
                      active
                        ? "bg-grad-blue font-extrabold text-white"
                        : "font-semibold text-ink hover:bg-white/60"
                    }`}
                  >
                    <Icon className="h-[22px] w-[22px] shrink-0" strokeWidth={2} aria-hidden="true" />
                    <span className="truncate">{item.label}</span>
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        {/* Signed-in user */}
        {user && (
          <div className="mt-auto rounded-nav bg-white/60 p-2.5">
            <div className="flex items-center gap-2.5">
              <Link
                href={ROUTES.account}
                aria-label="My account"
                className="grid h-[38px] w-[38px] shrink-0 place-items-center rounded-full bg-white text-[13px] font-extrabold"
              >
                {initialsOf(user.fullName)}
              </Link>
              <div className="min-w-0 text-sm leading-[1.15]">
                <b className="block truncate">{user.fullName}</b>
                <span className="block truncate">{ROLE_LABELS[user.role] ?? user.role}</span>
              </div>
            </div>
            <button
              type="button"
              onClick={signOut}
              disabled={signingOut}
              className="btn btn-secondary mt-2.5 w-full justify-center"
            >
              <LogOut className="h-4 w-4" aria-hidden="true" />
              {signingOut ? "Signing out…" : "Sign out"}
            </button>
          </div>
        )}
      </aside>
    </>
  );
}
