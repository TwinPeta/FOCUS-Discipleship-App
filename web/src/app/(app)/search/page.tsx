"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { Avatar, ErrorText, PageTitle, Panel, Skeleton } from "@/components/ui";
import { api, messageOf, post } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { meetingText, ROLE_LABEL } from "@/lib/format";
import { useAction } from "@/lib/hooks";
import type { CommunitySummary, Conversation, MyCommunities, Page, UserRef } from "@/lib/types";

type Results = { communities: CommunitySummary[]; people: UserRef[] };

/**
 * Communities on the student's campus and people in the communities they belong to: the same scope as the mobile
 * app's search. Communities are matched by the API; people are matched here from the member lists.
 */
async function search(term: string, myId: string): Promise<Results> {
  const q = term.toLowerCase();
  const [found, mine, blocks] = await Promise.all([
    api<Page<CommunitySummary>>(`/communities?limit=50&q=${encodeURIComponent(term)}`),
    api<MyCommunities>("/me/communities"),
    api<{ items: UserRef[] }>("/me/blocks"),
  ]);
  const ids = [mine.general, mine.specific].filter((m) => m?.membership_status === "member").map((m) => m!.community.id);
  const rosters = await Promise.all(ids.map((id) => api<Page<UserRef>>(`/communities/${id}/members?limit=100`).catch(() => ({ items: [] as UserRef[], next_cursor: null }))));
  const hidden = new Set([myId, ...blocks.items.map((b) => b.id)]);
  const seen = new Set<string>();
  const people = rosters.flatMap((r) => r.items)
    .filter((m) => !hidden.has(m.id) && !seen.has(m.id) && seen.add(m.id) && (m.full_name.toLowerCase().includes(q) || m.username.toLowerCase().includes(q.replace(/^@/, ""))))
    .sort((a, b) => a.full_name.localeCompare(b.full_name));
  return { communities: found.items, people };
}

export default function SearchPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [q, setQ] = useState("");
  const [term, setTerm] = useState("");
  const [results, setResults] = useState<Results | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const msg = useAction();

  useEffect(() => {
    if (!term || !user) { setResults(null); return; }
    let live = true;
    setLoading(true);
    setError("");
    search(term, user.id)
      .then((r) => live && setResults(r))
      .catch((e) => live && setError(messageOf(e)))
      .finally(() => live && setLoading(false));
    return () => { live = false; };
  }, [term, user]);

  return (
    <>
      <PageTitle title="Search" sub="Find communities on your campus and people in your communities." />
      <form className="search" style={{ marginTop: 0 }} role="search" onSubmit={(e) => { e.preventDefault(); setTerm(q.trim()); }}>
        <label className="sr-only" htmlFor="sq">Search</label>
        <input id="sq" type="search" autoFocus placeholder="A name, a community, a meeting day" value={q} onChange={(e) => { setQ(e.target.value); if (!e.target.value.trim()) setTerm(""); }} />
        <button className="btn btn-primary btn-sm" type="submit" disabled={!q.trim()}>Search</button>
      </form>
      <ErrorText>{error || msg.error}</ErrorText>
      {loading && !results ? <Panel><Skeleton /></Panel> : null}
      {results ? (
        <div aria-live="polite" className="list-stack">
          <Panel title={`Communities (${results.communities.length})`}>
            {results.communities.length ? results.communities.map((c) => (
              <Link className="row" key={c.id} href={`/community/${c.id}`}>
                <span className="avatar" aria-hidden="true">{c.initials}</span>
                <span className="grow">
                  <b>{c.name}</b>
                  <small>{[c.type === "general" ? "General community" : "Specific community", meetingText(c.meeting)].filter(Boolean).join(" · ")}</small>
                </span>
                {c.membership_status === "member" ? <span className="pill ok">Member</span> : c.membership_status === "pending" ? <span className="pill">Requested</span> : null}
              </Link>
            )) : <p className="empty-box">No community matches “{term}”.</p>}
          </Panel>
          <Panel title={`People (${results.people.length})`}>
            {results.people.length ? results.people.map((m) => (
              <div className="row" key={m.id}>
                <Avatar user={m} />
                <span className="grow"><b>{m.full_name}</b><small>@{m.username}{m.community_role && m.community_role !== "member" ? ` · ${ROLE_LABEL[m.community_role]}` : ""}</small></span>
                <button className="btn btn-sm" disabled={msg.busy} onClick={() => msg.run(async () => {
                  const c = await post<Conversation>("/conversations", { user_id: m.id });
                  router.push(`/messages/${c.id}`);
                })}>Message</button>
              </div>
            )) : <p className="empty-box">No one in your communities matches “{term}”.</p>}
          </Panel>
        </div>
      ) : !loading && !term ? <p className="empty-box">Type a name or a community and press Search.</p> : null}
    </>
  );
}
