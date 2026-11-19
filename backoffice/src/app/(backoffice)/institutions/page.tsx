/**
 * src/app/(backoffice)/institutions/page.tsx
 *
 * WHAT: B15 Institutions: list, search and edit panel; creating an institution creates its general community
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import Link from "next/link";
import { Plus } from "lucide-react";
import { InstitutionTable } from "@/features/institutions/components/InstitutionTable";
import type { Institution } from "@/features/institutions/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function InstitutionsPage() {
  // Initial data will be hydrated from API/MSW; empty array fallback keeps SSR safe before backend is live
  const initialItems: Institution[] = [];

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Campuses</h1>
          <p>Manage universities and high schools. A general caregroup is created automatically per campus.</p>
        </div>
        <div className="flex flex-wrap items-center gap-2.5">
          <Link href={ROUTES.churches} className="btn btn-secondary">
            Local churches
          </Link>
          <Link href={ROUTES.institutionNew} className="btn btn-primary">
            <Plus className="h-5 w-5" strokeWidth={2.6} aria-hidden="true" />
            Add campus
          </Link>
        </div>
      </div>

      <InstitutionTable initialItems={initialItems} />
    </div>
  );
}
