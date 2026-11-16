"use client";

import Link from "next/link";
import { DownloadButtons } from "@/components/HeroActions";
import { Load, Panel } from "@/components/ui";
import { useAuth } from "@/lib/auth";
import { plural, timeAgo, webRoute } from "@/lib/format";
import { useGet } from "@/lib/hooks";
import type { MyCommunities, MyCommunity, Notification, Page, PathwaySummary, Post } from "@/lib/types";

function CommunityRow({ label, m }: { label: string; m: MyCommunity }) {
  if (!m) return null;
  const member = m.membership_status === "member";
  return (
    <Link className="row" href={member ? `/community/${m.community.id}` : "/community"}>
      <span className="avatar" aria-hidden="true">{m.community.initials}</span>
      <span className="grow">
        <b>{m.community.name}</b>
        <small>{label}{m.community.super_mentor ? ` · led by ${m.community.super_mentor.full_name}` : ""}</small>
      </span>
      <span className={member ? "pill ok" : "pill"}>{member ? "Member" : "Waiting for approval"}</span>
    </Link>
  );
}

export default function Dashboard() {
  const { user } = useAuth();
  const communities = useGet<MyCommunities>("/me/communities");
  const notifications = useGet<Page<Notification>>("/me/notifications?limit=5");
  const pathways = useGet<{ current: PathwaySummary | null; items: PathwaySummary[] }>("/pathways");
  const general = communities.data?.general;
  const generalId = general?.membership_status === "member" ? general.community.id : "";
  const posts = useGet<Page<Post>>(generalId ? `/communities/${generalId}/posts?limit=5` : null);
  const first = user?.full_name.split(" ")[0];

  return (
    <>
      <section className="comm-head">
        <h1>{first ? `Hello, ${first}` : "Hello"}</h1>
        <p className="meta">{user?.institution ? user.institution.name : "Your student community"}{user ? ` · @${user.username}` : ""}</p>
      </section>
      <div className="dash-grid">
        <div className="list-stack">
          <Panel title="Your communities" action={<Link className="btn btn-sm" href="/community">See all</Link>}>
            <Load got={communities} empty={(d) => (!d.general && !d.specific ? "You are not in a community yet." : null)}>
              {(d) => (
                <>
                  <CommunityRow label="General community" m={d.general} />
                  <CommunityRow label="Specific community" m={d.specific} />
                  {!d.specific ? (
                    <p className="meta" style={{ marginTop: 12 }}>
                      You have not joined a specific community yet. <Link href="/community">Find one to join</Link>.
                    </p>
                  ) : null}
                </>
              )}
            </Load>
          </Panel>
          <Panel title="Latest from your campus" action={generalId ? <Link className="btn btn-sm" href={`/community/${generalId}`}>Open feed</Link> : null}>
            {communities.data && !generalId ? <p className="empty-box">Posts appear here once you are in your campus community.</p> : (
              <Load got={posts} empty={(d) => (d.items.length ? null : "No posts yet.")}>
                {(d) => d.items.map((p) => (
                  <Link className="row" key={p.id} href={`/post/${p.id}`}>
                    <span className="grow">
                      <small>{p.author?.full_name || "A member"} · {timeAgo(p.created_at)}{p.pinned ? " · Pinned" : ""}</small>
                      <b>{p.text}</b>
                      <small>{plural(p.like_count, "like")} · {plural(p.comment_count, "comment")}</small>
                    </span>
                  </Link>
                ))}
              </Load>
            )}
          </Panel>
        </div>
        <div className="list-stack">
          <Panel title="Your pathway" action={<Link className="btn btn-sm" href="/pathways">All pathways</Link>}>
            <Load got={pathways}>
              {(d) => {
                const p = d.current || d.items.find((x) => x.status === "available");
                if (!p) return <p className="empty-box">No pathway to continue right now.</p>;
                return (
                  <Link className="row" href={`/pathways/${p.id}`}>
                    <span className="grow">
                      <b>{p.title}</b>
                      <small>{p.steps_completed} of {p.steps_total} steps done</small>
                      <span className="bar"><span style={{ width: `${p.steps_total ? (100 * p.steps_completed) / p.steps_total : 0}%` }} /></span>
                    </span>
                  </Link>
                );
              }}
            </Load>
          </Panel>
          <Panel title="Notifications" action={<Link className="btn btn-sm" href="/notifications">See all</Link>}>
            <Load got={notifications} empty={(d) => (d.items.length ? null : "Nothing new.")}>
              {(d) => d.items.slice(0, 5).map((n) => {
                const body = (
                  <span className="grow">
                    <b style={{ fontWeight: n.read_at ? 500 : 700 }}>{n.title}</b>
                    <small>{timeAgo(n.created_at)}</small>
                  </span>
                );
                const to = webRoute(n.target_route);
                return to ? <Link className="row" key={n.id} href={to}>{body}</Link> : <div className="row" key={n.id}>{body}</div>;
              })}
            </Load>
          </Panel>
          <section className="panel get-app">
            <h2>Take it with you</h2>
            <p>Get notifications on your phone with the mobile app. It uses this same account.</p>
            <div className="cta-row" style={{ marginTop: 0 }}><DownloadButtons /></div>
          </section>
        </div>
      </div>
    </>
  );
}
