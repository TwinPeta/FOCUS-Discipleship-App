/**
 * src/components/layout/TopBar.tsx
 *
 * WHAT: Mobile-only header: menu button, brand and search (Ctrl/Cmd+K still works everywhere). Hidden from md up,
 *       where the sidebar carries the brand and the user chip.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { Menu, Search } from "lucide-react";
import { useShell } from "./ShellContext";

export function TopBar() {
  const { setPaletteOpen, setMobileNavOpen, mobileNavOpen } = useShell();

  return (
    <header className="sticky top-0 z-30 flex h-14 items-center gap-3 bg-[#FFF1CC] px-4 md:hidden">
      <button
        type="button"
        onClick={() => setMobileNavOpen(true)}
        aria-label="Open navigation menu"
        aria-expanded={mobileNavOpen}
        aria-controls="app-sidebar"
        className="grid h-10 w-10 shrink-0 place-items-center rounded-xl border-2 border-ink bg-white"
      >
        <Menu className="h-5 w-5" aria-hidden="true" />
      </button>
      <span className="flex-1 text-base font-extrabold">FCU Backoffice</span>
      <button
        type="button"
        onClick={() => setPaletteOpen(true)}
        aria-haspopup="dialog"
        aria-label="Search or jump to"
        className="grid h-10 w-10 place-items-center rounded-xl border-2 border-ink bg-white"
      >
        <Search className="h-5 w-5" aria-hidden="true" />
      </button>
    </header>
  );
}
