/**
 * src/features/my-community/components/FollowUpList.tsx
 *
 * WHAT: Inactive members with Send reminder
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { MailCheck, Send } from "lucide-react";
import { sendFollowUpReminder, type FollowUpMember } from "../queries";

export function FollowUpList({ members }: { members: FollowUpMember[] }) {
  const [sent, setSent] = useState<Record<string, boolean>>({});
  const [sendingId, setSendingId] = useState<string | null>(null);

  async function handleRemind(id: string) {
    setSendingId(id);
    try {
      await sendFollowUpReminder(id);
      setSent((prev) => ({ ...prev, [id]: true }));
    } finally {
      setSendingId(null);
    }
  }

  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div>
        <h2 className="text-base font-semibold text-foreground">
          Members to follow up
        </h2>
        <p className="text-xs text-muted">
          Students in your community who have been inactive for 14+ days.
        </p>
      </div>

      {members.length === 0 ? (
        <p className="text-sm text-muted">Everyone in your community has been active recently.</p>
      ) : (
        <div className="divide-y divide-border rounded-lg border border-border">
          {members.map((m) => {
            const isSent = Boolean(sent[m.id]);
            const isSending = sendingId === m.id;
            return (
              <div
                key={m.id}
                className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 text-sm"
              >
                <div>
                  <p className="font-medium text-foreground">{m.name}</p>
                  <p className="text-xs text-muted">
                    {m.daysInactive} days inactive · Last active {m.lastActiveAt}
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() => handleRemind(m.id)}
                  disabled={isSent || isSending}
                  className={`inline-flex items-center gap-1.5 rounded-md border px-3 py-1.5 text-xs font-medium ${
                    isSent
                      ? "border-emerald-200 bg-emerald-50 text-emerald-800"
                      : "border-border bg-white text-foreground hover:bg-slate-50"
                  }`}
                >
                  {isSent ? (
                    <>
                      <MailCheck className="h-3.5 w-3.5" aria-hidden="true" />
                      <span>Reminder sent</span>
                    </>
                  ) : (
                    <>
                      <Send className="h-3.5 w-3.5" aria-hidden="true" />
                      <span>{isSending ? "Sending…" : "Send reminder"}</span>
                    </>
                  )}
                </button>
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}
