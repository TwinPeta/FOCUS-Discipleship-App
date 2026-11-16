"use client";

import { useParams } from "next/navigation";
import { PrayerCard } from "@/components/community/PrayerTab";
import { Byline, Composer, Load, PageTitle, Panel } from "@/components/ui";
import { post } from "@/lib/api";
import { useGet } from "@/lib/hooks";
import type { Comment, Page, PrayerRequest } from "@/lib/types";

export default function PrayerPage() {
  const { id } = useParams<{ id: string }>();
  const got = useGet<PrayerRequest>(`/prayer-requests/${id}`);
  const responses = useGet<Page<Comment>>(`/prayer-requests/${id}/responses?limit=100`, 30000);
  return (
    <>
      <PageTitle title="Prayer request" back={{ href: got.data ? `/community/${got.data.community_id}?tab=prayer` : "/community", label: "Back to the prayer wall" }} />
      <Load got={got}>{(r) => <PrayerCard request={r} link={false} onChange={(n) => got.setData(n)} />}</Load>
      {got.data ? (
        <Panel title="Responses">
          <Load got={responses} empty={(d) => (d.items.length ? null : "No responses yet. Leave a word of encouragement.")}>
            {(d) => d.items.map((c) => (
              <div className="row" key={c.id} style={{ alignItems: "flex-start" }}>
                <span className="grow" style={{ display: "grid", gap: 6 }}>
                  <Byline user={c.author} at={c.created_at} />
                  <span style={{ whiteSpace: "pre-wrap", overflowWrap: "anywhere" }}>{c.text}</span>
                </span>
              </div>
            ))}
          </Load>
          <div style={{ marginTop: 16 }}>
            <Composer label="response" placeholder="Write an encouragement" submitLabel="Respond" max={2000}
              onSubmit={async (text) => {
                const c = await post<Comment>(`/prayer-requests/${id}/responses`, { text });
                responses.setData((d) => (d ? { ...d, items: [...d.items, c] } : d));
                got.setData((r) => (r ? { ...r, response_count: r.response_count + 1 } : r));
              }} />
          </div>
        </Panel>
      ) : null}
    </>
  );
}
