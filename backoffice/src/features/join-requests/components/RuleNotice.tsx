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
    <div className="flex items-start gap-2.5 rounded-md border border-border bg-primary-soft px-4 py-3 text-sm text-foreground">
      <Info className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
      <p>
        Each student can belong to <strong>one specific community</strong> at a time.
        Requests from students already in another community are flagged and skipped
        during bulk approval.
      </p>
    </div>
  );
}
