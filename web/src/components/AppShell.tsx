"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect } from "react";
import { post } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { onNotification, onMessage } from "@/lib/realtime";
import { useAction, useGet } from "@/lib/hooks";
import { Avatar } from "./ui";

const NAV: { href: string; label: string; icon: string; match: string[] }[] = [
  { href: "/dashboard", label: "Home", icon: "bx-home-alt", match: ["/dashboard"] },
  { href: "/community", label: "Community", icon: "bx-group", match: ["/community", "/post", "/prayer", "/testimony"] },
  { href: "/pathways", label: "Learn", icon: "bx-book-open", match: ["/pathways", "/resources", "/quiz"] },
  { href: "/messages", label: "Messages", icon: "bx-message-rounded-dots", match: ["/messages"] },
  { href: "/notifications", label: "Alerts", icon: "bx-bell", match: ["/notifications"] },
  { href: "/profile", label: "Profile", icon: "bx-user", match: ["/profile", "/settings"] },
];

type Warning = { id: string; reason: string; preview: string; acknowledged: boolean };

/** Frame for every signed-in page: navigation, unread counts, and any warning or suspension the student must see. */
export function AppShell({ children }: { children: React.ReactNode }) {
  const { status, user } = useAuth();
  const router = useRouter();
  const path = usePathname();
  const ready = status === "signedIn";

  useEffect(() => {
    if (status === "signedOut") router.replace(`/login`);
  }, [status, router]);

  const notes = useGet<{ unread_count: number }>(ready ? "/me/notifications?limit=1" : null, onNotification);
  const chats = useGet<{ unread_total: number }>(ready ? "/conversations?limit=1" : null, onMessage);
  const warnings = useGet<{ items: Warning[] }>(ready ? "/me/warnings" : null);
  const suspension = useGet<{ suspension: { reason: string; until: string | null } | null }>(ready ? "/me/suspension" : null);
  const ack = useAction();

  if (!ready) return <div className="app-loading" aria-busy="true" />;

  const counts: Record<string, number> = { "/messages": chats.data?.unread_total || 0, "/notifications": notes.data?.unread_count || 0 };
  const open = warnings.data?.items.filter((w) => !w.acknowledged) || [];
  const s = suspension.data?.suspension;

  return (
    <div className="app">
      <header className="site-header">
        <div className="wrap">
          <Link href="/dashboard" className="logo" aria-label="FCU Student Community, home">
            <span className="logo-mark" aria-hidden="true">FCU</span>
            <span className="logo-text">Student Community</span>
          </Link>
          <Link href="/search" className="btn btn-sm header-search" aria-label="Search"><i className="bx bx-search" aria-hidden="true" /><span className="me-name">Search</span></Link>
          <Link href="/profile" className="me-chip" aria-label="Your profile">
            <span className="me-name">{user?.full_name.split(" ")[0]}</span>
            <Avatar user={user} size={38} />
          </Link>
        </div>
      </header>
      <div className="wrap app-body">
        <nav className="app-nav" aria-label="Main">
          {NAV.map((n) => {
            const active = n.match.some((m) => path === m || path.startsWith(`${m}/`));
            const count = counts[n.href] || 0;
            return (
              <Link key={n.href} href={n.href} className={active ? "active" : undefined} aria-current={active ? "page" : undefined}>
                <i className={`bx ${n.icon} nav-icon`} aria-hidden="true" />
                <span className="nav-label">{n.label}</span>
                {count ? <span className="badge" aria-label={`${count} unread`}>{count > 99 ? "99+" : count}</span> : null}
              </Link>
            );
          })}
        </nav>
        <main className="app-main">
          {s ? (
            <div className="notice danger" role="alert">
              <b>Your account is suspended{s.until ? ` until ${new Date(s.until).toLocaleDateString(undefined, { day: "numeric", month: "long" })}` : ""}.</b>{" "}
              You can still read, but you cannot post, message or join until it ends.{s.reason ? ` Reason: ${s.reason}.` : ""}
            </div>
          ) : null}
          {open.map((w) => (
            <div className="notice danger" role="alert" key={w.id}>
              <b>A moderator sent you a warning{w.reason ? `: ${w.reason}` : ""}.</b>
              {w.preview ? <p className="quote">“{w.preview}”</p> : null}
              <button className="btn btn-sm" disabled={ack.busy} onClick={() => ack.run(async () => { await post(`/me/warnings/${w.id}/acknowledge`, {}); await warnings.reload(); })}>
                I understand
              </button>
            </div>
          ))}
          {user?.minor_status === "pending_guardian_consent" && !path.startsWith("/settings") ? (
            <div className="notice">
              Your account is limited until a parent or guardian gives consent. <Link href="/settings#guardian">Add your guardian&apos;s details</Link>.
            </div>
          ) : null}
          {children}
        </main>
      </div>
    </div>
  );
}
