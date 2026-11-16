"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { ApiError, postOnce, uploadImage, messageOf, type Purpose } from "@/lib/api";
import { initialsOf, timeAgo, ROLE_LABEL } from "@/lib/format";
import { useAction, type Got } from "@/lib/hooks";
import type { UserRef } from "@/lib/types";

export function Avatar({ user, size = 44 }: { user: { full_name?: string; photo_url?: string | null } | null; size?: number }) {
  const style = { width: size, height: size, fontSize: Math.round(size * 0.36) };
  return user?.photo_url ? (
    // eslint-disable-next-line @next/next/no-img-element
    <img className="avatar round" style={style} src={user.photo_url} alt="" />
  ) : (
    <span className="avatar round" style={style} aria-hidden="true">{user ? initialsOf(user.full_name) : "?"}</span>
  );
}

/** Author line used by posts, comments, prayer requests and messages. A null user is an anonymous author. */
export function Byline({ user, at, extra }: { user: UserRef | null; at?: string | null; extra?: React.ReactNode }) {
  const role = user?.community_role && user.community_role !== "member" ? ROLE_LABEL[user.community_role] : null;
  return (
    <div className="byline">
      <Avatar user={user} size={40} />
      <div>
        <b>{user ? user.full_name : "Anonymous"}{role ? <span className="tag">{role}</span> : null}</b>
        <small>{at ? timeAgo(at) : ""}{extra}</small>
      </div>
    </div>
  );
}

export const Skeleton = ({ rows = 3 }: { rows?: number }) => (
  <div aria-hidden="true">{Array.from({ length: rows }, (_, i) => <div key={i} className="skeleton" style={{ width: `${95 - i * 14}%` }} />)}</div>
);

/** Loading, error and empty handling for one loaded list or record. */
export function Load<T>({ got, empty, children, rows }: { got: Got<T>; empty?: (d: T) => string | null; children: (d: T) => React.ReactNode; rows?: number }) {
  if (got.data === undefined) {
    if (got.error) {
      return (
        <div className="empty-box" role="alert">
          <p>{got.error.status === 404 ? "This is no longer available." : got.error.status === 403 ? got.error.message : "Could not load this."}</p>
          {got.error.status === 404 || got.error.status === 403 ? null : <button className="btn btn-sm" onClick={() => got.reload()}>Try again</button>}
        </div>
      );
    }
    return <Skeleton rows={rows} />;
  }
  const none = empty?.(got.data);
  return none ? <p className="empty-box">{none}</p> : <>{children(got.data)}</>;
}

export const ErrorText = ({ children }: { children?: string }) => (children ? <p className="err" role="alert">{children}</p> : null);

export function Panel({ title, action, children }: { title?: string; action?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="panel">
      {title || action ? <div className="panel-head">{title ? <h2>{title}</h2> : <span />}{action}</div> : null}
      {children}
    </section>
  );
}

export function PageTitle({ title, sub, back, action }: { title: string; sub?: React.ReactNode; back?: { href: string; label: string }; action?: React.ReactNode }) {
  return (
    <div className="page-title">
      {back ? <Link className="back" href={back.href}><i className="bx bx-arrow-back" aria-hidden="true" /> {back.label}</Link> : null}
      <div className="page-title-row">
        <div><h1>{title}</h1>{sub ? <p>{sub}</p> : null}</div>
        {action}
      </div>
    </div>
  );
}

/** Text box with an optional photo, used for posts, comments, prayer responses and messages. */
export function Composer({
  placeholder, label, submitLabel, max, photos, onSubmit, extra, rows = 2,
}: {
  placeholder: string; label: string; submitLabel: string; max: number; rows?: number;
  photos?: Purpose; extra?: React.ReactNode;
  onSubmit: (text: string, mediaIds: string[]) => Promise<unknown>;
}) {
  const [text, setText] = useState("");
  const [files, setFiles] = useState<File[]>([]);
  const { busy, error, run, setError } = useAction();
  const input = useRef<HTMLInputElement>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const body = text.trim();
    if (!body) return;
    const ok = await run(async () => {
      const ids: string[] = [];
      for (const f of files) ids.push(await uploadImage(f, photos!));
      await onSubmit(body, ids);
    });
    if (ok) { setText(""); setFiles([]); }
  }

  function pick(list: FileList | null) {
    const next = [...files, ...Array.from(list || [])];
    if (next.some((f) => f.size > 10 * 1024 * 1024)) return setError("Each photo must be 10 MB or smaller.");
    if (next.length > 4) return setError("You can add up to 4 photos.");
    setError("");
    setFiles(next);
  }

  return (
    <form className="composer" onSubmit={submit}>
      <label className="sr-only" htmlFor={`c-${label}`}>{label}</label>
      <textarea id={`c-${label}`} rows={rows} maxLength={max} placeholder={placeholder} value={text} onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => { if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) submit(e); }} />
      {files.length ? (
        <ul className="chips">
          {files.map((f, i) => (
            <li key={i}>{f.name}<button type="button" aria-label={`Remove ${f.name}`} onClick={() => setFiles(files.filter((_, j) => j !== i))}><i className="bx bx-x" aria-hidden="true" /></button></li>
          ))}
        </ul>
      ) : null}
      <ErrorText>{error}</ErrorText>
      <div className="composer-row">
        <div className="composer-extra">
          {photos ? (
            <>
              <input ref={input} type="file" accept="image/jpeg,image/png,image/webp" multiple hidden onChange={(e) => { pick(e.target.files); e.target.value = ""; }} />
              <button type="button" className="btn btn-sm" onClick={() => input.current?.click()}>Add photo</button>
            </>
          ) : null}
          {extra}
        </div>
        <button className="btn btn-primary btn-sm" type="submit" disabled={busy || !text.trim()}>{busy ? "Sending…" : submitLabel}</button>
      </div>
    </form>
  );
}

export function Dialog({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (d && !d.open) d.showModal();
  }, []);
  return (
    <dialog ref={ref} className="dialog" onClose={onClose} onClick={(e) => { if (e.target === ref.current) onClose(); }}>
      <div className="dialog-body">
        <div className="panel-head"><h2>{title}</h2><button className="btn btn-ghost btn-sm" onClick={onClose} aria-label="Close"><i className="bx bx-x" aria-hidden="true" /></button></div>
        {children}
      </div>
    </dialog>
  );
}

const REASONS: [string, string][] = [
  ["harassment_bullying", "Harassment or bullying"],
  ["offensive_content", "Offensive content"],
  ["breaks_community_rules", "Breaks the community rules"],
  ["spam_or_fake_profile", "Spam or a fake profile"],
  ["other", "Something else"],
];

export type ReportTarget = "user" | "message" | "post" | "comment" | "testimony" | "prayer_request";

/** "Report" link that opens the same reasons the mobile app offers. */
export function ReportButton({ type, id, label = "Report" }: { type: ReportTarget; id: string; label?: string }) {
  const [open, setOpen] = useState(false);
  const [reason, setReason] = useState("");
  const [details, setDetails] = useState("");
  const [sent, setSent] = useState(false);
  const { busy, error, run } = useAction();
  const close = () => { setOpen(false); setSent(false); setReason(""); setDetails(""); };
  return (
    <>
      <button type="button" className="link-btn" onClick={() => setOpen(true)}>{label}</button>
      {open ? (
        <Dialog title={sent ? "Report sent" : "Report"} onClose={close}>
          {sent ? (
            <><p>Thank you. The people who look after this community will review it.</p><button className="btn btn-primary" onClick={close}>Done</button></>
          ) : (
            <form onSubmit={async (e) => {
              e.preventDefault();
              if (await run(() => postOnce("/reports", { target_type: type, target_id: id, reason, ...(details.trim() ? { details: details.trim() } : {}) }))) setSent(true);
            }}>
              <fieldset className="radios">
                <legend>What is wrong?</legend>
                {REASONS.map(([v, l]) => (
                  <label key={v}><input type="radio" name="reason" value={v} checked={reason === v} onChange={() => setReason(v)} /> {l}</label>
                ))}
              </fieldset>
              <div className="field">
                <label htmlFor="report-details">More detail (optional)</label>
                <textarea id="report-details" rows={3} maxLength={2000} value={details} onChange={(e) => setDetails(e.target.value)} />
              </div>
              <ErrorText>{error}</ErrorText>
              <button className="btn btn-primary" type="submit" disabled={!reason || busy}>{busy ? "Sending…" : "Send report"}</button>
            </form>
          )}
        </Dialog>
      ) : null}
    </>
  );
}

export function Confirm({ title, body, confirmLabel, onConfirm, onClose }: { title: string; body: string; confirmLabel: string; onConfirm: () => Promise<unknown>; onClose: () => void }) {
  const { busy, error, run } = useAction();
  return (
    <Dialog title={title} onClose={onClose}>
      <p>{body}</p>
      <ErrorText>{error}</ErrorText>
      <div className="btn-row">
        <button className="btn" onClick={onClose}>Cancel</button>
        <button className="btn btn-dark" disabled={busy} onClick={async () => { if (await run(onConfirm)) onClose(); }}>{busy ? "Working…" : confirmLabel}</button>
      </div>
    </Dialog>
  );
}

export function MoreButton<T>({ got, path, onMore }: { got: { next_cursor: string | null } | undefined; path: string; onMore: (page: { items: T[]; next_cursor: string | null }) => void }) {
  const { busy, error, run } = useAction();
  if (!got?.next_cursor) return null;
  return (
    <div className="more">
      <ErrorText>{error}</ErrorText>
      <button className="btn btn-sm" disabled={busy} onClick={() => run(async () => {
        const { api } = await import("@/lib/api");
        onMore(await api(`${path}${path.includes("?") ? "&" : "?"}cursor=${encodeURIComponent(got.next_cursor!)}`));
      })}>{busy ? "Loading…" : "Show more"}</button>
    </div>
  );
}

export { ApiError, messageOf };
