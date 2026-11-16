"use client";

import Link from "next/link";
import { Avatar, Load, PageTitle, Panel } from "@/components/ui";
import { useAuth } from "@/lib/auth";
import { timeAgo } from "@/lib/format";
import { useGet } from "@/lib/hooks";
import type { Badge } from "@/lib/types";

type Activity = { badges: Badge[]; recent: { items: { id: string; label: string; occurred_at: string }[] } };

export default function ProfilePage() {
  const { user, signOut } = useAuth();
  const activity = useGet<Activity>("/me/activity?limit=15");
  return (
    <>
      <PageTitle title="Profile" action={<span className="row-actions"><Link className="btn btn-sm" href="/settings">Settings</Link><button className="btn btn-sm" onClick={() => signOut()}>Log out</button></span>} />
      <Panel>
        <div className="row">
          <Avatar user={user} size={72} />
          <span className="grow">
            <b style={{ fontSize: 22 }}>{user?.full_name}</b>
            <small>@{user?.username}{user?.institution ? ` · ${user.institution.name}` : ""}</small>
            <small>{[user?.email, user?.phone].filter(Boolean).join(" · ")}</small>
          </span>
        </div>
      </Panel>
      <Panel title="Badges">
        <Load got={activity} empty={(d) => (d.badges.length ? null : "No badges yet.")}>
          {(d) => (
            <div className="badges">
              {d.badges.map((b) => (
                <div key={b.id} className={b.earned ? "badge-card" : "badge-card locked"}>
                  <i className={`bx ${b.earned ? "bxs-medal" : "bx-lock-alt"}`} aria-hidden="true" />{b.name}
                  <small className="sr-only">{b.earned ? "earned" : "not earned yet"}</small>
                </div>
              ))}
            </div>
          )}
        </Load>
      </Panel>
      <Panel title="Recent activity">
        <Load got={activity} empty={(d) => (d.recent.items.length ? null : "Your activity will show here.")}>
          {(d) => d.recent.items.map((e) => (
            <div className="row" key={e.id}><span className="grow"><b style={{ fontWeight: 500 }}>{e.label}</b><small>{timeAgo(e.occurred_at)}</small></span></div>
          ))}
        </Load>
      </Panel>
    </>
  );
}
