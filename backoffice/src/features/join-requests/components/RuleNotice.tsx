/**
 * src/features/join-requests/components/RuleNotice.tsx
 *
 * WHAT: One-specific-community-per-student rule notice banner
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

import { Info } from "lucide-react";

export function RuleNotice() {
  return (
    <div className="notice">
      <Info className="h-[22px] w-[22px] shrink-0" aria-hidden="true" />
      <p>
        Each student can belong to <strong>one specific caregroup</strong> at a time.
        Requests from students already in another caregroup are flagged and skipped
        during bulk approval.
      </p>
    </div>
  );
}
