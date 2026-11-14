/**
 * src/components/layout/TopBar.tsx
 *
 * WHAT: Sticky frosted header: mobile menu button, breadcrumbs + quick back, search (Ctrl/Cmd+K) and profile button
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { Menu, Search } from "lucide-react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Breadcrumbs } from "./Breadcrumbs";
import { useShell } from "./ShellContext";

function useIsMac() {
  const [isMac, setIsMac] = useState(false);
  useEffect(() => {
    setIsMac(/mac|iphone|ipad/i.test(navigator.userAgent));
  }, []);
  return isMac;
}

export function TopBar() {
  const { user } = useSession();
  const { setPaletteOpen, setProfileOpen, setMobileNavOpen, mobileNavOpen } = useShell();
  const isMac = useIsMac();

  return (
    <header className="sticky top-0 z-30 border-b border-border/60 bg-surface-glass/80 backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-7xl items-center gap-3 px-4 sm:px-6 lg:px-8">
        <button
          type="button"
          onClick={() => setMobileNavOpen(true)}
          aria-label="Open navigation menu"
          aria-expanded={mobileNavOpen}
          aria-controls="app-sidebar"
          className="grid h-9 w-9 shrink-0 place-items-center rounded-lg bg-primary text-foreground shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground md:hidden"
        >
          <Menu className="h-5 w-5" aria-hidden="true" />
        </button>

        <div className="min-w-0 flex-1">
          <Breadcrumbs />
        </div>

        <button
          type="button"
          onClick={() => setPaletteOpen(true)}
          aria-haspopup="dialog"
          aria-keyshortcuts={isMac ? "Meta+K" : "Control+K"}
          className="flex h-9 shrink-0 items-center gap-2 rounded-lg border border-border/80 bg-surface px-2.5 text-sm text-muted-foreground shadow-sm transition hover:border-primary hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary sm:w-56 lg:w-64"
        >
          <Search className="h-4 w-4 shrink-0" aria-hidden="true" />
          <span className="sr-only sm:not-sr-only sm:flex-1 sm:text-left">Search or jump to…</span>
          <kbd className="hidden rounded border border-border bg-background-subtle px-1.5 py-0.5 font-sans text-[11px] font-semibold text-muted-foreground sm:inline">
            {isMac ? "⌘K" : "Ctrl K"}
          </kbd>
        </button>

        {user && (
          <button
            type="button"
            onClick={() => setProfileOpen(true)}
            aria-haspopup="dialog"
            aria-label={`Open profile for ${user.fullName}`}
            className="flex shrink-0 items-center gap-2 rounded-full p-0.5 pr-0.5 transition hover:bg-black/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary lg:pr-3"
          >
            <InitialsAvatar name={user.fullName} avatarUrl={user.avatarUrl} size="md" />
            <span className="hidden text-left leading-tight lg:block">
              <span className="block max-w-[10rem] truncate text-xs font-bold text-foreground">{user.fullName}</span>
              <span className="block text-[11px] text-muted-foreground">{ROLE_LABELS[user.role] ?? user.role}</span>
            </span>
          </button>
        )}
      </div>
    </header>
  );
}
