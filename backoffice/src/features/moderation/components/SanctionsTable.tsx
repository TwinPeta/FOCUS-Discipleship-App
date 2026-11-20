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
import { Search } from "lucide-react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { StatusPill } from "@/components/data-table/StatusPill";
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
  const [search, setSearch] = useState("");
  const shown = items.filter((i) => i.userName.toLowerCase().includes(search.trim().toLowerCase()));

  async function handleReinstate(reason: string) {
    if (!target) return;
    await reinstateSanction(target.id, reason);
    setItems((prev) =>
      prev.map((i) => (i.id === target.id ? { ...i, active: false } : i)),
    );
  }

  return (
    <>
      <section className="card flex flex-col gap-2">
        <div className="mb-1.5 flex flex-wrap items-center gap-2.5">
          <div className="relative min-w-[220px] flex-1">
            <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search a user"
              aria-label="Search sanctions"
              className="field-soft w-full pl-10 pr-3"
            />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr>
                <th>User</th>
                <th>Sanction</th>
                <th>Reason</th>
                <th>Date</th>
                <th>By</th>
                <th className="text-right">
                  <span className="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody>
              {shown.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center text-muted-foreground">
                    No sanctions recorded.
                  </td>
                </tr>
              ) : (
                shown.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <div className="flex items-center gap-2.5">
                        <InitialsAvatar name={item.userName} />
                        <p className="text-base font-extrabold">{item.userName}</p>
                      </div>
                    </td>
                    <td>
                      <StatusPill status={item.active ? String(item.type).toLowerCase() : "reinstated"} variant={item.active ? "suspended" : "inactive"} />
                    </td>
                    <td>{item.reason}</td>
                    <td className="whitespace-nowrap text-sm">{item.issuedAt}</td>
                    <td>{item.issuedBy}</td>
                    <td className="text-right">
                      {item.active && (
                        <button type="button" onClick={() => setTarget(item)} className="rounded-md border border-border px-2.5 py-1 text-xs font-medium">
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
      </section>

      <div className="notice mt-4">
        <span>
          <b>Escalation levels.</b> Level 1: super-mentors and mentors hide a message or warn a member. Level 2: admins
          suspend an account or delete permanently. Every sanction keeps its reason, author and date.
        </span>
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
