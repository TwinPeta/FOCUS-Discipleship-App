"use client";

import { useEffect, useRef, useState } from "react";
import { CodeInput } from "@/components/CodeInput";
import { Avatar, Confirm, ErrorText, Load, PageTitle, Panel } from "@/components/ui";
import { api, del, patch, post, put, uploadImage } from "@/lib/api";
import { useAuth } from "@/lib/auth";
import { useAction, useGet } from "@/lib/hooks";
import type { Profile, UserRef } from "@/lib/types";

/** Confirms the student's email with the 6-digit code the API sends (the mobile app's "Check your email" step). */
function VerifyEmail() {
  const { user, setUser } = useAuth();
  const [sent, setSent] = useState(false);
  const [code, setCode] = useState("");
  const send = useAction();
  const check = useAction();
  if (!user?.email || user.email_verified) return null;
  const request = () => send.run(async () => {
    await post("/auth/otp/request", { channel: "email", destination: user.email, purpose: "verify_contact" }, false);
    setSent(true);
  });
  return (
    <div className="notice" style={{ marginBottom: 16 }}>
      <b>Your email is not confirmed yet.</b>{" "}
      {sent ? (
        <form className="inline-form" style={{ marginTop: 10 }} onSubmit={async (e) => {
          e.preventDefault();
          await check.run(async () => {
            await post("/auth/otp/verify", { destination: user.email, code, purpose: "verify_contact" }, false);
            setUser(await api<Profile>("/me"));
          });
        }}>
          <div className="field">
            <label htmlFor="verify-code">Enter the 6-digit code we sent to {user.email}</label>
            <CodeInput id="verify-code" value={code} onChange={setCode} />
          </div>
          <ErrorText>{check.error ? "That code is not right or has expired." : ""}</ErrorText>
          <div className="actions">
            <button className="btn btn-primary btn-sm" disabled={check.busy || code.length !== 6}>{check.busy ? "Checking…" : "Confirm email"}</button>
            <button type="button" className="link-btn" disabled={send.busy} onClick={request}>Send a new code</button>
          </div>
        </form>
      ) : (
        <>
          We can send a code to {user.email}.
          <div><button className="btn btn-sm" disabled={send.busy} onClick={request}>{send.busy ? "Sending…" : "Send code"}</button></div>
        </>
      )}
      <ErrorText>{send.error}</ErrorText>
    </div>
  );
}

function ProfileForm() {
  const { user, setUser } = useAuth();
  const [f, setF] = useState({ full_name: user?.full_name || "", email: user?.email || "", phone: user?.phone || "" });
  const save = useAction();
  const photo = useAction();
  const [saved, setSaved] = useState(false);
  const input = useRef<HTMLInputElement>(null);
  if (!user) return null;
  const changed = f.full_name.trim() !== user.full_name || f.email.trim() !== (user.email || "") || f.phone.trim() !== (user.phone || "");
  return (
    <Panel title="Your details">
      <VerifyEmail />
      <div className="row" style={{ marginBottom: 16 }}>
        <Avatar user={user} size={64} />
        <span className="grow"><b>Profile photo</b><small>JPEG, PNG or WebP, up to 10 MB</small></span>
        <input ref={input} type="file" accept="image/jpeg,image/png,image/webp" hidden onChange={(e) => {
          const file = e.target.files?.[0];
          e.target.value = "";
          if (file) photo.run(async () => setUser(await patch<Profile>("/me", { photo_media_id: await uploadImage(file, "profile_photo") })));
        }} />
        <button className="btn btn-sm" disabled={photo.busy} onClick={() => input.current?.click()}>{photo.busy ? "Uploading…" : "Change photo"}</button>
      </div>
      <ErrorText>{photo.error}</ErrorText>
      <form className="inline-form" onSubmit={async (e) => {
        e.preventDefault();
        setSaved(false);
        const body: Record<string, string> = {};
        if (f.full_name.trim() !== user.full_name) body.full_name = f.full_name.trim();
        if (f.email.trim() && f.email.trim() !== (user.email || "")) body.email = f.email.trim();
        if (f.phone.trim() && f.phone.trim() !== (user.phone || "")) body.phone = f.phone.trim();
        if (await save.run(async () => setUser(await patch<Profile>("/me", body)))) setSaved(true);
      }}>
        <div className="field"><label htmlFor="s-name">Full name</label><input id="s-name" autoComplete="name" value={f.full_name} onChange={(e) => setF({ ...f, full_name: e.target.value })} /></div>
        <div className="row-2">
          <div className="field"><label htmlFor="s-email">Email</label><input id="s-email" type="email" autoComplete="email" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} /></div>
          <div className="field"><label htmlFor="s-phone">Phone</label><input id="s-phone" type="tel" autoComplete="tel" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></div>
        </div>
        <p className="meta">Username: @{user.username}{user.institution ? ` · ${user.institution.name}` : ""}</p>
        <ErrorText>{save.error}</ErrorText>
        <div className="actions">
          <button className="btn btn-primary btn-sm" disabled={save.busy || !changed || f.full_name.trim().length < 2}>{save.busy ? "Saving…" : "Save changes"}</button>
          {saved && !changed ? <span className="ok-text">Saved</span> : null}
        </div>
      </form>
    </Panel>
  );
}

/** Lets a student appear as @username (no name, no photo) to other students. Staff still see who they are. */
function Privacy() {
  const { user, setUser } = useAuth();
  const save = useAction();
  if (!user) return null;
  const on = !!user.show_username_only;
  return (
    <Panel title="How others see you">
      <label className="switch"><span>Show my username instead of my name</span>
        <input type="checkbox" checked={on} disabled={save.busy}
          onChange={() => save.run(async () => setUser(await patch<Profile>("/me", { show_username_only: !on })))} /></label>
      <p className="meta" style={{ marginTop: 8 }}>
        {on
          ? `Other students see @${user.username} on your posts, comments and messages, with no photo.`
          : "Other students see your name and photo on your posts, comments and messages."}{" "}
        The FCU team can always see who you are, to keep everyone safe.
      </p>
      <ErrorText>{save.error}</ErrorText>
    </Panel>
  );
}

const CATEGORIES: [string, string][] = [
  ["joinRequestUpdates", "Updates on my request to join a community"],
  ["replies", "Replies to my posts"],
  ["prayerResponses", "Prayers and responses to my prayer requests"],
  ["announcements", "Announcements"],
  ["meetingReminders", "Meeting reminders"],
  ["inactivityReminders", "Reminders when I have been away"],
];

type Prefs = { channels: string[]; muted: string[] };

function NotificationPrefs() {
  const got = useGet<Prefs>("/me/notification-preferences");
  const save = useAction();
  const update = (next: Prefs) => {
    const before = got.data;
    got.setData(next);
    save.run(async () => {
      try { got.setData(await put<Prefs>("/me/notification-preferences", next)); } catch (e) { if (before) got.setData(before); throw e; }
    });
  };
  const flip = (list: string[], v: string) => (list.includes(v) ? list.filter((x) => x !== v) : [...list, v]);
  return (
    <Panel title="Notifications">
      <ErrorText>{save.error}</ErrorText>
      <Load got={got}>
        {(p) => (
          <>
            <label className="switch"><span>Send notifications by email too</span>
              <input type="checkbox" checked={p.channels.includes("email")} onChange={() => update({ ...p, channels: flip(p.channels, "email") })} /></label>
            <p className="legend" style={{ margin: "14px 0 4px" }}>Tell me about</p>
            {CATEGORIES.map(([k, l]) => (
              <label className="switch" key={k}><span>{l}</span>
                <input type="checkbox" checked={!p.muted.includes(k)} onChange={() => update({ ...p, muted: flip(p.muted, k) })} /></label>
            ))}
          </>
        )}
      </Load>
    </Panel>
  );
}

type Guardian = { name: string; relationship: string | null; email: string | null; phone: string | null; status: "confirmed" | "pending" } | null;

function GuardianForm() {
  const got = useGet<{ guardian: Guardian }>("/me/guardian");
  const [f, setF] = useState({ name: "", relationship: "", email: "", phone: "" });
  const save = useAction();
  const [saved, setSaved] = useState(false);
  const g = got.data?.guardian;
  useEffect(() => {
    if (g) setF({ name: g.name, relationship: g.relationship || "", email: g.email || "", phone: g.phone || "" });
  }, [g]);
  return (
    <section className="panel" id="guardian">
      <div className="panel-head"><h2>Parent or guardian</h2>{g ? <span className={g.status === "confirmed" ? "pill ok" : "pill"}>{g.status === "confirmed" ? "Consent confirmed" : "Waiting for consent"}</span> : null}</div>
      <p className="meta" style={{ marginBottom: 14 }}>Because you are under 18, the FCU team confirms consent with your parent or guardian before your account is fully open.</p>
      <Load got={got}>
        {() => (
          <form className="inline-form" onSubmit={async (e) => {
            e.preventDefault();
            setSaved(false);
            const body = { name: f.name.trim(), ...(f.relationship.trim() ? { relationship: f.relationship.trim() } : {}), ...(f.email.trim() ? { email: f.email.trim() } : {}), ...(f.phone.trim() ? { phone: f.phone.trim() } : {}) };
            if (await save.run(async () => got.setData(await put<{ guardian: Guardian }>("/me/guardian", body)))) setSaved(true);
          }}>
            <div className="row-2">
              <div className="field"><label htmlFor="g-name">Their full name</label><input id="g-name" value={f.name} onChange={(e) => setF({ ...f, name: e.target.value })} /></div>
              <div className="field"><label htmlFor="g-rel">Relationship</label><input id="g-rel" placeholder="Mother, uncle…" value={f.relationship} onChange={(e) => setF({ ...f, relationship: e.target.value })} /></div>
            </div>
            <div className="row-2">
              <div className="field"><label htmlFor="g-email">Their email</label><input id="g-email" type="email" value={f.email} onChange={(e) => setF({ ...f, email: e.target.value })} /></div>
              <div className="field"><label htmlFor="g-phone">Their phone</label><input id="g-phone" type="tel" value={f.phone} onChange={(e) => setF({ ...f, phone: e.target.value })} /></div>
            </div>
            <span className="hint">Give their email, their phone, or both.</span>
            <ErrorText>{save.error}</ErrorText>
            <div className="actions">
              <button className="btn btn-primary btn-sm" disabled={save.busy || f.name.trim().length < 2 || (!f.email.trim() && !f.phone.trim())}>{save.busy ? "Saving…" : "Save guardian"}</button>
              {saved ? <span className="ok-text">Saved</span> : null}
            </div>
          </form>
        )}
      </Load>
    </section>
  );
}

function Blocked() {
  const got = useGet<{ items: UserRef[] }>("/me/blocks");
  const act = useAction();
  return (
    <Panel title="Blocked people">
      <ErrorText>{act.error}</ErrorText>
      <Load got={got} empty={(d) => (d.items.length ? null : "You have not blocked anyone.")}>
        {(d) => d.items.map((u) => (
          <div className="row" key={u.id}>
            <Avatar user={u} />
            <span className="grow"><b>{u.full_name}</b><small>@{u.username}</small></span>
            <button className="btn btn-sm" disabled={act.busy} onClick={() => act.run(async () => { await del(`/users/${u.id}/block`); await got.reload(); })}>Unblock</button>
          </div>
        ))}
      </Load>
    </Panel>
  );
}

function Account() {
  const { signOut } = useAuth();
  const exp = useAction();
  const [exported, setExported] = useState(false);
  const [deleting, setDeleting] = useState(false);
  return (
    <Panel title="Your account and data">
      <div className="row">
        <span className="grow"><b>Get a copy of your data</b><small style={{ whiteSpace: "normal" }}>The FCU team prepares it and sends it to you.</small></span>
        {exported ? <span className="ok-text">Requested</span> : <button className="btn btn-sm" disabled={exp.busy} onClick={async () => { if (await exp.run(() => post("/me/export", {}))) setExported(true); }}>Request</button>}
      </div>
      <ErrorText>{exp.error}</ErrorText>
      <div className="row">
        <span className="grow"><b>Log out</b><small>On this browser only.</small></span>
        <button className="btn btn-sm" onClick={() => signOut()}>Log out</button>
      </div>
      <div className="row">
        <span className="grow"><b>Delete your account</b><small style={{ whiteSpace: "normal" }}>Closes your account and schedules your data for deletion.</small></span>
        <button className="btn btn-sm" onClick={() => setDeleting(true)}>Delete</button>
      </div>
      {deleting ? (
        <Confirm title="Delete your account?" body="You will be signed out now and will not be able to log in again. Your data is scheduled for deletion. This cannot be undone from here."
          confirmLabel="Delete my account" onClose={() => setDeleting(false)} onConfirm={async () => { await del("/me"); await signOut(); }} />
      ) : null}
    </Panel>
  );
}

export default function Settings() {
  const { user } = useAuth();
  return (
    <>
      <PageTitle title="Settings" back={{ href: "/profile", label: "Profile" }} />
      <ProfileForm />
      <Privacy />
      {user && user.minor_status !== "adult" ? <GuardianForm /> : null}
      <NotificationPrefs />
      <Blocked />
      <Account />
    </>
  );
}
