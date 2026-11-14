/**
 * src/app/forbidden/page.tsx
 *
 * WHAT: 403 Forbidden page: informative notice when role lacks permission
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ShieldAlert } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";

export default function ForbiddenPage() {
  return (
    <main
      role="main"
      className="flex min-h-screen flex-col items-center justify-center p-6 text-center bg-background text-foreground"
    >
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-amber-50 text-amber-600 mb-4">
        <ShieldAlert className="h-8 w-8" aria-hidden="true" />
      </div>
      <h1 className="text-3xl font-extrabold tracking-tight">403 — Access Restricted</h1>
      <p className="mt-2 text-sm text-muted max-w-md">
        Your staff account does not have sufficient permissions to access this backoffice area. Contact a System Administrator if you believe your account role needs updating.
      </p>
      <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
        <Link
          href={ROUTES.home}
          className="rounded-md bg-primary px-5 py-2.5 text-sm font-semibold text-white hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 transition"
        >
          Return to My Workspace
        </Link>
      </div>
    </main>
  );
}
