/**
 * src/app/(backoffice)/members/[id]/page.tsx
 *
 * WHAT: Member detail page with AuditNotice and account actions
 * REQUIREMENTS: FR-07, FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { use, useEffect, useState } from "react";
import { MemberDetailPanel } from "@/features/members/components/MemberDetailPanel";
import { fetchMember } from "@/features/members/queries";
import type { Member } from "@/features/members/schemas";

export default function MemberDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const [member, setMember] = useState<Member | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchMember(id)
      .then(setMember)
      .catch(() => setError("Could not load member details."))
      .finally(() => setLoading(false));
  }, [id]);

  return (
    <div className="mx-auto max-w-2xl space-y-6 p-6">
      <h1 className="text-2xl font-bold text-foreground">Member details</h1>
      {loading && <p className="text-sm text-muted-foreground">Loading member...</p>}
      {error && (
        <p role="alert" className="text-sm text-red-700">
          {error}
        </p>
      )}
      {member && <MemberDetailPanel member={member} onUpdated={setMember} />}
    </div>
  );
}
