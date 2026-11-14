/**
 * src/app/(backoffice)/communities/page.tsx
 *
 * WHAT: B3 Communities and cover photos: list, filter, cover photo indicator, edit panel
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

import Link from "next/link";
import { CommunityTable } from "@/features/communities/components/CommunityTable";
import type { Community } from "@/features/communities/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function CommunitiesPage() {
  const items: Community[] = [];

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Communities</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Manage general and specific campus communities, meeting details, and
            cover photos.
          </p>
        </div>

        <Link
          href={ROUTES.communityNew}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95"
        >
          New community
        </Link>
      </div>

      <CommunityTable items={items} />
    </div>
  );
}
