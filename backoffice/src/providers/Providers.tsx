/**
 * src/providers/Providers.tsx
 *
 * WHAT: Composes client providers (React Query, Toast alerts)
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import type { ReactNode } from "react";
import { Toaster } from "sonner";
import { QueryProvider } from "./QueryProvider";
import { SessionExpiryWatcher } from "./SessionExpiryWatcher";

export function Providers({ children }: { children: ReactNode }) {
  return (
    <QueryProvider>
      <SessionExpiryWatcher />
      {children}
      <Toaster position="top-right" richColors closeButton />
    </QueryProvider>
  );
}
