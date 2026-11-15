/**
 * src/app/(my-community)/my-community/members/page.tsx
 *
 * WHAT: Own community members only
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { MailCheck, Send } from "lucide-react";
import { AuditNotice } from "@/components/common/AuditNotice";
import {
  fetchMyCommunityOverview,
  sendFollowUpReminder,
  type OwnCommunityMember,
} from "@/features/my-community/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function MyCommunityMembersPage() {
  const [communityName, setCommunityName] = useState("");
  const [members, setMembers] = useState<OwnCommunityMember[]>([]);
  const [search, setSearch] = useState("");
  const [sentIds, setSentIds] = useState<Record<string, boolean>>({});

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchMyCommunityOverview().then((res) => {
      if (!active) return;
      setCommunityName(res.communityName);
      setMembers(res.members);
    })
      .catch((e: unknown) => {
        if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
      });
    return () => {
      active = false;
    };
  }, []);

  const filtered = members.filter((m) => {
    if (!search.trim()) return true;
    const q = search.trim().toLowerCase();
    return (
      m.name.toLowerCase().includes(q) ||
      m.email.toLowerCase().includes(q) ||
      m.roleLabel.toLowerCase().includes(q)
    );
  });

  async function handleRemind(id: string) {
    await sendFollowUpReminder(id);
    setSentIds((prev) => ({ ...prev, [id]: true }));
  }

  return (
    <main className="space-y-6">
      {loadError && <ErrorState message={loadError} />}
      <div>
        <h1 className="text-2xl font-semibold text-foreground">
          Members — {communityName || "your community"}
        </h1>
        <p className="mt-1 text-sm text-muted">
          Scoped to your community only. Role changes and exports are managed by System admins.
        </p>
      </div>

      <AuditNotice message="Viewing community member details and sending follow-up reminders are recorded in the audit log." />

      <div className="max-w-sm">
        <label htmlFor="my-members-search" className="sr-only">
          Search members
        </label>
        <input
          id="my-members-search"
          type="search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search name, email, or role…"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
        />
      </div>

      <div className="overflow-x-auto rounded-xl border border-border bg-white">
        <table className="w-full border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-border bg-slate-50 text-xs font-semibold uppercase tracking-wide text-muted">
              <th className="px-4 py-3">Member</th>
              <th className="px-4 py-3">Role</th>
              <th className="px-4 py-3">Joined</th>
              <th className="px-4 py-3">Activity</th>
              <th className="px-4 py-3 text-right">Follow-up</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.map((m) => {
              const sent = Boolean(sentIds[m.id]);
              return (
                <tr key={m.id}>
                  <td className="px-4 py-3">
                    <div className="font-medium text-foreground">{m.name}</div>
                    <div className="text-xs text-muted">{m.email}</div>
                  </td>
                  <td className="px-4 py-3 text-xs text-foreground">{m.roleLabel}</td>
                  <td className="px-4 py-3 text-xs text-muted">{m.joinedAt}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                        m.active
                          ? "bg-emerald-50 text-emerald-800"
                          : "bg-amber-50 text-amber-800"
                      }`}
                    >
                      {m.active ? "Active" : "Inactive 14+ days"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right">
                    {!m.active && (
                      <button
                        type="button"
                        onClick={() => handleRemind(m.id)}
                        disabled={sent}
                        className="inline-flex items-center gap-1 rounded-md border border-border px-2.5 py-1 text-xs font-medium text-foreground hover:bg-slate-50 disabled:opacity-60"
                      >
                        {sent ? (
                          <>
                            <MailCheck className="h-3.5 w-3.5 text-emerald-700" aria-hidden="true" />
                            <span>Sent</span>
                          </>
                        ) : (
                          <>
                            <Send className="h-3.5 w-3.5" aria-hidden="true" />
                            <span>Send reminder</span>
                          </>
                        )}
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </main>
  );
}
