/**
 * src/app/(backoffice)/members/page.tsx
 *
 * WHAT: B4 Members: role tabs with counts, search, filters, detail side panel
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import Link from "next/link";
import { MemberTable } from "@/features/members/components/MemberTable";
import type { Member } from "@/features/members/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function MembersPage() {
  const initialItems: Member[] = [];

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Members</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Search, filter, and manage student, mentor, and alumni accounts.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href={ROUTES.memberImport}
            className="rounded-md border border-border bg-white px-4 py-2 text-sm font-medium text-foreground hover:bg-surface"
          >
            Import CSV
          </Link>
          <Link
            href={ROUTES.memberNew}
            className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95"
          >
            Add user
          </Link>
        </div>
      </div>

      <MemberTable initialItems={initialItems} />
    </div>
  );
}
