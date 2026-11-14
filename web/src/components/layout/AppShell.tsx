/**
 * src/components/layout/AppShell.tsx
 *
 * WHAT: Desktop-first shell with yellow sidebar and scrollable main content area
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { Sidebar } from "./Sidebar";

export function AppShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-background text-foreground">
      <Sidebar />
      <main className="flex-1 min-w-0">{children}</main>
    </div>
  );
}
