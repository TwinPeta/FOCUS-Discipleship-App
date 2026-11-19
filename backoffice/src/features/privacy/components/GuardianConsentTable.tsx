/**
 * src/features/privacy/components/GuardianConsentTable.tsx
 *
 * WHAT: Guardian consents table with status and Send reminder action
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { StatusPill } from "@/components/data-table/StatusPill";
import {
  confirmGuardianConsent,
  sendGuardianReminder,
  type GuardianConsentRecord,
} from "@/features/privacy/queries";
import { GuardianConsentStatus } from "@/types/enums";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchGuardianConsents } from "@/features/privacy/queries";

interface GuardianConsentTableProps {
  initialItems: GuardianConsentRecord[];
}

export function GuardianConsentTable({ initialItems: seedItems }: GuardianConsentTableProps) {
  const [loadedItems] = useRemoteItems<GuardianConsentRecord>(seedItems, fetchGuardianConsents);
  const [confirmed, setConfirmed] = useState<Record<string, GuardianConsentRecord>>({});
  const initialItems = loadedItems.map((item) => confirmed[item.id] ?? item);
  const [remindedId, setRemindedId] = useState<string | null>(null);
  const [sendingId, setSendingId] = useState<string | null>(null);
  const [confirmingId, setConfirmingId] = useState<string | null>(null);

  async function handleConfirm(id: string) {
    if (!window.confirm("Record that the guardian has given consent? The student's account will no longer be restricted.")) return;
    setConfirmingId(id);
    try {
      const updated = await confirmGuardianConsent(id);
      setConfirmed((prev) => ({ ...prev, [id]: updated }));
    } finally {
      setConfirmingId(null);
    }
  }

  async function handleRemind(id: string) {
    setSendingId(id);
    try {
      await sendGuardianReminder(id);
      setRemindedId(id);
    } finally {
      setSendingId(null);
    }
  }

  return (
    <div className="space-y-3">
      {remindedId && (
        <div
          role="status"
          className="rounded-md border border-blue/30 bg-blue-soft px-4 py-2 text-sm text-ink"
        >
          Reminder sent to guardian.
        </div>
      )}

      <div className="overflow-x-auto rounded-card border border-border bg-white">
        <h2 className="eyebrow mb-1">Users under 18: guardian consent</h2>
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
            <tr>
              <th className="px-4 py-3">Student</th>
              <th className="px-4 py-3">Guardian</th>
              <th className="px-4 py-3">Contact</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Date</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {initialItems.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">
                  No minor guardian consents recorded.
                </td>
              </tr>
            ) : (
              initialItems.map((item) => (
                <tr key={item.id} className="hover:bg-surface/60">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2.5">
                      <InitialsAvatar name={item.studentName} />
                      <span className="text-base font-extrabold">{item.studentName}</span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-foreground">
                    {item.guardianName}
                    {item.guardianRelationship && (
                      <span className="block text-xs text-muted-foreground">
                        {item.guardianRelationship}
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {item.guardianPhone || item.guardianEmail ? (
                      <>
                        {item.guardianPhone && <span className="block">{item.guardianPhone}</span>}
                        {item.guardianEmail && <span className="block">{item.guardianEmail}</span>}
                      </>
                    ) : (
                      item.guardianContact
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <StatusPill status={item.status === GuardianConsentStatus.Received ? "Received" : "Pending"} variant={item.status === GuardianConsentStatus.Received ? "active" : "pending"} />
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{item.updatedAt}</td>
                  <td className="px-4 py-3 text-right">
                    {item.status === GuardianConsentStatus.Pending && (
                      <div className="flex justify-end gap-2">
                        <button
                          type="button"
                          disabled={sendingId === item.id}
                          onClick={() => handleRemind(item.id)}
                          className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface disabled:opacity-60"
                        >
                          {sendingId === item.id ? "Sending..." : "Send reminder"}
                        </button>
                        <button
                          type="button"
                          disabled={confirmingId === item.id}
                          onClick={() => handleConfirm(item.id)}
                          className="rounded-md bg-primary px-2.5 py-1 text-xs font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
                        >
                          {confirmingId === item.id ? "Saving..." : "Mark confirmed"}
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
