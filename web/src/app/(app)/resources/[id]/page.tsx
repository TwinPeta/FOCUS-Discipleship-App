"use client";

import { useParams, useSearchParams } from "next/navigation";
import { Suspense, useMemo, useState } from "react";
import { resourceMeta } from "@/components/community/ResourcesTab";
import { ErrorText, Load, PageTitle, Panel } from "@/components/ui";
import { post, put } from "@/lib/api";
import { useAction, useGet } from "@/lib/hooks";
import { sanitizeHtml, youtubeEmbed } from "@/lib/sanitize";
import type { Resource } from "@/lib/types";

function Body({ r }: { r: Resource }) {
  const html = useMemo(() => (r.body_html ? sanitizeHtml(r.body_html) : ""), [r.body_html]);
  if (r.type === "video") {
    if (!r.stream_url) return <p className="empty-box">This video is not available yet.</p>;
    const yt = youtubeEmbed(r.stream_url);
    return yt
      ? <iframe className="video-frame" src={yt} title={r.title} allow="accelerometer; encrypted-media; picture-in-picture; fullscreen" allowFullScreen referrerPolicy="strict-origin-when-cross-origin" />
      : <video className="video-frame" src={r.stream_url} controls poster={r.thumbnail_url || undefined} />;
  }
  if (r.type === "devotional") return html ? <div className="prose" dangerouslySetInnerHTML={{ __html: html }} /> : <p className="empty-box">This devotional has no text yet.</p>;
  if (r.type === "document") {
    return r.document_url
      ? <a className="btn btn-primary" href={r.document_url} target="_blank" rel="noopener noreferrer">Open document</a>
      : <p className="empty-box">This document is not available yet.</p>;
  }
  return null;
}

function View() {
  const { id } = useParams<{ id: string }>();
  const params = useSearchParams();
  const pathway = params.get("pathway");
  const step = params.get("step");
  const got = useGet<Resource>(`/resources/${id}`);
  const act = useAction();
  const [done, setDone] = useState(false);
  return (
    <>
      <PageTitle title={got.data?.title || "Resource"} sub={got.data ? resourceMeta(got.data) : undefined}
        back={pathway ? { href: `/pathways/${pathway}`, label: "Back to the pathway" } : { href: "/community", label: "Community" }} />
      <Load got={got} rows={6}>
        {(r) => (
          <Panel>
            <div style={{ display: "grid", gap: 16 }}>
              <Body r={r} />
              <ErrorText>{act.error}</ErrorText>
              <div className="actions">
                {r.my_progress.completed || done ? <span className="pill ok">Completed</span> : (
                  <button className="btn btn-primary btn-sm" disabled={act.busy} onClick={() => act.run(async () => {
                    await put(`/resources/${id}/progress`, { completed: true });
                    // Opened from a pathway step: finishing the resource finishes the step too.
                    if (pathway && step) await post(`/pathways/${pathway}/steps/${step}/complete`, {}).catch(() => undefined);
                    setDone(true);
                  })}>{r.type === "video" ? "I watched this" : "Mark as done"}</button>
                )}
                {r.added_by ? <span className="meta">Shared by {r.added_by.full_name}</span> : null}
              </div>
            </div>
          </Panel>
        )}
      </Load>
    </>
  );
}

export default function ResourcePage() {
  return <Suspense><View /></Suspense>;
}
