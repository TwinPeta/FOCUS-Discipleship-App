/**
 * src/app/(backoffice)/members/page.tsx
 *
 * WHAT: B4 Members: role tabs with counts, search, filters, detail side panel
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import Link from "next/link";
import { Plus } from "lucide-react";
import { MemberTable } from "@/features/members/components/MemberTable";
import type { Member } from "@/features/members/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function MembersPage() {
  const initialItems: Member[] = [];

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-[34px] leading-[1.05]">Members</h1>
        <div className="flex flex-wrap items-center gap-2.5">
          <Link href={ROUTES.memberImport} className="btn btn-secondary">
            Import CSV
          </Link>
          <Link href={ROUTES.memberNew} className="btn btn-primary">
            <Plus className="h-5 w-5" strokeWidth={2.6} aria-hidden="true" />
            Add user
          </Link>
        </div>
      </div>

      <MemberTable initialItems={initialItems} />
    </div>
  );
}
