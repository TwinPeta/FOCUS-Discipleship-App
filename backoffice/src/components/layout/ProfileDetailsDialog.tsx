/**
 * src/components/layout/ProfileDetailsDialog.tsx
 *
 * WHAT: Right-side profile drawer: photo, name, email, role and scope; quick edit of name/photo;
 *       links to account security; workspace preferences; sign out
 * REQUIREMENTS: FR-07, FR-12
 * SPEC: docs/features/01-staff-access.md, docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useId, useState, type FormEvent, type ReactNode } from "react";
import Link from "next/link";
import { toast } from "sonner";
import { ChevronRight, KeyRound, LogOut, MonitorSmartphone, Pencil, X } from "lucide-react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { ModalDialog } from "@/components/common/ModalDialog";
import { updateProfile } from "@/features/account/queries";
import { useSession } from "@/features/auth/hooks/useSession";
import { useSignOut } from "@/features/auth/hooks/useSignOut";
import { ROUTES } from "@/lib/constants/routes";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { Role } from "@/types/enums";
import { useShell } from "./ShellContext";

const ROLE_BADGE: Partial<Record<Role, string>> = {
  [Role.SystemAdmin]: "bg-ink text-white",
  [Role.ContentAdmin]: "bg-info-soft text-info ring-1 ring-info/30",
  [Role.SuperMentor]: "bg-success-soft text-success ring-1 ring-success/30",
};

const ROLE_SCOPE: Partial<Record<Role, string>> = {
  [Role.SystemAdmin]: "Full access to every caregroup and setting",
  [Role.ContentAdmin]: "Creates and reviews content and pathways",
};

function isValidUrl(value: string) {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

export function ProfileDetailsDialog() {
  const { user, updateUser } = useSession();
  const { signOut, signingOut } = useSignOut();
  const { profileOpen, setProfileOpen, sidebarExpanded, toggleSidebar, motionPaused, toggleMotion } = useShell();
  const titleId = useId();

  const [editing, setEditing] = useState(false);
  const [fullName, setFullName] = useState("");
  const [avatarUrl, setAvatarUrl] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fresh form every time the drawer opens.
  useEffect(() => {
    if (profileOpen && user) {
      setEditing(false);
      setError(null);
      setFullName(user.fullName);
      setAvatarUrl(user.avatarUrl ?? "");
    }
  }, [profileOpen, user]);

  if (!user) return null;

  const close = () => setProfileOpen(false);
  const roleLabel = ROLE_LABELS[user.role] ?? user.role;
  const scope =
    user.role === Role.SuperMentor
      ? `Leads ${user.communityName ?? "one caregroup"}`
      : ROLE_SCOPE[user.role];
  const previewUrl = avatarUrl.trim() && isValidUrl(avatarUrl.trim()) ? avatarUrl.trim() : null;

  async function onSave(event: FormEvent) {
    event.preventDefault();
    const name = fullName.trim();
    const photo = avatarUrl.trim();
    if (name.length < 2) return setError("Full name must be at least 2 characters.");
    if (photo && !isValidUrl(photo)) return setError("Photo URL must start with http:// or https://");

    setSaving(true);
    setError(null);
    try {
      const patch = { fullName: name, avatarUrl: photo || null };
      await updateProfile(patch);
      updateUser(patch);
      setEditing(false);
      toast.success("Profile updated");
    } catch {
      setError("Could not update your profile. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <ModalDialog
      open={profileOpen}
      onClose={close}
      labelledBy={titleId}
      variant="drawer"
      className="m-0 ml-auto h-dvh max-h-dvh w-[min(400px,100vw)]"
    >
      <div className="flex h-full flex-col overflow-y-auto border-l border-border/70 bg-surface shadow-2xl">
        {/* Header band */}
        <div className="relative shrink-0 bg-gradient-to-br from-primary via-primary to-accent px-5 pb-5 pt-4">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold uppercase tracking-wider text-black/70">Your profile</p>
            <button
              type="button"
              onClick={close}
              aria-label="Close profile"
              className="grid h-8 w-8 place-items-center rounded-lg text-foreground/80 hover:bg-black/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground"
            >
              <X className="h-5 w-5" aria-hidden="true" />
            </button>
          </div>

          <div className="mt-3 flex items-center gap-4">
            <InitialsAvatar
              name={editing ? fullName || user.fullName : user.fullName}
              avatarUrl={editing ? previewUrl : user.avatarUrl}
              size="xl"
              className="ring-4 ring-white/70"
            />
            <div className="min-w-0">
              <h2 id={titleId} className="truncate text-lg font-black leading-tight text-slate-950">
                {user.fullName}
              </h2>
              <p className="truncate text-sm text-slate-900/80">{user.email}</p>
              <span
                className={`mt-1.5 inline-block rounded-full px-2 py-0.5 text-[11px] font-bold ${
                  ROLE_BADGE[user.role] ?? "bg-white text-slate-900"
                }`}
              >
                {roleLabel}
              </span>
            </div>
          </div>
        </div>

        <div className="flex-1 space-y-6 p-5">
          {scope && (
            <p className="rounded-lg bg-background-subtle px-3 py-2 text-sm text-muted-foreground">{scope}</p>
          )}

          {/* Quick edit */}
          <section aria-labelledby={`${titleId}-edit`}>
            <div className="mb-2 flex items-center justify-between">
              <h3 id={`${titleId}-edit`} className="text-sm font-bold text-foreground">
                Name &amp; photo
              </h3>
              {!editing && (
                <button
                  type="button"
                  onClick={() => setEditing(true)}
                  className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-semibold text-foreground hover:bg-primary-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                >
                  <Pencil className="h-3.5 w-3.5" aria-hidden="true" /> Edit
                </button>
              )}
            </div>

            {editing ? (
              <form onSubmit={onSave} noValidate className="space-y-3">
                {error && (
                  <p role="alert" className="rounded-md border border-danger/30 bg-danger-soft px-3 py-2 text-xs text-danger">
                    {error}
                  </p>
                )}
                <label className="block space-y-1">
                  <span className="text-xs font-medium text-foreground">Full name</span>
                  <input
                    type="text"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    required
                    minLength={2}
                    autoComplete="name"
                    className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </label>
                <label className="block space-y-1">
                  <span className="text-xs font-medium text-foreground">Photo URL</span>
                  <input
                    type="url"
                    value={avatarUrl}
                    onChange={(e) => setAvatarUrl(e.target.value)}
                    placeholder="https://…"
                    className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                  <span className="block text-[11px] text-muted-foreground">
                    Leave empty to show your initials. The preview above updates as you type.
                  </span>
                </label>
                <div className="flex gap-2">
                  <button
                    type="submit"
                    disabled={saving}
                    className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-slate-950 transition hover:bg-primary-hover disabled:opacity-60"
                  >
                    {saving ? "Saving…" : "Save"}
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setEditing(false);
                      setError(null);
                      setFullName(user.fullName);
                      setAvatarUrl(user.avatarUrl ?? "");
                    }}
                    className="rounded-md px-4 py-2 text-sm font-semibold text-muted-foreground hover:bg-background-subtle"
                  >
                    Cancel
                  </button>
                </div>
              </form>
            ) : (
              <p className="text-sm text-muted-foreground">
                This is how other staff see you across the backoffice.
              </p>
            )}
          </section>

          {/* Security links */}
          <section aria-label="Account security" className="divide-y divide-border/50 overflow-hidden rounded-xl border border-border/60">
            <DrawerLink href={`${ROUTES.account}#security`} icon={<KeyRound className="h-4 w-4" />} onNavigate={close}>
              Password &amp; security
            </DrawerLink>
            <DrawerLink href={`${ROUTES.account}#sessions`} icon={<MonitorSmartphone className="h-4 w-4" />} onNavigate={close}>
              Active sessions
            </DrawerLink>
          </section>

          {/* Preferences */}
          <section aria-labelledby={`${titleId}-prefs`} className="space-y-1">
            <h3 id={`${titleId}-prefs`} className="mb-1 text-sm font-bold text-foreground">
              Workspace
            </h3>
            <Toggle label="Keep sidebar expanded" checked={sidebarExpanded} onChange={toggleSidebar} />
            <Toggle label="Animated background" checked={!motionPaused} onChange={toggleMotion} />
          </section>
        </div>

        <div className="shrink-0 border-t border-border/60 p-4">
          <button
            type="button"
            onClick={() => void signOut()}
            disabled={signingOut}
            className="flex w-full items-center justify-center gap-2 rounded-lg border border-danger/30 px-4 py-2.5 text-sm font-semibold text-danger transition hover:bg-danger-soft disabled:opacity-60"
          >
            <LogOut className="h-4 w-4" aria-hidden="true" />
            {signingOut ? "Signing out…" : "Sign out"}
          </button>
        </div>
      </div>
    </ModalDialog>
  );
}

function DrawerLink({
  href,
  icon,
  onNavigate,
  children,
}: {
  href: string;
  icon: ReactNode;
  onNavigate: () => void;
  children: ReactNode;
}) {
  return (
    <Link
      href={href}
      onClick={onNavigate}
      className="flex items-center gap-3 px-3 py-2.5 text-sm font-medium text-foreground transition hover:bg-primary-soft focus-visible:bg-primary-soft focus-visible:outline-none"
    >
      <span className="text-muted-foreground" aria-hidden="true">{icon}</span>
      <span className="flex-1">{children}</span>
      <ChevronRight className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
    </Link>
  );
}

function Toggle({ label, checked, onChange }: { label: string; checked: boolean; onChange: () => void }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      onClick={onChange}
      className="flex w-full items-center justify-between rounded-lg px-1 py-2 text-left text-sm text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
    >
      <span>{label}</span>
      <span
        aria-hidden="true"
        className={`relative h-5 w-9 rounded-full transition ${checked ? "bg-primary" : "bg-slate-300"}`}
      >
        <span
          className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow transition-transform ${
            checked ? "translate-x-[18px]" : "translate-x-0.5"
          }`}
        />
      </span>
    </button>
  );
}
