/**
 * src/app/(backoffice)/institutions/churches/page.tsx
 *
 * WHAT: Local churches (B15b): churches students belong to, with how many students and mentors each has
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ChurchList } from "@/features/churches/ChurchList";
import { ROUTES } from "@/lib/constants/routes";

export default function ChurchesPage() {
  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Local churches</h1>
          <p>Churches that students belong to, with the number of students and mentors in each.</p>
        </div>
        <Link href={ROUTES.institutions} className="btn btn-secondary">
          Campuses
        </Link>
      </div>

      <ChurchList />
    </div>
  );
}
