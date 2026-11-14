/**
 * src/components/layout/Breadcrumbs.tsx
 *
 * WHAT: Quick-back button + breadcrumb trail ("Dashboard / Communities / New community") for the top bar
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ArrowLeft, ChevronRight } from "lucide-react";
import { useSession } from "@/features/auth/hooks/useSession";
import { getHomeRouteForRole, ROUTES } from "@/lib/constants/routes";
import { buildBreadcrumbs, getParentHref } from "./breadcrumb-trail";

export function Breadcrumbs() {
  const pathname = usePathname();
  const { user } = useSession();
  const homeHref = user ? getHomeRouteForRole(user.role) : ROUTES.dashboard;
  const crumbs = buildBreadcrumbs(pathname, homeHref);
  const parentHref = getParentHref(crumbs);
  const parentLabel = crumbs.find((c) => c.href === parentHref)?.label;

  return (
    <div className="flex min-w-0 items-center gap-2">
      {parentHref && (
        <Link
          href={parentHref}
          aria-label={`Back to ${parentLabel}`}
          title={`Back to ${parentLabel}`}
          className="grid h-8 w-8 shrink-0 place-items-center rounded-lg border border-border/70 bg-surface text-foreground/80 shadow-sm transition hover:border-primary hover:bg-primary-soft hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
        >
          <ArrowLeft className="h-4 w-4" aria-hidden="true" />
        </Link>
      )}

      <nav aria-label="Breadcrumb" className="min-w-0">
        <ol className="flex min-w-0 items-center gap-1 text-sm">
          {crumbs.map((crumb, index) => {
            const isLast = index === crumbs.length - 1;
            return (
              <li
                key={`${crumb.label}-${index}`}
                // On small screens show only the current page to save space.
                className={`flex min-w-0 items-center gap-1 ${isLast ? "" : "hidden sm:flex"}`}
              >
                {index > 0 && (
                  <ChevronRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground/60" aria-hidden="true" />
                )}
                {crumb.href && !isLast ? (
                  <Link
                    href={crumb.href}
                    className="truncate rounded px-1 font-medium text-muted-foreground transition hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                  >
                    {crumb.label}
                  </Link>
                ) : (
                  <span
                    aria-current={isLast ? "page" : undefined}
                    className={`truncate px-1 ${isLast ? "font-semibold text-foreground" : "text-muted-foreground"}`}
                  >
                    {crumb.label}
                  </span>
                )}
              </li>
            );
          })}
        </ol>
      </nav>
    </div>
  );
}
