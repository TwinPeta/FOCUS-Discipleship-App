/**
 * src/app/not-found.tsx
 *
 * WHAT: Accessible 404 Not Found error page with brand styling
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import Link from "next/link";
import { Compass } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";

export default function NotFound() {
  return (
    <main
      role="main"
      className="flex min-h-screen flex-col items-center justify-center p-6 text-center bg-background text-foreground"
    >
      <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary-soft text-primary mb-4">
        <Compass className="h-8 w-8" aria-hidden="true" />
      </div>
      <h1 className="text-[34px] leading-[1.05]">404 — Page Not Found</h1>
      <p className="mt-2 text-sm text-muted max-w-md">
        The backoffice page or resource you are looking for does not exist or may have been moved.
      </p>
      <div className="mt-6">
        <Link
          href={ROUTES.home}
          className="inline-flex items-center justify-center rounded-md bg-primary px-5 py-2.5 text-sm font-semibold text-white hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 transition"
        >
          Return to Backoffice
        </Link>
      </div>
    </main>
  );
}
