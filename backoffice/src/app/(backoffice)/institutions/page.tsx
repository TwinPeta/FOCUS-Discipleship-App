/**
 * src/app/(backoffice)/institutions/page.tsx
 *
 * WHAT: B15 Institutions: list, search and edit panel; creating an institution creates its general community
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import Link from "next/link";
import { InstitutionTable } from "@/features/institutions/components/InstitutionTable";
import type { Institution } from "@/features/institutions/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function InstitutionsPage() {
  // Initial data will be hydrated from API/MSW; empty array fallback keeps SSR safe before backend is live
  const initialItems: Institution[] = [];

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Institutions</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Manage universities and high schools. A general community is created
            automatically per institution.
          </p>
        </div>

        <Link
          href={ROUTES.institutionNew}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95"
        >
          New institution
        </Link>
      </div>

      <InstitutionTable initialItems={initialItems} />
    </div>
  );
}
