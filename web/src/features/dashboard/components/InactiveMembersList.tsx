/**
 * src/features/dashboard/components/InactiveMembersList.tsx
 *
 * WHAT: Members inactive 14+ days with community and Send reminder action
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { MailCheck, Send } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";
import { sendMemberReminder, type InactiveMember } from "../queries";

export function InactiveMembersList({
  members,
}: {
  members: InactiveMember[];
}) {
  const [sentIds, setSentIds] = useState<Record<string, boolean>>({});
  const [sendingId, setSendingId] = useState<string | null>(null);

  async function handleRemind(id: string) {
    setSendingId(id);
    try {
      await sendMemberReminder(id);
      setSentIds((prev) => ({ ...prev, [id]: true }));
    } finally {
      setSendingId(null);
    }
  }

  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div>
        <h2 className="text-base font-semibold text-foreground">
          Inactive members (14+ days)
        </h2>
        <p className="text-xs text-muted">
          Follow up with students or mentors who have not logged in for two weeks or more.
        </p>
      </div>

      {members.length === 0 ? (
        <p className="text-sm text-muted">No members are currently inactive for 14+ days.</p>
      ) : (
        <div className="divide-y divide-border rounded-lg border border-border">
          {members.map((m) => {
            const sent = Boolean(sentIds[m.id]);
            const sending = sendingId === m.id;
            return (
              <div
                key={m.id}
                className="flex flex-wrap items-center justify-between gap-3 px-4 py-3 text-sm"
              >
                <div>
                  <Link
                    href={ROUTES.memberDetail(m.id)}
                    className="font-medium text-foreground hover:text-primary hover:underline"
                  >
                    {m.name}
                  </Link>
                  <p className="text-xs text-muted">
                    {m.community} · {m.daysInactive} days inactive (last active {m.lastActiveAt})
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() => handleRemind(m.id)}
                  disabled={sent || sending}
                  className={`inline-flex items-center gap-1.5 rounded-md border px-3 py-1.5 text-xs font-medium transition ${
                    sent
                      ? "border-emerald-200 bg-emerald-50 text-emerald-800"
                      : "border-border bg-white text-foreground hover:bg-slate-50"
                  }`}
                >
                  {sent ? (
                    <>
                      <MailCheck className="h-3.5 w-3.5" aria-hidden="true" />
                      <span>Reminder sent</span>
                    </>
                  ) : (
                    <>
                      <Send className="h-3.5 w-3.5" aria-hidden="true" />
                      <span>{sending ? "Sending…" : "Send reminder"}</span>
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
