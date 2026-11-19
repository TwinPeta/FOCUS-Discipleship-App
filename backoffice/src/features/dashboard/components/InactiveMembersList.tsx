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
import { MailCheck } from "lucide-react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
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
    <section className="card flex flex-col gap-1">
      <div className="mb-1 flex items-baseline justify-between gap-3">
        <h2 className="eyebrow">Inactive members</h2>
        <p className="text-sm font-extrabold">No activity for 14+ days</p>
      </div>

      {members.length === 0 ? (
        <p className="py-2 text-sm text-muted-foreground">No members are currently inactive for 14+ days.</p>
      ) : (
        <ul className="divide-y-[1.5px] divide-border">
          {members.map((m) => {
            const sent = Boolean(sentIds[m.id]);
            const sending = sendingId === m.id;
            return (
              <li key={m.id} className="flex flex-wrap items-center gap-3 py-2.5">
                <InitialsAvatar name={m.name} />
                <div className="min-w-0 flex-1">
                  <Link href={ROUTES.memberDetail(m.id)} className="block truncate text-base font-extrabold hover:underline">
                    {m.name}
                  </Link>
                  <p className="truncate text-[13px] opacity-80">{m.community}</p>
                </div>
                <span className="text-sm">{m.daysInactive} days</span>
                <button
                  type="button"
                  onClick={() => handleRemind(m.id)}
                  disabled={sent || sending}
                  className="rounded-md border border-border px-3.5 py-1.5 text-xs font-medium"
                >
                  {sent ? (
                    <>
                      <MailCheck className="h-4 w-4" aria-hidden="true" />
                      <span>Reminder sent</span>
                    </>
                  ) : (
                    <span>{sending ? "Sending…" : "Send reminder"}</span>
                  )}
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
