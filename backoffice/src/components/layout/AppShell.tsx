/**
 * src/components/layout/AppShell.tsx
 *
 * WHAT: Viewport-locked shell: ambient background, collapsible sidebar, sticky top bar (breadcrumbs, search, profile),
 *       scrollable main content, command palette (Ctrl/Cmd+K) and profile drawer. Includes a skip-link.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import type { ReactNode } from "react";
import { CommandPalette } from "./CommandPalette";
import { InteractiveBackground } from "./InteractiveBackground";
import { ProfileDetailsDialog } from "./ProfileDetailsDialog";
import { ShellProvider } from "./ShellContext";
import { Sidebar } from "./Sidebar";
import { TopBar } from "./TopBar";

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <ShellProvider>
      <div className="relative flex h-dvh overflow-hidden text-foreground">
        {/* Skip to content link for screen readers & keyboard navigation */}
        <a
          href="#main-content"
          className="sr-only focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-[70] focus:rounded-md focus:bg-slate-900 focus:px-4 focus:py-2 focus:text-xs focus:font-bold focus:text-white focus:shadow-lg focus:outline-none focus:ring-2 focus:ring-primary"
        >
          Skip to main content
        </a>

        <InteractiveBackground />
        <Sidebar />

        {/* No z-index here: page-level overlays (z-50) must be able to stack above the sidebar. */}
        <div className="relative flex h-dvh min-w-0 flex-1 flex-col overflow-y-auto [scrollbar-gutter:stable]">
          <TopBar />
          <main
            id="main-content"
            tabIndex={-1}
            className="mx-auto w-full max-w-7xl flex-1 animate-fade-in p-4 focus:outline-none sm:p-6 lg:p-8"
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
