"use client";

import { useState } from "react";
import { Avatar, ErrorText, Load, Panel } from "@/components/ui";
import { post } from "@/lib/api";
import { timeAgo } from "@/lib/format";
import { onJoinRequest } from "@/lib/realtime";
import { useAction, useGet } from "@/lib/hooks";
import type { JoinRequest, ModerationCase } from "@/lib/types";

const CONTENT: Record<string, string> = { post: "Post", comment: "Comment", prayer_request: "Prayer request", testimony: "Testimony", message: "Message", user: "Member" };

/** Super-mentor tools: approve or decline people asking to join, and act on reported content. */
export function ManageTab({ communityId }: { communityId: string }) {
  const requests = useGet<{ items: JoinRequest[] }>(`/communities/${communityId}/join-requests`, onJoinRequest);
  const cases = useGet<{ items: ModerationCase[] }>(`/communities/${communityId}/moderation/cases`);
  const act = useAction();
  const [declining, setDeclining] = useState<string | null>(null);
  const [note, setNote] = useState("");
  const decide = (id: string, decision: "approve" | "reject") => act.run(async () => {
    await post(`/join-requests/${id}/decision`, { decision, ...(decision === "reject" && note.trim() ? { note: note.trim() } : {}) });
    setDeclining(null); setNote("");
    await requests.reload();
  });
  return (
    <>
      <Panel title="People asking to join">
        <ErrorText>{act.error}</ErrorText>
        <Load got={requests} empty={(d) => (d.items.length ? null : "No one is waiting.")}>
          {(d) => d.items.map((j) => (
            <div key={j.id}>
              <div className="row">
                <Avatar user={j.user} />
                <span className="grow"><b>{j.user.full_name}</b><small>@{j.user.username} · asked {timeAgo(j.created_at)}</small></span>
                <span className="row-actions">
                  <button className="btn btn-primary btn-sm" disabled={act.busy} onClick={() => decide(j.id, "approve")}>Approve</button>
                  <button className="btn btn-sm" disabled={act.busy} onClick={() => { setDeclining(declining === j.id ? null : j.id); setNote(""); }}>Decline</button>
                </span>
              </div>
              {declining === j.id ? (
                <form className="inline-form" style={{ marginBottom: 12 }} onSubmit={(e) => { e.preventDefault(); decide(j.id, "reject"); }}>
                  <div className="field">
                    <label htmlFor={`note-${j.id}`}>Message to {j.user.full_name.split(" ")[0]} (optional)</label>
                    <textarea id={`note-${j.id}`} rows={2} maxLength={500} value={note} onChange={(e) => setNote(e.target.value)} />
                  </div>
                  <div className="btn-row"><button className="btn btn-dark btn-sm" disabled={act.busy}>Decline request</button></div>
                </form>
              ) : null}
            </div>
          ))}
        </Load>
      </Panel>
      <Panel title="Reported content">
        <Load got={cases} empty={(d) => (d.items.length ? null : "Nothing has been reported.")}>
          {(d) => d.items.map((c) => (
            <div className="card-item" key={c.id} style={{ marginBottom: 12, boxShadow: "none" }}>
              <p className="meta">{CONTENT[c.content] || c.content}{c.author ? ` by ${c.author.full_name}` : ""} · {c.reason.replace(/_/g, " ")} · reported by {c.first_reporter_name}{c.report_count > 1 ? ` and ${c.report_count - 1} more` : ""}</p>
              <p className="text">“{c.preview}”</p>
              <div className="row-actions" style={{ justifyContent: "flex-start" }}>
                {([["keep", "Keep"], ["hide", "Hide"], ["warn", "Hide and warn"], ["escalate", "Send to FCU team"]] as const).map(([a, l]) => (
                  <button key={a} className="btn btn-sm" disabled={act.busy}
                    onClick={() => act.run(async () => { await post(`/communities/${communityId}/moderation/cases/${encodeURIComponent(c.id)}/action`, { action: a }); await cases.reload(); })}>
                    {l}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </Load>
      </Panel>
    </>
  );
}
