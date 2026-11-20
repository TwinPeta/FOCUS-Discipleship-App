/**
 * src/components/layout/AppShell.tsx
 *
 * WHAT: Page shell: fixed 240px sidebar, mobile header, page content on the warm wash, command palette (Ctrl/Cmd+K) and profile drawer. Includes a skip-link.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import type { ReactNode } from "react";
import { CommandPalette } from "./CommandPalette";
import { ProfileDetailsDialog } from "./ProfileDetailsDialog";
import { ShellProvider } from "./ShellContext";
import { Sidebar } from "./Sidebar";
import { TopBar } from "./TopBar";

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <ShellProvider>
      <div className="relative flex min-h-dvh text-foreground">
        {/* Skip to content link for screen readers & keyboard navigation */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-[70] focus:rounded-md focus:bg-ink focus:px-4 focus:py-2 focus:text-xs focus:font-bold focus:text-white focus:shadow-lg focus:outline-none focus:ring-2 focus:ring-primary"
        >
          Skip to main content
        </a>

        <Sidebar />

        {/* No z-index here: page-level overlays (z-50) must be able to stack above the sidebar. */}
        <div className="relative flex min-w-0 flex-1 flex-col">
          <TopBar />
          <main
            id="main-content"
            tabIndex={-1}
            className="flex w-full flex-1 animate-fade-in flex-col gap-5 p-4 focus:outline-none sm:px-[30px] sm:py-[26px]"
          >
            {children}
          </main>
        </div>

        <CommandPalette />
        <ProfileDetailsDialog />
      </div>
    </ShellProvider>
  );
}
