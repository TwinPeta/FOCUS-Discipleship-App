"use client";

import { ErrorText, Load, Panel } from "@/components/ui";
import { post, put } from "@/lib/api";
import { dateTime } from "@/lib/format";
import { useAction, useGet } from "@/lib/hooks";
import type { MeetingItem } from "@/lib/types";

export function MeetingsTab({ communityId }: { communityId: string }) {
  const list = useGet<{ next: MeetingItem | null; past: MeetingItem[] }>(`/communities/${communityId}/meetings`);
  const act = useAction();
  const setNext = (m: MeetingItem) => list.setData((d) => (d ? { ...d, next: m } : d));
  return (
    <>
      <Panel title="Next meeting">
        <Load got={list}>
          {(d) => d.next ? (
            <>
              <p><b>{dateTime(d.next.starts_at)}</b>{d.next.room ? ` · ${d.next.room}` : ""}</p>
              <ErrorText>{act.error}</ErrorText>
              <div className="actions" style={{ marginTop: 12 }}>
                <button className={d.next.going ? "act on" : "act"} aria-pressed={d.next.going} disabled={act.busy}
                  onClick={() => act.run(async () => setNext(await put<MeetingItem>(`/meetings/${d.next!.id}/going`, { going: !d.next!.going })))}>
                  {d.next.going ? <i className="bx bx-check" aria-hidden="true" /> : null} I&apos;m going
                </button>
                {d.next.attended ? <span className="pill ok">Checked in</span> : (
                  <button className="act" disabled={act.busy} onClick={() => act.run(async () => setNext(await post<MeetingItem>(`/meetings/${d.next!.id}/check-in`, {})))}>
                    Check in
                  </button>
                )}
              </div>
              <p className="meta" style={{ marginTop: 10 }}>Check-in opens 30 minutes before the meeting and closes 2 hours after it starts.</p>
            </>
          ) : <p className="empty-box">No meeting is scheduled.</p>}
        </Load>
      </Panel>
      <Panel title="Past meetings">
        <Load got={list} empty={(d) => (d.past.length ? null : "No past meetings yet.")}>
          {(d) => d.past.map((m) => (
            <div className="row" key={m.id}>
              <span className="grow"><b>{dateTime(m.starts_at)}</b><small>{m.room}</small></span>
              <span className={m.attended ? "pill ok" : "pill"}>{m.attended ? "Attended" : "Missed"}</span>
            </div>
          ))}
        </Load>
      </Panel>
    </>
  );
}
