/**
 * src/components/layout/Sidebar.tsx
 *
 * WHAT: Yellow sidebar (240px) with role-filtered grouped navigation, accessible mobile menu, and user card
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Menu, X } from "lucide-react";
import { UserCard } from "./UserCard";
import {
  getFilteredNavGroups,
  MY_COMMUNITY_NAV,
} from "./nav-config";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROUTES } from "@/lib/constants/routes";
import { Role } from "@/types/enums";

export function Sidebar() {
  const pathname = usePathname();
  const { user } = useSession();
  const [mobileOpen, setMobileOpen] = useState(false);

  const isSuperMentor = user?.role === Role.SuperMentor;
  const navGroups = getFilteredNavGroups(user?.role);

  return (
    <>
      {/* Mobile top bar for tablet / phone (<1024px) */}
      <div className="flex md:hidden items-center justify-between bg-primary px-4 py-3 text-foreground shadow-sm">
        <div className="flex items-center gap-2">
          <span className="text-xs font-bold uppercase tracking-wider text-black/80">
            FCU
          </span>
          <span className="font-bold text-sm">
            {isSuperMentor ? "My Community" : "Staff Portal"}
          </span>
        </div>
        <button
          type="button"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-expanded={mobileOpen}
          aria-label={mobileOpen ? "Close navigation menu" : "Open navigation menu"}
          className="rounded p-1 text-foreground hover:bg-black/10 focus:outline-none focus:ring-2 focus:ring-foreground"
        >
          {mobileOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </div>

      <aside
        className={`${
          mobileOpen ? "block" : "hidden"
        } md:flex flex-col justify-between bg-primary p-4 text-foreground md:w-sidebar md:min-h-screen md:shrink-0 overflow-y-auto border-r border-amber-400/40`}
        aria-label="Sidebar Navigation"
      >
        <div className="space-y-6">
          <div className="hidden md:block px-2 pt-2">
            <p className="text-xs font-bold uppercase tracking-wider text-black/75">
              FCU Backoffice
            </p>
            <p className="text-lg font-black tracking-tight text-foreground">
              {isSuperMentor ? "My Community" : "Staff Portal"}
            </p>
          </div>

          <nav aria-label="Main navigation" className="space-y-4">
            {isSuperMentor ? (
              <div className="space-y-1">
                {MY_COMMUNITY_NAV.map((item) => {
                  const active =
                    pathname === item.href ||
                    (item.href !== ROUTES.myCommunity && pathname.startsWith(`${item.href}/`));
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      onClick={() => setMobileOpen(false)}
                      aria-current={active ? "page" : undefined}
                      className={`block rounded-lg px-3 py-2 text-sm font-semibold transition ${
                        active
                          ? "bg-white text-slate-950 shadow-sm"
                          : "text-slate-900 hover:bg-black/10"
                      }`}
                    >
                      {item.label}
                    </Link>
                  );
                })}
              </div>
            ) : (
              navGroups.map((group) => (
                <div key={group.group} className="space-y-1">
                  <p className="px-3 text-[11px] font-bold uppercase tracking-wider text-black/60">
                    {group.group}
                  </p>
                  <div className="space-y-0.5">
                    {group.items.map((item) => {
                      const active =
                        pathname === item.href ||
                        (item.href !== ROUTES.dashboard &&
                          item.href !== ROUTES.home &&
                          pathname.startsWith(`${item.href}`));
                      return (
                        <Link
                          key={item.href}
                          href={item.href}
                          onClick={() => setMobileOpen(false)}
                          aria-current={active ? "page" : undefined}
                          className={`block rounded-lg px-3 py-1.5 text-xs font-semibold transition ${
                            active
                              ? "bg-white text-slate-950 shadow-sm"
                              : "text-slate-900 hover:bg-black/10"
                          }`}
                        >
                          {item.label}
                        </Link>
                      );
                    })}
                  </div>
                </div>
              ))
            )}
          </nav>
        </div>

        <div className="mt-6 pt-4 border-t border-black/10">
          <UserCard />
        </div>
      </aside>
    </>
  );
}
