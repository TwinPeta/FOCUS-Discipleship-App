"use client";

import Link from "next/link";
import { useState } from "react";
import { Byline, Confirm, ErrorText, ReportButton } from "@/components/ui";
import { del, patch, put } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { plural } from "@/lib/format";
import { useAction } from "@/lib/hooks";
import type { Post } from "@/lib/types";

export function MediaGrid({ media }: { media: Post["media"] }) {
  if (!media?.length) return null;
  return (
    <div className="media-grid">
      {media.map((m) => m.kind === "video"
        ? <video key={m.id} src={m.url} controls preload="metadata" />
        // eslint-disable-next-line @next/next/no-img-element
        : <img key={m.id} src={m.url} alt="Photo attached to this post" loading="lazy" />)}
    </div>
  );
}

/** One post: like, open comments, edit or delete your own, report someone else's. `canHide` is for community leaders. */
export function PostCard({ post, onChange, onRemoved, linkComments = true, canHide = false }: {
  post: Post; onChange: (p: Post) => void; onRemoved: () => void; linkComments?: boolean; canHide?: boolean;
}) {
  const { user } = useAuth();
  const mine = !!user && post.author?.id === user.id;
  const like = useAction();
  const save = useAction();
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(post.text);
  const [ask, setAsk] = useState(false);

  const toggle = () => like.run(async () => {
    const r = await (post.liked_by_me ? del : put)<{ like_count: number; liked_by_me: boolean }>(`/posts/${post.id}/like`);
    onChange({ ...post, ...r });
  });

  return (
    <article className="card-item">
      <Byline user={post.author} at={post.created_at} extra={post.pinned ? " · Pinned" : ""} />
      {editing ? (
        <form className="composer" onSubmit={async (e) => {
          e.preventDefault();
          if (await save.run(async () => onChange(await patch<Post>(`/posts/${post.id}`, { text: draft.trim() })))) setEditing(false);
        }}>
          <label className="sr-only" htmlFor={`edit-${post.id}`}>Edit your post</label>
          <textarea id={`edit-${post.id}`} rows={3} maxLength={5000} value={draft} onChange={(e) => setDraft(e.target.value)} />
          <ErrorText>{save.error}</ErrorText>
          <div className="btn-row">
            <button type="button" className="btn btn-sm" onClick={() => { setEditing(false); setDraft(post.text); }}>Cancel</button>
            <button className="btn btn-primary btn-sm" disabled={save.busy || !draft.trim()}>Save</button>
          </div>
        </form>
      ) : <p className="text">{post.text}</p>}
      <MediaGrid media={post.media} />
      <ErrorText>{like.error}</ErrorText>
      <div className="actions">
        <button className={post.liked_by_me ? "act on" : "act"} onClick={toggle} disabled={like.busy} aria-pressed={post.liked_by_me}>
          <i className={`bx ${post.liked_by_me ? "bxs-heart" : "bx-heart"}`} aria-hidden="true" /> {plural(post.like_count, "like")}
        </button>
        {linkComments
          ? <Link className="act" href={`/post/${post.id}`}><i className="bx bx-comment" aria-hidden="true" /> {plural(post.comment_count, "comment")}</Link>
          : <span className="meta">{plural(post.comment_count, "comment")}</span>}
        <span className="spacer" />
        {mine ? (
          <>
            {editing ? null : <button className="link-btn" onClick={() => setEditing(true)}>Edit</button>}
            <button className="link-btn" onClick={() => setAsk(true)}>Delete</button>
          </>
        ) : (
          <>
            {canHide ? <button className="link-btn" onClick={() => setAsk(true)}>Hide post</button> : null}
            <ReportButton type="post" id={post.id} />
          </>
        )}
      </div>
      {ask ? (
        <Confirm title={mine ? "Delete this post?" : "Hide this post?"}
          body={mine ? "The post, its likes and its comments will be removed for everyone." : "Members will no longer see this post."}
          confirmLabel={mine ? "Delete" : "Hide"} onClose={() => setAsk(false)}
          onConfirm={async () => { await del(`/posts/${post.id}`); onRemoved(); }} />
      ) : null}
    </article>
  );
}
