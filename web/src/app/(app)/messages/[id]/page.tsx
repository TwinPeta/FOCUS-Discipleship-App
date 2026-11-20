"use client";

import { useParams } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { Composer, Confirm, Load, PageTitle, Panel, ReportButton } from "@/components/ui";
import { post, postOnce, put } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { timeAgo } from "@/lib/format";
import { useGet } from "@/lib/hooks";
import { useRealtime, type LiveEvent } from "@/lib/realtime";
import type { Message, Page, UserRef } from "@/lib/types";

export default function Thread() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const { publish } = useRealtime();
  // Newest first from the API; loaded once, then updated when a message arrives in this chat.
  const onThisChat = useCallback((e: LiveEvent) => (e.event === "message.created" || e.event === "message.read") && (!e.data.conversation_id || e.data.conversation_id === id), [id]);
  const got = useGet<Page<Message> & { participant: UserRef }>(`/conversations/${id}/messages?limit=100`, onThisChat);
  const end = useRef<HTMLDivElement>(null);
  const [blocking, setBlocking] = useState(false);
  const items = got.data ? [...got.data.items].reverse() : [];
  const newest = got.data?.items[0]?.id;
  const unread = items.some((m) => m.sender_id !== user?.id && !m.read_at);

  useEffect(() => {
    end.current?.scrollIntoView({ block: "nearest" });
  }, [newest]);

  useEffect(() => {
    if (unread) post(`/conversations/${id}/read`, {}).then(() => publish({ event: "local.messages", data: {} })).catch(() => undefined);
  }, [unread, id, newest, publish]);

  const other = got.data?.participant;
  return (
    <>
      <PageTitle title={other?.full_name || "Conversation"} sub={other ? `@${other.username}` : undefined} back={{ href: "/messages", label: "All messages" }}
        action={other ? <span className="row-actions"><button className="link-btn" onClick={() => setBlocking(true)}>Block</button><ReportButton type="user" id={other.id} /></span> : null} />
      <Panel>
        <Load got={got} rows={4}>
          {() => (
            <div className="thread" role="log" aria-live="polite" aria-label="Messages">
              {items.length ? items.map((m) => {
                const mine = m.sender_id === user?.id;
                return (
                  <div key={m.id} className={mine ? "bubble mine" : "bubble"}>
                    {m.text}
                    <small>{timeAgo(m.sent_at)}{mine && m.read_at ? " · Read" : ""}</small>
                  </div>
                );
              }) : <p className="empty-box">No messages yet. Say hello.</p>}
              <div ref={end} />
            </div>
          )}
        </Load>
        {got.data ? (
          <div style={{ marginTop: 16 }}>
            <Composer label="message" placeholder="Write a message" submitLabel="Send" max={4000}
              onSubmit={async (text) => {
                const m = await postOnce<Message>(`/conversations/${id}/messages`, { text });
                got.setData((d) => (d ? { ...d, items: [m, ...d.items.filter((x) => x.id !== m.id)] } : d));
              }} />
          </div>
        ) : null}
      </Panel>
      {blocking && other ? (
        <Confirm title={`Block ${other.full_name}?`} body="You will not see each other's messages. You can unblock them in Settings."
          confirmLabel="Block" onClose={() => setBlocking(false)} onConfirm={async () => { await put(`/users/${other.id}/block`); window.location.assign("/messages"); }} />
      ) : null}
    </>
  );
}
