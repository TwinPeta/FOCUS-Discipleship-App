"use client";

import Link from "next/link";
import { ErrorText, Load, MoreButton, PageTitle, Panel } from "@/components/ui";
import { post } from "@/lib/api";
import { timeAgo, webRoute } from "@/lib/format";
import { onNotification, useRealtime } from "@/lib/realtime";
import { useAction, useGet } from "@/lib/hooks";
import type { Notification, Page } from "@/lib/types";

export default function Notifications() {
  const path = "/me/notifications?limit=30";
  const got = useGet<Page<Notification> & { unread_count: number }>(path, onNotification);
  const act = useAction();
  const { publish } = useRealtime();
  const read = (n: Notification) => {
    if (n.read_at) return;
    got.setData((d) => (d ? { ...d, unread_count: Math.max(0, d.unread_count - 1), items: d.items.map((x) => (x.id === n.id ? { ...x, read_at: new Date().toISOString() } : x)) } : d));
    post(`/me/notifications/${n.id}/read`, {}).then(() => publish({ event: "local.notifications", data: {} })).catch(() => undefined);
  };
  return (
    <>
      <PageTitle title="Notifications" action={got.data?.unread_count ? (
        <button className="btn btn-sm" disabled={act.busy} onClick={() => act.run(async () => { await post("/me/notifications/read-all", {}); publish({ event: "local.notifications", data: {} }); })}>Mark all as read</button>
      ) : null} />
      <ErrorText>{act.error}</ErrorText>
      <Panel>
        <Load got={got} empty={(d) => (d.items.length ? null : "You have no notifications yet.")}>
          {(d) => (
            <>
              {d.items.map((n) => {
                const to = webRoute(n.target_route);
                const body = (
                  <>
                    {n.read_at ? <span style={{ width: 10 }} /> : <span className="dot" aria-label="Unread" />}
                    <span className="grow">
                      <b style={{ fontWeight: n.read_at ? 500 : 700, whiteSpace: "normal" }}>{n.title}</b>
                      {n.body ? <small style={{ whiteSpace: "normal" }}>{n.body}</small> : null}
                      <small>{timeAgo(n.created_at)}</small>
                    </span>
                  </>
                );
                return to
                  ? <Link className="row" key={n.id} href={to} onClick={() => read(n)}>{body}</Link>
                  : <div className="row" key={n.id}>{body}{n.read_at ? null : <button className="link-btn" onClick={() => read(n)}>Mark read</button>}</div>;
              })}
              <MoreButton<Notification> got={d} path={path} onMore={(pg) => got.setData((cur) => (cur ? { ...cur, items: [...cur.items, ...pg.items], next_cursor: pg.next_cursor } : cur))} />
            </>
          )}
        </Load>
      </Panel>
    </>
  );
}
