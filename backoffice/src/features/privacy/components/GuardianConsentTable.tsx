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
import {
  sendGuardianReminder,
  type GuardianConsentRecord,
} from "@/features/privacy/queries";
import { GuardianConsentStatus } from "@/types/enums";

interface GuardianConsentTableProps {
  initialItems: GuardianConsentRecord[];
}

export function GuardianConsentTable({ initialItems }: GuardianConsentTableProps) {
  const [remindedId, setRemindedId] = useState<string | null>(null);
  const [sendingId, setSendingId] = useState<string | null>(null);

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
          className="rounded-md border border-emerald-300 bg-emerald-50 px-4 py-2 text-sm text-emerald-900"
        >
          Reminder sent to guardian.
        </div>
      )}

      <div className="overflow-x-auto rounded-card border border-border bg-white">
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
                  <td className="px-4 py-3 font-medium text-foreground">
                    {item.studentName}
                  </td>
                  <td className="px-4 py-3 text-foreground">{item.guardianName}</td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {item.guardianContact}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        item.status === GuardianConsentStatus.Received
                          ? "bg-emerald-100 text-emerald-800"
                          : "bg-amber-100 text-amber-900"
                      }`}
                    >
                      {item.status === GuardianConsentStatus.Received
                        ? "Received"
                        : "Pending"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">{item.updatedAt}</td>
                  <td className="px-4 py-3 text-right">
                    {item.status === GuardianConsentStatus.Pending && (
                      <button
                        type="button"
                        disabled={sendingId === item.id}
                        onClick={() => handleRemind(item.id)}
                        className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface disabled:opacity-60"
                      >
                        {sendingId === item.id ? "Sending..." : "Send reminder"}
                      </button>
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
