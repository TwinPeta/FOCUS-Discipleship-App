"use client";

import Link from "next/link";
import { useState } from "react";
import { Load, MoreButton, Panel } from "@/components/ui";
import { useGet } from "@/lib/hooks";
import type { Page, Resource } from "@/lib/types";

const TYPES: [string, string][] = [["", "All"], ["video", "Videos"], ["devotional", "Devotionals"], ["document", "Documents"], ["quiz", "Quizzes"]];
const ICON: Record<string, string> = { video: "bx-video", devotional: "bx-book-open", document: "bx-file", quiz: "bx-edit" };

export const resourceHref = (r: { id: string; type: string }) => (r.type === "quiz" ? `/quiz/${r.id}` : `/resources/${r.id}`);

export function resourceMeta(r: Resource): string {
  if (r.type === "video" && r.duration_seconds) return `${Math.max(1, Math.round(r.duration_seconds / 60))} min video`;
  if (r.type === "devotional") return r.read_minutes ? `${r.read_minutes} min read` : "Devotional";
  if (r.type === "quiz") return r.question_count ? `${r.question_count} questions` : "Quiz";
  return r.type === "document" ? "Document" : "Video";
}

export function ResourcesTab({ communityId }: { communityId: string }) {
  const [type, setType] = useState("");
  const [q, setQ] = useState("");
  const [term, setTerm] = useState("");
  const path = `/communities/${communityId}/resources?limit=30${type ? `&type=${type}` : ""}${term ? `&q=${encodeURIComponent(term)}` : ""}`;
  const list = useGet<Page<Resource>>(path);
  return (
    <Panel title="Resources">
      <form className="search" style={{ marginTop: 0, marginBottom: 12 }} role="search" onSubmit={(e) => { e.preventDefault(); setTerm(q.trim()); }}>
        <label className="sr-only" htmlFor="rq">Search resources</label>
        <input id="rq" type="search" placeholder="Search resources" value={q} onChange={(e) => { setQ(e.target.value); if (!e.target.value) setTerm(""); }} />
        <button className="btn btn-sm" type="submit">Search</button>
      </form>
      <div className="tabs" role="group" aria-label="Filter by type" style={{ marginBottom: 12 }}>
        {TYPES.map(([v, l]) => (
          <a key={v} href="#" aria-current={type === v ? "page" : undefined} onClick={(e) => { e.preventDefault(); setType(v); }}>{l}</a>
        ))}
      </div>
      <Load got={list} empty={(d) => (d.items.length ? null : "No resources here yet.")}>
        {(d) => (
          <>
            {d.items.map((r) => (
              <Link className="row" key={r.id} href={resourceHref(r)}>
                <span className="avatar"><i className={`bx ${ICON[r.type] || "bx-file"}`} aria-hidden="true" /></span>
                <span className="grow"><b>{r.title}</b><small>{resourceMeta(r)}{r.added_by ? ` · from ${r.added_by.full_name}` : ""}</small></span>
                {r.my_progress.completed ? <span className="pill ok">Done</span> : null}
              </Link>
            ))}
            <MoreButton<Resource> got={d} path={path} onMore={(pg) => list.setData((cur) => (cur ? { items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
          </>
        )}
      </Load>
    </Panel>
  );
}
