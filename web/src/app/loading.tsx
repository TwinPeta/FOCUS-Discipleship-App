/**
 * src/app/loading.tsx
 *
 * WHAT: Default accessible loading skeleton with brand spinner
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { Loader2 } from "lucide-react";

export default function Loading() {
  return (
    <div
      role="status"
      aria-live="polite"
      className="flex min-h-[50vh] flex-col items-center justify-center p-8 text-center"
    >
      <Loader2 className="h-8 w-8 animate-spin text-primary mb-3" aria-hidden="true" />
      <p className="text-xs font-semibold uppercase tracking-wider text-muted">
        Loading discipleship portal…
      </p>
    </div>
  );
}
