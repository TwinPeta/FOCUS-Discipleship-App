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
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-left">
        <thead>
          <tr>
            <th>When</th>
            <th>Who</th>
            <th>Action</th>
            <th>Target</th>
            <th>Place</th>
          </tr>
        </thead>
        <tbody>
          {entries.length === 0 ? (
            <tr>
              <td colSpan={5} className="text-center text-muted-foreground">
                No audit entries match your current filters.
              </td>
            </tr>
          ) : (
            entries.map((entry) => (
              <tr key={entry.id}>
                <td className="whitespace-nowrap text-sm">{new Date(entry.occurredAt).toLocaleString()}</td>
                <td>
                  <p className="font-extrabold">{entry.actorName}</p>
                  <p className="text-[13px] opacity-80">{ROLE_LABELS[entry.actorRole]}</p>
                </td>
                <td className="font-extrabold">{entry.actionLabel}</td>
                <td>{entry.target}</td>
                <td>
                  <span className="chip">{entry.place}</span>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
