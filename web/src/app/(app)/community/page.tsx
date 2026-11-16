"use client";

import Link from "next/link";
import { useState } from "react";
import { Confirm, ErrorText, Load, PageTitle, Panel } from "@/components/ui";
import { del, post } from "@/lib/api";
import { meetingText } from "@/lib/format";
import { useAction, useGet } from "@/lib/hooks";
import type { CommunitySummary, MyCommunities, MyCommunity, Page } from "@/lib/types";

function Mine({ label, m, onChanged }: { label: string; m: MyCommunity; onChanged: () => Promise<void> }) {
  const [ask, setAsk] = useState(false);
  if (!m) return null;
  const member = m.membership_status === "member";
  return (
    <div className="row">
      <span className="avatar" aria-hidden="true">{m.community.initials}</span>
      <span className="grow">
        <b>{m.community.name}</b>
        <small>{label}{member ? "" : " · waiting for the super-mentor to approve"}</small>
      </span>
      <span className="row-actions">
        {member ? <Link className="btn btn-primary btn-sm" href={`/community/${m.community.id}`}>Open</Link>
          : m.join_request_id ? <button className="btn btn-sm" onClick={() => setAsk(true)}>Cancel request</button> : <span className="pill">Pending</span>}
      </span>
      {ask ? (
        <Confirm title="Cancel your request?" body={`You will no longer be waiting to join ${m.community.name}. You can ask again, or pick another community.`}
          confirmLabel="Cancel request" onClose={() => setAsk(false)}
          onConfirm={async () => { await del(`/join-requests/${m.join_request_id}`); await onChanged(); }} />
      ) : null}
    </div>
  );
}

export default function Communities() {
  const mine = useGet<MyCommunities>("/me/communities", 30000);
  const [q, setQ] = useState("");
  const [term, setTerm] = useState("");
  const browse = useGet<Page<CommunitySummary>>(`/communities?type=specific&limit=50${term ? `&q=${encodeURIComponent(term)}` : ""}`);
  const join = useAction();
  const hasSpecific = !!mine.data?.specific;

  return (
    <>
      <PageTitle title="Community" sub="Your campus community, and one smaller group with mentors." />
      <Panel title="Your communities">
        <Load got={mine} empty={(d) => (!d.general && !d.specific ? "You are not in a community yet." : null)}>
          {(d) => (
            <>
              <Mine label="General community" m={d.general} onChanged={async () => { await mine.reload(); await browse.reload(); }} />
              <Mine label="Specific community" m={d.specific} onChanged={async () => { await mine.reload(); await browse.reload(); }} />
            </>
          )}
        </Load>
      </Panel>
      <Panel title={hasSpecific ? "Specific communities on your campus" : "Pick one specific community"}>
        <p className="meta" style={{ marginBottom: 14 }}>
          {hasSpecific ? "You can belong to one specific community at a time." : "A smaller group with mentors. You can join one. The super-mentor approves each request."}
        </p>
        <form className="search" style={{ marginTop: 0, marginBottom: 14 }} role="search" onSubmit={(e) => { e.preventDefault(); setTerm(q.trim()); }}>
          <label className="sr-only" htmlFor="q">Search communities</label>
          <input id="q" type="search" placeholder="Search by name, day or place" value={q} onChange={(e) => { setQ(e.target.value); if (!e.target.value) setTerm(""); }} />
          <button className="btn btn-sm" type="submit">Search</button>
        </form>
        <ErrorText>{join.error}</ErrorText>
        <Load got={browse} empty={(d) => (d.items.length ? null : term ? "No community matches that search." : "There are no specific communities on your campus yet.")}>
          {(d) => d.items.map((c) => (
            <div className="row" key={c.id}>
              <span className="avatar" aria-hidden="true">{c.initials}</span>
              <span className="grow">
                <b>{c.name}</b>
                <small>{[c.super_mentor ? `Led by ${c.super_mentor.full_name}` : "", meetingText(c.meeting)].filter(Boolean).join(" · ") || "Specific community"}</small>
              </span>
              <span className="row-actions">
                <Link className="btn btn-sm" href={`/community/${c.id}`}>View</Link>
                {c.membership_status === "member" ? <span className="pill ok">Member</span>
                  : c.membership_status === "pending" ? <span className="pill">Requested</span>
                  : c.can_request ? (
                    <button className="btn btn-primary btn-sm" disabled={join.busy}
                      onClick={() => join.run(async () => { await post(`/communities/${c.id}/join-requests`, {}); await mine.reload(); await browse.reload(); })}>
                      Ask to join
                    </button>
                  ) : null}
              </span>
            </div>
          ))}
        </Load>
      </Panel>
    </>
  );
}
