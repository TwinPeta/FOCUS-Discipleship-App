/**
 * src/features/moderation/components/EscalationInfo.tsx
 *
 * WHAT: Explains Level 1 vs Level 2 moderation and super-mentor report escalation
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import { Shield } from "lucide-react";

interface EscalationInfoProps {
  isSuperMentorTarget?: boolean;
}

export function EscalationInfo({
  isSuperMentorTarget = false,
}: EscalationInfoProps) {
  return (
    <div className="flex items-start gap-2 rounded-md border border-border bg-primary-soft px-3 py-2 text-xs text-foreground">
      <Shield className="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden="true" />
      <p>
        {isSuperMentorTarget
          ? "Reports involving a super-mentor must be reviewed by a system administrator."
          : "Level 1 reviewers can hide content, warn, or escalate. Level 2 administrators can suspend or permanently delete."}
      </p>
    </div>
  );
}
