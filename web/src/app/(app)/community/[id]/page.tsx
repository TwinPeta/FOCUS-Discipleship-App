"use client";

import Link from "next/link";
import { useParams, useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { FeedTab } from "@/components/community/FeedTab";
import { ManageTab } from "@/components/community/ManageTab";
import { MeetingsTab } from "@/components/community/MeetingsTab";
import { MembersTab } from "@/components/community/MembersTab";
import { PrayerTab } from "@/components/community/PrayerTab";
import { ResourcesTab } from "@/components/community/ResourcesTab";
import { TestimoniesTab } from "@/components/community/TestimoniesTab";
import { Avatar, Confirm, ErrorText, Load, Panel } from "@/components/ui";
import { del, post } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { meetingText, plural, ROLE_LABEL } from "@/lib/format";
import { useAction, useGet } from "@/lib/hooks";
import type { Community } from "@/lib/types";

const TABS: [string, string][] = [["feed", "Feed"], ["prayer", "Prayer"], ["testimonies", "Testimonies"], ["resources", "Resources"], ["meetings", "Meetings"], ["members", "Members"]];

function View() {
  const { id } = useParams<{ id: string }>();
  const tab = useSearchParams().get("tab") || "feed";
  const { user } = useAuth();
  const got = useGet<Community>(`/communities/${id}`);
  const join = useAction();
  const [leaving, setLeaving] = useState(false);

  return (
    <Load got={got} rows={5}>
      {(c) => {
        const me = c.leadership.find((l) => l.id === user?.id);
        const isSuper = me?.community_role === "super_mentor";
        const member = c.membership_status === "member";
        const tabs = isSuper ? [...TABS, ["manage", "Manage"] as [string, string]] : TABS;
        return (
          <>
            <section className="comm-head">
              <Link className="back" href="/community" style={{ marginBottom: 0 }}><i className="bx bx-arrow-back" aria-hidden="true" /> Communities</Link>
              <h1>{c.name}</h1>
              <p className="meta">
                {c.type === "general" ? "General community" : "Specific community"}{c.institution ? ` · ${c.institution.name}` : ""} · {plural(c.members_count, "member")}
                {meetingText(c.meeting) ? ` · Meets ${meetingText(c.meeting)}` : ""}
              </p>
              {c.description ? <p>{c.description}</p> : null}
              <ErrorText>{join.error}</ErrorText>
              <div className="actions">
                {member ? <span className="pill ok">You are a member</span>
                  : c.membership_status === "pending" ? <span className="pill">Waiting for approval</span>
                  : c.can_request ? (
                    <button className="btn btn-dark btn-sm" disabled={join.busy} onClick={() => join.run(async () => { await post(`/communities/${c.id}/join-requests`, {}); await got.reload(); })}>
                      Ask to join
                    </button>
                  ) : c.type === "specific" ? <span className="pill">You already have a specific community</span> : null}
                {member && c.type === "specific" && !isSuper ? <button className="link-btn" onClick={() => setLeaving(true)}>Leave community</button> : null}
              </div>
            </section>
            {member ? (
              <>
                <nav className="tabs" aria-label="Community sections">
                  {tabs.map(([v, l]) => <Link key={v} href={`/community/${c.id}?tab=${v}`} aria-current={tab === v ? "page" : undefined} scroll={false}>{l}</Link>)}
                </nav>
                {tab === "prayer" ? <PrayerTab communityId={c.id} />
                  : tab === "testimonies" ? <TestimoniesTab communityId={c.id} />
                  : tab === "resources" ? <ResourcesTab communityId={c.id} />
                  : tab === "meetings" ? <MeetingsTab communityId={c.id} />
                  : tab === "members" ? <MembersTab communityId={c.id} />
                  : tab === "manage" && isSuper ? <ManageTab communityId={c.id} />
                  : <FeedTab communityId={c.id} isLeader={!!me} />}
              </>
            ) : (
              <Panel title="Leaders">
                {c.leadership.length ? c.leadership.map((l) => (
                  <div className="row" key={l.id}>
                    <Avatar user={l} />
                    <span className="grow"><b>{l.full_name}</b><small>{ROLE_LABEL[l.community_role || "member"]}</small></span>
                  </div>
                )) : <p className="empty-box">No leaders listed yet.</p>}
                <p className="meta" style={{ marginTop: 12 }}>The feed, prayer wall and resources open once you are a member.</p>
              </Panel>
            )}
            {leaving ? (
              <Confirm title={`Leave ${c.name}?`} body="You will lose access to its feed, prayer wall and resources. You can ask to join a community again later."
                confirmLabel="Leave" onClose={() => setLeaving(false)} onConfirm={async () => { await del(`/communities/${c.id}/membership`); await got.reload(); }} />
            ) : null}
          </>
        );
      }}
    </Load>
  );
}

export default function CommunityPage() {
  return <Suspense><View /></Suspense>;
}
