/**
 * src/components/layout/PageHeader.tsx
 *
 * WHAT: Standard page header with accessible h1 title, description, and action buttons slot
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";

interface PageHeaderProps {
  title: string;
  description?: string;
  backHref?: string;
  backLabel?: string;
  children?: ReactNode;
}

export function PageHeader({
  title,
  description,
  backHref,
  backLabel = "Back",
  children,
}: PageHeaderProps) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div className="min-w-0">
        <h1 className="text-[34px] leading-[1.05]">{title}</h1>
        {description && (
          <p className="mt-1.5 max-w-2xl text-[15px] text-muted-foreground">{description}</p>
        )}
      </div>

      {(backHref || children) && (
        <div className="flex shrink-0 flex-wrap items-center gap-2.5">
          {children}
          {backHref && (
            <Link href={backHref} className="btn btn-secondary">
              <ArrowLeft className="h-4 w-4" aria-hidden="true" />
              <span>{backLabel}</span>
            </Link>
          )}
        </div>
      )}
    </div>
  );
}
