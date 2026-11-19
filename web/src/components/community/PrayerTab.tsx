"use client";

import Link from "next/link";
import { useState } from "react";
import { Byline, Composer, ErrorText, Load, MoreButton, Panel, ReportButton } from "@/components/ui";
import { del, post, put } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { plural } from "@/lib/format";
import { useAction, useGet } from "@/lib/hooks";
import type { Page, PrayerRequest } from "@/lib/types";

export function PrayerCard({ request, onChange, link = true }: { request: PrayerRequest; onChange: (r: PrayerRequest) => void; link?: boolean }) {
  const { user } = useAuth();
  const pray = useAction();
  const mine = !!user && request.author?.id === user.id;
  return (
    <article className="card-item">
      <Byline user={request.author} at={request.created_at} />
      <p className="text">{request.text}</p>
      <ErrorText>{pray.error}</ErrorText>
      <div className="actions">
        <button className={request.prayed_by_me ? "act on" : "act"} disabled={pray.busy} aria-pressed={request.prayed_by_me}
          onClick={() => pray.run(async () => {
            const r = await (request.prayed_by_me ? del : put)<{ prayed_count: number; prayed_by_me: boolean }>(`/prayer-requests/${request.id}/prayed`);
            onChange({ ...request, ...r });
          })}>
          <i className={`bx ${request.prayed_by_me ? "bxs-donate-heart" : "bx-donate-heart"}`} aria-hidden="true" /> {request.prayed_by_me ? "You prayed" : "I prayed"} · {request.prayed_count}
        </button>
        {link ? <Link className="act" href={`/prayer/${request.id}`}><i className="bx bx-comment" aria-hidden="true" /> {plural(request.response_count, "response")}</Link>
          : <span className="meta">{plural(request.response_count, "response")}</span>}
        <span className="spacer" />
        {mine ? null : <ReportButton type="prayer_request" id={request.id} />}
      </div>
    </article>
  );
}

export function PrayerTab({ communityId }: { communityId: string }) {
  const path = `/communities/${communityId}/prayer-requests?limit=20`;
  const list = useGet<Page<PrayerRequest>>(path);
  const [anonymous, setAnonymous] = useState(false);
  return (
    <>
      <Panel>
        <Composer label="prayer request" placeholder="What can your community pray for?" submitLabel="Share request" max={2000} rows={3}
          extra={<label className="check" style={{ gridTemplateColumns: "20px auto" }}><input type="checkbox" checked={anonymous} onChange={(e) => setAnonymous(e.target.checked)} /><span>Post anonymously</span></label>}
          onSubmit={async (text) => {
            const r = await post<PrayerRequest>(`/communities/${communityId}/prayer-requests`, { text, anonymous });
            list.setData((d) => (d ? { ...d, items: [r, ...d.items] } : d));
            setAnonymous(false);
          }} />
      </Panel>
      <Load got={list} empty={(d) => (d.items.length ? null : "No prayer requests yet.")}>
        {(d) => (
          <div className="list-stack">
            {d.items.map((r) => (
              <PrayerCard key={r.id} request={r} onChange={(n) => list.setData((cur) => (cur ? { ...cur, items: cur.items.map((x) => (x.id === n.id ? n : x)) } : cur))} />
            ))}
            <MoreButton<PrayerRequest> got={d} path={path} onMore={(pg) => list.setData((cur) => (cur ? { items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
          </div>
        )}
      </Load>
    </>
  );
}
