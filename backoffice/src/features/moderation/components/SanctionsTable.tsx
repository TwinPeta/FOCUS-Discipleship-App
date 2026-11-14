/**
 * src/features/moderation/components/SanctionsTable.tsx
 *
 * WHAT: Sanctions table (warnings and suspensions) with reinstate action
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { reinstateSanction } from "@/features/moderation/queries";
import type { SanctionRecord } from "@/features/moderation/schemas";
import { ReinstateDialog } from "./ReinstateDialog";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchSanctions } from "@/features/moderation/queries";

interface SanctionsTableProps {
  initialItems: SanctionRecord[];
}

export function SanctionsTable({ initialItems }: SanctionsTableProps) {
  const [items, setItems] = useRemoteItems<SanctionRecord>(initialItems, fetchSanctions);
  const [target, setTarget] = useState<SanctionRecord | null>(null);

  async function handleReinstate(reason: string) {
    if (!target) return;
    await reinstateSanction(target.id, reason);
    setItems((prev) =>
      prev.map((i) => (i.id === target.id ? { ...i, active: false } : i)),
    );
  }

  return (
    <>
      <div className="overflow-x-auto rounded-card border border-border bg-white">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
            <tr>
              <th className="px-4 py-3">User</th>
              <th className="px-4 py-3">Sanction</th>
              <th className="px-4 py-3">Reason</th>
              <th className="px-4 py-3">Issued by</th>
              <th className="px-4 py-3">Date</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {items.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                  No sanctions recorded.
                </td>
              </tr>
            ) : (
              items.map((item) => (
                <tr key={item.id} className="hover:bg-surface/60">
                  <td className="px-4 py-3 font-medium text-foreground">
                    {item.userName}
                  </td>
                  <td className="px-4 py-3">{item.type}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.reason}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.issuedBy}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.issuedAt}</td>
                  <td className="px-4 py-3">
                    {item.active ? "Active" : "Reinstated"}
                  </td>
                  <td className="px-4 py-3 text-right">
                    {item.active && (
                      <button
                        type="button"
                        onClick={() => setTarget(item)}
                        className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                      >
                        Reinstate
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <ReinstateDialog
        open={Boolean(target)}
        userName={target?.userName ?? ""}
        onConfirm={handleReinstate}
        onClose={() => setTarget(null)}
      />
    </>
  );
}
