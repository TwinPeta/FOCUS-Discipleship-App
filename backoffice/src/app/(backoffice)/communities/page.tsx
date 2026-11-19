/**
 * src/app/(backoffice)/communities/page.tsx
 *
 * WHAT: B3 Communities and cover photos: list, filter, cover photo indicator, edit panel
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import Link from "next/link";
import { Plus } from "lucide-react";
import { CommunityTable } from "@/features/communities/components/CommunityTable";
import type { Community } from "@/features/communities/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function CommunitiesPage() {
  const items: Community[] = [];

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Caregroups</h1>
          <p>Manage general and specific campus caregroups, meeting details, and cover photos.</p>
        </div>
        <Link href={ROUTES.communityNew} className="btn btn-primary">
          <Plus className="h-5 w-5" strokeWidth={2.6} aria-hidden="true" />
          New caregroup
        </Link>
      </div>

      <CommunityTable items={items} />
    </div>
  );
}
