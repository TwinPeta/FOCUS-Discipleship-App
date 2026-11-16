"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import { DownloadButtons } from "@/components/HeroActions";
import { SiteHeader } from "@/components/SiteHeader";
import { api } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import type { MyCommunities, MyCommunity, Notification, PathwaySummary, Post } from "@/lib/types";

type Loaded<T> = { state: "loading" } | { state: "error" } | { state: "ready"; data: T };

function useLoad<T>(enabled: boolean, load: () => Promise<T>, key: string): Loaded<T> {
  const [v, setV] = useState<Loaded<T>>({ state: "loading" });
  useEffect(() => {
    if (!enabled) return;
    let live = true;
    setV({ state: "loading" });
    load().then((data) => live && setV({ state: "ready", data })).catch(() => live && setV({ state: "error" }));
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, key]);
  return v;
}

const when = (iso: string) => new Date(iso).toLocaleDateString(undefined, { day: "numeric", month: "short" });

const Skeleton = () => (<div aria-hidden="true"><div className="skeleton" /><div className="skeleton" style={{ width: "70%" }} /></div>);
const Failed = () => <p className="empty">Could not load this. Refresh the page to try again.</p>;

function CommunityRow({ label, m }: { label: string; m: MyCommunity }) {
  if (!m) return null;
  return (
    <div className="comm">
      <div className="avatar" aria-hidden="true">{m.community.initials}</div>
      <div>
        <b>{m.community.name}</b>
        <small>{label}{m.community.super_mentor ? ` · led by ${m.community.super_mentor.full_name}` : ""}</small>
      </div>
      <span className={m.membership_status === "member" ? "pill ok" : "pill"}>
        {m.membership_status === "member" ? "Member" : "Waiting for approval"}
      </span>
    </div>
  );
}

export default function Dashboard() {
  const { status, user } = useAuth();
  const router = useRouter();
  const ready = status === "signedIn";

  useEffect(() => {
    if (status === "signedOut") router.replace("/login");
  }, [status, router]);

  const communities = useLoad(ready, () => api<MyCommunities>("/me/communities"), "c");
  const notifications = useLoad(ready, () => api<{ items: Notification[] }>("/me/notifications?limit=5"), "n");
  const pathways = useLoad(ready, () => api<{ current: PathwaySummary | null; items: PathwaySummary[] }>("/pathways"), "p");
  const generalId =
    communities.state === "ready" && communities.data.general?.membership_status === "member" ? communities.data.general.community.id : "";
  const posts = useLoad(ready && !!generalId, () => api<{ items: Post[] }>(`/communities/${generalId}/posts?limit=5`), generalId);

  if (!ready) return <SiteHeader />;

  const first = user?.full_name.split(" ")[0];
  const pathway = pathways.state === "ready" ? pathways.data.current || pathways.data.items.find((p) => p.status === "available") || null : null;

  return (
    <>
      <SiteHeader variant="dashboard" />
      <main>
        <section className="dash-hero">
          <div className="wrap">
            <h1>{first ? `Hello, ${first}` : "Hello"}</h1>
            <p>{user?.institution ? user.institution.name : "Your student community"}{user ? ` · @${user.username}` : ""}</p>
          </div>
        </section>
        <div className="wrap dash">
          <div className="stack">
            {user?.minor_status === "pending_guardian_consent" ? (
              <p className="notice">Your account is limited until a parent or guardian gives consent. Add their details in the mobile app.</p>
            ) : null}
            <section className="panel" aria-labelledby="h-comm">
              <h2 id="h-comm">Your communities</h2>
              {communities.state === "loading" ? <Skeleton /> : communities.state === "error" ? <Failed /> : (
                <>
                  <CommunityRow label="General community" m={communities.data.general} />
                  <CommunityRow label="Specific community" m={communities.data.specific} />
                  {!communities.data.general && !communities.data.specific ? <p className="empty">You are not in a community yet.</p> : null}
                  {!communities.data.specific ? (
                    <p className="meta" style={{ marginTop: 12 }}>You have not joined a specific community yet. Pick one in the mobile app.</p>
                  ) : null}
                </>
              )}
            </section>
            <section className="panel" aria-labelledby="h-feed">
              <h2 id="h-feed">Latest from your campus</h2>
              {communities.state === "ready" && !generalId ? <p className="empty">Posts appear here once you are in your campus community.</p>
                : posts.state === "loading" ? <Skeleton /> : posts.state === "error" ? <Failed />
                : posts.data.items.length === 0 ? <p className="empty">No posts yet.</p>
                : posts.data.items.map((p) => (
                  <article className="item" key={p.id}>
                    <p className="meta">{p.author?.full_name || "A member"} · {when(p.created_at)}{p.pinned ? " · Pinned" : ""}</p>
                    <p>{p.text}</p>
                    <p className="meta">{p.like_count} {p.like_count === 1 ? "like" : "likes"} · {p.comment_count} {p.comment_count === 1 ? "comment" : "comments"}</p>
                  </article>
                ))}
            </section>
          </div>
          <div className="stack">
            <section className="panel" aria-labelledby="h-path">
              <h2 id="h-path">Your pathway</h2>
              {pathways.state === "loading" ? <Skeleton /> : pathways.state === "error" ? <Failed /> : !pathway ? <p className="empty">No pathway to continue right now.</p> : (
                <>
                  <b>{pathway.title}</b>
                  <p className="meta">{pathway.steps_completed} of {pathway.steps_total} steps done</p>
                  <div className="bar" role="progressbar" aria-label={`${pathway.title} progress`} aria-valuemin={0} aria-valuemax={pathway.steps_total} aria-valuenow={pathway.steps_completed}>
                    <span style={{ width: `${pathway.steps_total ? (100 * pathway.steps_completed) / pathway.steps_total : 0}%` }} />
                  </div>
                </>
              )}
            </section>
            <section className="panel" aria-labelledby="h-notif">
              <h2 id="h-notif">Notifications</h2>
              {notifications.state === "loading" ? <Skeleton /> : notifications.state === "error" ? <Failed />
                : notifications.data.items.length === 0 ? <p className="empty">Nothing new.</p>
                : notifications.data.items.slice(0, 5).map((n) => (
                  <div className="item" key={n.id}>
                    <p className={n.read_at ? undefined : "unread"}>{n.title}</p>
                    {n.body ? <p className="meta">{n.body}</p> : null}
                    <p className="meta">{when(n.created_at)}</p>
                  </div>
                ))}
            </section>
            <section className="panel get-app" aria-labelledby="h-app">
              <h2 id="h-app">Get the full experience</h2>
              <p>Post, pray, message your group and get notifications in the mobile app.</p>
              <div className="cta-row" style={{ marginTop: 0 }}><DownloadButtons /></div>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
