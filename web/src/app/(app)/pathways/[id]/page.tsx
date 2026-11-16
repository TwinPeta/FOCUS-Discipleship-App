"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { ErrorText, Load, PageTitle, Panel } from "@/components/ui";
import { post, put } from "@/lib/api";
import { useAction, useGet } from "@/lib/hooks";
import type { Badge, PathwayDetail, PathwayStep } from "@/lib/types";

const TYPE: Record<string, string> = { video: "Video", devotional: "Devotional", document: "Document", quiz: "Quiz", reflection: "Reflection", activity: "Activity" };
const hrefOf = (s: PathwayStep) => (s.resource_id ? (s.type === "quiz" ? `/quiz/${s.resource_id}` : `/resources/${s.resource_id}`) : null);

export default function PathwayPage() {
  const { id } = useParams<{ id: string }>();
  const got = useGet<PathwayDetail>(`/pathways/${id}`);
  const act = useAction();
  const [badges, setBadges] = useState<Badge[]>([]);
  return (
    <>
      <PageTitle title={got.data?.title || "Pathway"} back={{ href: "/pathways", label: "All pathways" }}
        sub={got.data ? `${got.data.steps_completed} of ${got.data.steps_total} steps done` : undefined} />
      {badges.length ? <p className="notice"><i className="bx bx-party" aria-hidden="true" /> You earned {badges.length === 1 ? "a badge" : "badges"}: {badges.map((b) => b.name).join(", ")}.</p> : null}
      <ErrorText>{act.error}</ErrorText>
      <Load got={got} rows={5}>
        {(p) => (
          <>
            {p.status === "locked" ? <p className="notice">{p.unlock_hint || "This pathway is locked."}</p> : null}
            {p.status === "available" ? (
              <Panel>
                <p style={{ marginBottom: 12 }}>Start this pathway to track your progress through its steps.</p>
                <button className="btn btn-primary" disabled={act.busy} onClick={() => act.run(async () => { await put(`/pathways/${id}/enrollment`); await got.reload(); })}>
                  Start pathway
                </button>
              </Panel>
            ) : null}
            {p.status === "completed" ? <p className="notice">You completed this pathway. Well done.</p> : null}
            <ol className="steps-list">
              {p.steps.map((s) => {
                const href = hrefOf(s);
                const started = p.status === "in_progress" || p.status === "completed";
                return (
                  <li key={s.id} className={`step ${s.status}`}>
                    <span className="num" aria-hidden="true">{s.status === "done" ? <i className="bx bx-check" aria-hidden="true" /> : s.order}</span>
                    <div>
                      <b>{s.title}</b>
                      <p className="meta">{[TYPE[s.type] || s.type, s.duration_label, s.status === "done" ? "Done" : ""].filter(Boolean).join(" · ")}</p>
                    </div>
                    <div className="row-actions">
                      {href ? <Link className="btn btn-sm" href={`${href}?pathway=${id}&step=${s.id}`}>{s.type === "quiz" ? "Take quiz" : "Open"}</Link> : null}
                      {started && s.status !== "done" && s.type !== "quiz" ? (
                        <button className="btn btn-primary btn-sm" disabled={act.busy} onClick={() => act.run(async () => {
                          const r = await post<{ badges_awarded?: Badge[] }>(`/pathways/${id}/steps/${s.id}/complete`, {});
                          if (r?.badges_awarded?.length) setBadges(r.badges_awarded);
                          await got.reload();
                        })}>Mark done</button>
                      ) : null}
                    </div>
                  </li>
                );
              })}
            </ol>
          </>
        )}
      </Load>
    </>
  );
}
