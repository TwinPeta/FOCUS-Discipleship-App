"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Avatar, Confirm, ErrorText, Load, MoreButton, Panel, ReportButton } from "@/components/ui";
import { post, put } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { ROLE_LABEL } from "@/lib/format";
import { useAction, useGet } from "@/lib/hooks";
import type { Conversation, Page, UserRef } from "@/lib/types";

export function MembersTab({ communityId }: { communityId: string }) {
  const { user } = useAuth();
  const router = useRouter();
  const path = `/communities/${communityId}/members?limit=50`;
  const list = useGet<Page<UserRef>>(path);
  const act = useAction();
  const [block, setBlock] = useState<UserRef | null>(null);
  return (
    <Panel title="Members">
      <ErrorText>{act.error}</ErrorText>
      <Load got={list} empty={(d) => (d.items.length ? null : "No members yet.")}>
        {(d) => (
          <>
            {d.items.map((m) => (
              <div className="row" key={m.id}>
                <Avatar user={m} />
                <span className="grow">
                  <b>{m.full_name}{m.id === user?.id ? " (you)" : ""}</b>
                  <small>@{m.username}{m.community_role && m.community_role !== "member" ? ` · ${ROLE_LABEL[m.community_role]}` : ""}{m.online ? " · online" : ""}</small>
                </span>
                {m.id === user?.id ? null : (
                  <span className="row-actions">
                    <button className="btn btn-sm" disabled={act.busy} onClick={() => act.run(async () => {
                      const c = await post<Conversation>("/conversations", { user_id: m.id });
                      router.push(`/messages/${c.id}`);
                    })}>Message</button>
                    <button className="link-btn" onClick={() => setBlock(m)}>Block</button>
                    <ReportButton type="user" id={m.id} />
                  </span>
                )}
              </div>
            ))}
            <MoreButton<UserRef> got={d} path={path} onMore={(pg) => list.setData((cur) => (cur ? { items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
          </>
        )}
      </Load>
      {block ? (
        <Confirm title={`Block ${block.full_name}?`} body="You will not see each other's messages. You can unblock them in Settings."
          confirmLabel="Block" onClose={() => setBlock(null)} onConfirm={() => put(`/users/${block.id}/block`)} />
      ) : null}
    </Panel>
  );
}
