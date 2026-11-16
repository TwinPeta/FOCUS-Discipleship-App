"use client";

import { useParams, useRouter } from "next/navigation";
import { PostCard } from "@/components/community/PostCard";
import { Byline, Composer, Load, MoreButton, PageTitle, Panel, ReportButton } from "@/components/ui";
import { post as send } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { useGet } from "@/lib/hooks";
import type { Comment, Page, Post } from "@/lib/types";

export default function PostPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user } = useAuth();
  const got = useGet<Post>(`/posts/${id}`);
  const path = `/posts/${id}/comments?limit=50`;
  const comments = useGet<Page<Comment>>(path, 30000);
  const back = got.data ? `/community/${got.data.community_id}` : "/community";
  return (
    <>
      <PageTitle title="Post" back={{ href: back, label: "Back to the feed" }} />
      <Load got={got}>
        {(p) => <PostCard post={p} linkComments={false} onChange={(n) => got.setData(n)} onRemoved={() => router.replace(back)} />}
      </Load>
      {got.data ? (
        <Panel title="Comments">
          <Load got={comments} empty={(d) => (d.items.length ? null : "No comments yet.")}>
            {(d) => (
              <>
                {d.items.map((c) => (
                  <div className="row" key={c.id} style={{ alignItems: "flex-start" }}>
                    <span className="grow" style={{ display: "grid", gap: 6 }}>
                      <Byline user={c.author} at={c.created_at} />
                      <span className="text" style={{ whiteSpace: "pre-wrap", overflowWrap: "anywhere" }}>{c.text}</span>
                    </span>
                    {c.author?.id === user?.id ? null : <ReportButton type="comment" id={c.id} />}
                  </div>
                ))}
                <MoreButton<Comment> got={d} path={path} onMore={(pg) => comments.setData((cur) => (cur ? { items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
              </>
            )}
          </Load>
          <div style={{ marginTop: 16 }}>
            <Composer label="comment" placeholder="Write a comment" submitLabel="Comment" max={2000}
              onSubmit={async (text) => {
                const c = await send<Comment>(`/posts/${id}/comments`, { text });
                comments.setData((d) => (d ? { ...d, items: [...d.items, c] } : d));
                got.setData((p) => (p ? { ...p, comment_count: p.comment_count + 1 } : p));
              }} />
          </div>
        </Panel>
      ) : null}
    </>
  );
}
