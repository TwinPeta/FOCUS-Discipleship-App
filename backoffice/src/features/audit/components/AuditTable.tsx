/**
 * src/features/audit/components/AuditTable.tsx
 *
 * WHAT: When, who, action, target, place
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { ROLE_LABELS } from "@/lib/permissions/roles";
import type { AuditEntry } from "../queries";

export function AuditTable({ entries }: { entries: AuditEntry[] }) {
  if (entries.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-white p-8 text-center text-sm text-muted">
        No audit entries match your current filters.
      </div>
    );
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-white">
      <table className="w-full border-collapse text-left text-sm">
        <thead>
          <tr className="border-b border-border bg-slate-50 text-xs font-semibold uppercase tracking-wide text-muted">
            <th className="px-4 py-3">When</th>
            <th className="px-4 py-3">Who</th>
            <th className="px-4 py-3">Action</th>
            <th className="px-4 py-3">Target</th>
            <th className="px-4 py-3">Place</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {entries.map((entry) => (
            <tr key={entry.id} className="hover:bg-slate-50/50">
              <td className="whitespace-nowrap px-4 py-3 text-xs text-muted">
                {new Date(entry.occurredAt).toLocaleString()}
              </td>
              <td className="px-4 py-3">
                <div className="font-medium text-foreground">{entry.actorName}</div>
                <div className="text-xs text-muted">{ROLE_LABELS[entry.actorRole]}</div>
              </td>
              <td className="px-4 py-3 font-medium text-foreground">
                {entry.actionLabel}
              </td>
              <td className="px-4 py-3 text-foreground">{entry.target}</td>
              <td className="px-4 py-3 text-xs text-muted">{entry.place}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
