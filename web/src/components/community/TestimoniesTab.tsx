"use client";

import Link from "next/link";
import { useState } from "react";
import { Byline, ErrorText, Load, MoreButton, Panel } from "@/components/ui";
import { post, uploadImage } from "@/lib/api";
import { useAction, useGet } from "@/lib/hooks";
import type { Page, Testimony } from "@/lib/types";

function NewTestimony({ communityId, onSent }: { communityId: string; onSent: () => void }) {
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [consent, setConsent] = useState(false);
  const [file, setFile] = useState<File | null>(null);
  const send = useAction();
  return (
    <form className="inline-form" onSubmit={async (e) => {
      e.preventDefault();
      const ok = await send.run(async () => {
        const media_ids = file ? [await uploadImage(file, file.type.startsWith("video/") ? "testimony_video" : "testimony_photo")] : [];
        await post(`/communities/${communityId}/testimonies`, { title: title.trim(), body: body.trim(), consent: true, ...(media_ids.length ? { media_ids } : {}) });
      });
      if (ok) onSent();
    }}>
      <div className="field">
        <label htmlFor="t-title">Title</label>
        <input id="t-title" maxLength={120} value={title} onChange={(e) => setTitle(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="t-body">Your story</label>
        <textarea id="t-body" rows={6} maxLength={10000} value={body} onChange={(e) => setBody(e.target.value)} />
      </div>
      <div className="field">
        <label htmlFor="t-photo">Photo or video (optional)</label>
        <input id="t-photo" type="file" accept="image/jpeg,image/png,image/webp,video/mp4,video/quicktime,video/webm" onChange={(e) => {
          const f = e.target.files?.[0] || null;
          const limit = f?.type.startsWith("video/") ? 200 : 10;
          if (f && f.size > limit * 1024 * 1024) { send.setError(`That file is too large. The limit is ${limit} MB.`); e.target.value = ""; setFile(null); return; }
          send.setError("");
          setFile(f);
        }} />
        <span className="hint">A photo up to 10 MB, or a video (MP4, MOV or WebM) up to 200 MB. Large videos take a while to upload.</span>
      </div>
      <label className="check">
        <input type="checkbox" checked={consent} onChange={(e) => setConsent(e.target.checked)} />
        <span>I agree to share this story with my community. A mentor reviews it before it is published.</span>
      </label>
      <ErrorText>{send.error}</ErrorText>
      <button className="btn btn-primary" disabled={send.busy || !title.trim() || !body.trim() || !consent}>{send.busy ? (file ? "Uploading…" : "Sending…") : "Send for review"}</button>
    </form>
  );
}

export function TestimoniesTab({ communityId }: { communityId: string }) {
  const path = `/communities/${communityId}/testimonies?limit=20`;
  const list = useGet<Page<Testimony> & { has_my_pending: boolean }>(path);
  const [writing, setWriting] = useState(false);
  const [sent, setSent] = useState(false);
  return (
    <>
      <Panel title="Share your testimony" action={writing ? <button className="btn btn-sm" onClick={() => setWriting(false)}>Close</button> : <button className="btn btn-primary btn-sm" onClick={() => { setWriting(true); setSent(false); }}>Write a story</button>}>
        {sent ? <p className="ok-text">Thank you. Your story was sent for review and will appear once a mentor approves it.</p> : null}
        {writing ? <NewTestimony communityId={communityId} onSent={() => { setWriting(false); setSent(true); list.reload(); }} />
          : !sent ? <p className="meta">Tell your community what God has done. Stories are reviewed before they are published.</p> : null}
      </Panel>
      <Load got={list} empty={(d) => (d.items.length ? null : "No testimonies yet.")}>
        {(d) => (
          <div className="list-stack">
            {d.items.map((t) => (
              <Link key={t.id} className="card-item" href={`/testimony/${t.id}`}>
                <Byline user={t.author} at={t.published_at || t.created_at} extra={`${t.format === "video" ? " · Video" : ""}${t.status === "published" ? "" : " · Waiting for review"}`} />
                <h3>{t.title}</h3>
                <p className="text">{t.excerpt}{t.excerpt.length >= 160 ? "…" : ""}</p>
              </Link>
            ))}
            <MoreButton<Testimony> got={d} path={path} onMore={(pg) => list.setData((cur) => (cur ? { ...cur, items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
          </div>
        )}
      </Load>
    </>
  );
}
