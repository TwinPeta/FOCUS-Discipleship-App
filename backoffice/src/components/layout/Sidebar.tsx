/**
 * src/components/layout/Sidebar.tsx
 *
 * WHAT: Yellow navigation sidebar. Desktop: icon rail (68px, collapsed by default) that expands to 240px,
 *       with tooltips when collapsed. Mobile: slide-in drawer. Role-filtered groups, user card in the footer.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { Fragment, useEffect, useState, type FocusEvent, type MouseEvent } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { PanelLeftClose, PanelLeftOpen, X } from "lucide-react";
import { UserCard } from "./UserCard";
import { getNavGroupsForRole, isNavActive } from "./nav-config";
import { useShell } from "./ShellContext";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROUTES } from "@/lib/constants/routes";
import { Role } from "@/types/enums";

interface Tooltip {
  label: string;
  top: number;
}

export function Sidebar() {
  const pathname = usePathname();
  const { user } = useSession();
  const { sidebarExpanded, toggleSidebar, mobileNavOpen, setMobileNavOpen } = useShell();
  const [tooltip, setTooltip] = useState<Tooltip | null>(null);

  const isSuperMentor = user?.role === Role.SuperMentor;
  const navGroups = getNavGroupsForRole(user?.role);
  const collapsed = !sidebarExpanded;

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

  useEffect(() => {
    if (!collapsed) setTooltip(null);
  }, [collapsed]);

  function showTooltip(event: MouseEvent<HTMLElement> | FocusEvent<HTMLElement>, label: string) {
    if (!collapsed) return;
    const rect = event.currentTarget.getBoundingClientRect();
    setTooltip({ label, top: rect.top + rect.height / 2 });
  }
  const hideTooltip = () => setTooltip(null);

  return (
    <>
      {/* Mobile backdrop */}
      {mobileNavOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-[2px] md:hidden"
          onClick={() => setMobileNavOpen(false)}
          aria-hidden="true"
        />
      )}

      <aside
        id="app-sidebar"
        aria-label="Sidebar"
        data-collapsed={collapsed}
        className={`fixed inset-y-0 left-0 z-50 flex w-72 flex-col bg-primary text-foreground shadow-xl transition-[transform,width] duration-200 ease-out
          ${mobileNavOpen ? "translate-x-0" : "-translate-x-full"}
          md:relative md:z-20 md:h-dvh md:shrink-0 md:translate-x-0 md:shadow-none md:border-r md:border-black/10
          ${collapsed ? "md:w-sidebar-collapsed" : "md:w-sidebar"}`}
      >
        {/* Brand + collapse toggle */}
        <div
          className={`flex shrink-0 items-center gap-2 px-3 pt-3 pb-2 ${
            collapsed ? "md:flex-col md:px-2" : "justify-between"
          }`}
        >
          <Link
            href={isSuperMentor ? ROUTES.myCommunity : ROUTES.dashboard}
            className="flex min-w-0 items-center gap-2.5 rounded-lg focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground"
          >
            <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-slate-900 text-[11px] font-black tracking-wider text-primary">
              FCU
            </span>
            <span className={`min-w-0 leading-tight ${collapsed ? "md:sr-only" : ""}`}>
              <span className="block text-[10px] font-bold uppercase tracking-wider text-black/70">
                FCU Backoffice
              </span>
              <span className="block truncate text-sm font-black">
                {isSuperMentor ? "My Community" : "Staff Portal"}
              </span>
            </span>
          </Link>

          <button
            type="button"
            onClick={toggleSidebar}
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
            aria-expanded={!collapsed}
            aria-controls="app-sidebar"
            onMouseEnter={(e) => showTooltip(e, "Expand sidebar")}
            onMouseLeave={hideTooltip}
            onFocus={(e) => showTooltip(e, "Expand sidebar")}
            onBlur={hideTooltip}
            className="hidden h-8 w-8 shrink-0 place-items-center rounded-lg text-foreground/80 transition hover:bg-black/10 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground md:grid"
          >
            {collapsed ? (
              <PanelLeftOpen className="h-[18px] w-[18px]" aria-hidden="true" />
            ) : (
              <PanelLeftClose className="h-[18px] w-[18px]" aria-hidden="true" />
            )}
          </button>

          <button
            type="button"
            onClick={() => setMobileNavOpen(false)}
            aria-label="Close navigation menu"
            className="grid h-8 w-8 place-items-center rounded-lg hover:bg-black/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground md:hidden"
          >
            <X className="h-5 w-5" aria-hidden="true" />
          </button>
        </div>

        {/* Navigation */}
        <nav
          aria-label="Main navigation"
          onScroll={hideTooltip}
          className={`flex-1 overflow-y-auto overflow-x-hidden px-2 py-1 [scrollbar-width:thin] ${
            collapsed ? "md:px-2.5" : ""
          }`}
        >
          {navGroups.map((group, groupIndex) => (
            <Fragment key={group.group}>
              {/* Collapsed rail: hairline between groups instead of headings */}
              {groupIndex > 0 && collapsed && (
                <div className="mx-1.5 my-1 hidden border-t border-black/15 md:block" aria-hidden="true" />
              )}
              <div
                role="group"
                aria-label={group.group}
                className={groupIndex > 0 ? (collapsed ? "mt-3 md:mt-0" : "mt-3 md:mt-2") : ""}
              >
                {!isSuperMentor && (
                  <p
                    className={`px-2.5 pb-1 text-[10px] md:pb-0.5 font-bold uppercase tracking-wider text-black/60 ${
                      collapsed ? "md:hidden" : ""
                    }`}
                  >
                    {group.group}
                  </p>
                )}
                <ul className="space-y-0.5 md:space-y-px">
                  {group.items.map((item) => {
                    const active = isNavActive(pathname, item.href);
                    const Icon = item.icon;
                    return (
                      <li key={item.href}>
                        <Link
                          href={item.href}
                          aria-current={active ? "page" : undefined}
                          onMouseEnter={(e) => showTooltip(e, item.label)}
                          onMouseLeave={hideTooltip}
                          onFocus={(e) => showTooltip(e, item.label)}
                          onBlur={hideTooltip}
                          className={`flex h-10 items-center gap-3 rounded-lg px-2.5 text-sm font-semibold transition md:h-[clamp(26px,3.9dvh,36px)] md:text-[13px]
                            focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground
                            ${collapsed ? "md:justify-center md:px-0" : ""}
                            ${active ? "bg-white text-slate-950 shadow-sm" : "text-slate-900 hover:bg-black/10"}`}
                        >
                          <Icon
                            className={`h-[18px] w-[18px] shrink-0 ${active ? "text-slate-950" : "text-slate-900/80"}`}
                            aria-hidden="true"
                          />
                          <span className={`truncate ${collapsed ? "md:sr-only" : ""}`}>{item.label}</span>
                        </Link>
                      </li>
                    );
                  })}
                </ul>
              </div>
            </Fragment>
          ))}
        </nav>

        {/* Footer */}
        <div className={`shrink-0 border-t border-black/10 p-2 ${collapsed ? "md:px-2.5" : ""}`}>
          <div className="md:hidden">
            <UserCard />
          </div>
          <div className="hidden md:block">
            <UserCard collapsed={collapsed} />
          </div>
        </div>
      </aside>

      {/* Floating tooltip for the collapsed rail (fixed so the scrollable nav can't clip it) */}
      {tooltip && collapsed && (
        <div
          role="tooltip"
          className="pointer-events-none fixed z-[60] hidden -translate-y-1/2 animate-fade-in whitespace-nowrap rounded-md bg-slate-900 px-2.5 py-1.5 text-xs font-semibold text-white shadow-lg md:block"
          style={{ top: tooltip.top, left: "calc(var(--sidebar-collapsed-width) + 8px)" }}
        >
          {tooltip.label}
        </div>
      )}
    </>
  );
}
