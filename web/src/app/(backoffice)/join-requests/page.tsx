/**
 * src/app/(backoffice)/join-requests/page.tsx
 *
 * WHAT: B2 Join requests: pending/approved/declined tabs, single approve/decline, bulk approve, conflict badge
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

import { JoinRequestTable } from "@/features/join-requests/components/JoinRequestTable";
import { RuleNotice } from "@/features/join-requests/components/RuleNotice";
import type { JoinRequestItem } from "@/features/join-requests/conflicts";

export default function JoinRequestsPage() {
  const initialItems: JoinRequestItem[] = [];

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Join requests</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Review student requests to join specific campus communities.
        </p>
      </div>

      <RuleNotice />
      <JoinRequestTable initialItems={initialItems} />
    </div>
  );
}
