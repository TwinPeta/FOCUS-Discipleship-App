/**
 * src/components/feedback/ForbiddenState.tsx
 *
 * WHAT: In-page no-access / forbidden state
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ShieldX } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";

interface ForbiddenStateProps {
  title?: string;
  message?: string;
  backHref?: string;
}

export function ForbiddenState({
  title = "Access Restricted",
  message = "Your current role does not have permission to view or manage this section.",
  backHref = ROUTES.home,
}: ForbiddenStateProps) {
  return (
    <div
      role="alert"
      className="flex flex-col items-center justify-center rounded-xl border border-border bg-white p-8 text-center sm:p-12"
    >
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary-soft text-amber-700 mb-3">
        <ShieldX className="h-6 w-6" aria-hidden="true" />
      </div>
      <h2 className="text-base font-bold text-foreground">{title}</h2>
      <p className="mt-1 text-xs text-muted max-w-sm">{message}</p>
      <div className="mt-4">
        <Link
          href={backHref}
          className="rounded-md bg-primary px-4 py-2 text-xs font-semibold text-white hover:opacity-90"
        >
          Return to permitted view
        </Link>
      </div>
    </div>
  );
}
