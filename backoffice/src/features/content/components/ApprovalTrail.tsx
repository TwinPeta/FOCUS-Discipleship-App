/**
 * src/features/content/components/ApprovalTrail.tsx
 *
 * WHAT: Chronological trail of content submissions, reviewer notes, and validation approvals
 * REQUIREMENTS: FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import type { ApprovalTrailEntry } from "@/features/content/schemas";

interface ApprovalTrailProps {
  entries: ApprovalTrailEntry[];
}

export function ApprovalTrail({ entries }: ApprovalTrailProps) {
  return (
    <div className="space-y-3 rounded-card border border-border bg-white p-5">
      <h2 className="text-base font-semibold text-foreground">Approval trail</h2>

      {entries.length === 0 ? (
        <p className="text-xs text-muted-foreground">No workflow events recorded yet.</p>
      ) : (
        <ol className="space-y-3">
          {entries.map((entry) => (
            <li
              key={entry.id}
              className="border-l-2 border-primary pl-3 text-sm"
            >
              <p className="font-medium text-foreground">
                {entry.action} ·{" "}
                <span className="font-normal text-muted-foreground">
                  {entry.actorName}
                </span>
              </p>
              {entry.notes && (
                <p className="mt-0.5 text-xs text-foreground">{entry.notes}</p>
              )}
              <p className="mt-0.5 text-xs text-muted-foreground">{entry.createdAt}</p>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
