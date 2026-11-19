"use client";

import Link from "next/link";
import { useState } from "react";
import { Avatar, Load, PageTitle, Panel } from "@/components/ui";
import { timeAgo } from "@/lib/format";
import { onMessage } from "@/lib/realtime";
import { useGet } from "@/lib/hooks";
import type { Conversation, Page } from "@/lib/types";

const FILTERS: [string, string][] = [["all", "All"], ["mentors", "Mentors"], ["members", "Members"]];

export default function Messages() {
  const [filter, setFilter] = useState("all");
  const list = useGet<Page<Conversation> & { unread_total: number }>(`/conversations?limit=50&filter=${filter}`, onMessage);
  return (
    <>
      <PageTitle title="Messages" sub="Private conversations with mentors and members of your communities." />
      <div className="tabs" role="group" aria-label="Filter conversations">
        {FILTERS.map(([v, l]) => <a key={v} href="#" aria-current={filter === v ? "page" : undefined} onClick={(e) => { e.preventDefault(); setFilter(v); }}>{l}</a>)}
      </div>
      <Panel>
        <Load got={list} empty={(d) => (d.items.length ? null : "No conversations yet. Open a community's Members tab to message someone.")}>
          {(d) => d.items.map((c) => (
            <Link className="row" key={c.id} href={`/messages/${c.id}`}>
              <Avatar user={c.participant} />
              <span className="grow">
                <b>{c.participant.full_name}{c.kind === "mentor" ? <span className="tag">Mentor</span> : null}</b>
                <small style={{ fontWeight: c.unread_count ? 700 : 400, color: c.unread_count ? "var(--ink)" : undefined }}>{c.last_message || "No messages yet"}</small>
              </span>
              <span style={{ textAlign: "right" }}>
                <small className="meta">{timeAgo(c.last_message_at)}</small>
                {c.unread_count ? <span className="badge" style={{ display: "block", marginTop: 4 }}>{c.unread_count}</span> : null}
              </span>
            </Link>
          ))}
        </Load>
      </Panel>
    </>
  );
}
