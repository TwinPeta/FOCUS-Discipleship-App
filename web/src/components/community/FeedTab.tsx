"use client";

import { Composer, Load, MoreButton, Panel } from "@/components/ui";
import { postOnce } from "@/lib/api";
import { useGet } from "@/lib/hooks";
import type { Page, Post } from "@/lib/types";
import { PostCard } from "./PostCard";

export function FeedTab({ communityId, isLeader }: { communityId: string; isLeader: boolean }) {
  const path = `/communities/${communityId}/posts?limit=20`;
  const feed = useGet<Page<Post>>(path);
  const update = (fn: (items: Post[]) => Post[]) => feed.setData((d) => (d ? { ...d, items: fn(d.items) } : d));
  return (
    <>
      <Panel>
        <Composer label="post" placeholder="Share something with your community" submitLabel="Post" max={5000} rows={3} photos="post_photo"
          onSubmit={async (text, media_ids) => {
            const p = await postOnce<Post>(`/communities/${communityId}/posts`, { text, ...(media_ids.length ? { media_ids } : {}) });
            update((items) => [...items.filter((x) => x.pinned), p, ...items.filter((x) => !x.pinned)]);
          }} />
      </Panel>
      <Load got={feed} empty={(d) => (d.items.length ? null : "No posts yet. Be the first to share something.")}>
        {(d) => (
          <div className="list-stack">
            {d.items.map((p) => (
              <PostCard key={p.id} post={p} canHide={isLeader}
                onChange={(n) => update((items) => items.map((x) => (x.id === n.id ? n : x)))}
                onRemoved={() => update((items) => items.filter((x) => x.id !== p.id))} />
            ))}
            <MoreButton<Post> got={d} path={path} onMore={(pg) => feed.setData((cur) => (cur ? { items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
          </div>
        )}
      </Load>
    </>
  );
}
