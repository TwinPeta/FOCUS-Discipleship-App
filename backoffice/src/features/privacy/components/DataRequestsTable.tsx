/**
 * src/features/privacy/components/DataRequestsTable.tsx
 *
 * WHAT: Data export and deletion requests table with 30-day deadline badges and process dialog
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import {
  processDataRequest,
  type DataRequestRecord,
} from "@/features/privacy/queries";
import { RequestStatus } from "@/types/enums";
import { DeadlineBadge } from "./DeadlineBadge";
import { ProcessRequestDialog } from "./ProcessRequestDialog";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { StatusPill } from "@/components/data-table/StatusPill";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchDataRequests } from "@/features/privacy/queries";

interface DataRequestsTableProps {
  initialItems: DataRequestRecord[];
}

export function DataRequestsTable({ initialItems }: DataRequestsTableProps) {
  const [items, setItems] = useRemoteItems<DataRequestRecord>(initialItems, fetchDataRequests);
  const [target, setTarget] = useState<DataRequestRecord | null>(null);

  async function handleProcess(id: string) {
    await processDataRequest(id);
    setItems((prev) =>
      prev.map((i) => (i.id === id ? { ...i, status: RequestStatus.Done } : i)),
    );
  }

  return (
    <>
      <div className="overflow-x-auto rounded-card border border-border bg-white">
        <h2 className="eyebrow mb-1">Data requests</h2>
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
            <tr>
              <th className="px-4 py-3">Member</th>
              <th className="px-4 py-3">Type</th>
              <th className="px-4 py-3">Requested</th>
              <th className="px-4 py-3">Deadline</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {items.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">
                  No data export or deletion requests.
                </td>
              </tr>
            ) : (
              items.map((item) => (
                <tr key={item.id} className="hover:bg-surface/60">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2.5">
                      <InitialsAvatar name={item.memberName} />
                      <div>
                        <p className="text-base font-extrabold">{item.memberName}</p>
                        <p className="text-[13px] opacity-80">{item.memberEmail}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">{item.type}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.requestedAt}</td>
                  <td className="px-4 py-3">
                    <DeadlineBadge deadlineAt={item.deadlineAt} status={item.status} />
                  </td>
                  <td className="px-4 py-3"><StatusPill status={String(item.status).toLowerCase().replace("_", " ")} variant={item.status === RequestStatus.Done ? "active" : "pending"} /></td>
                  <td className="px-4 py-3 text-right">
                    {item.status !== RequestStatus.Done && (
                      <button
                        type="button"
                        onClick={() => setTarget(item)}
                        className="rounded-md bg-primary px-2.5 py-1 text-xs font-semibold text-foreground hover:brightness-95"
                      >
                        Process
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <ProcessRequestDialog
        request={target}
        onConfirm={handleProcess}
        onClose={() => setTarget(null)}
      />
    </>
  );
}
