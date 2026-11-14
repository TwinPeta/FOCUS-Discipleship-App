/**
 * src/components/layout/UserCard.tsx
 *
 * WHAT: Sidebar footer: avatar, name and role. Clicking opens the profile dialog; collapsed mode shows the avatar only.
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { ChevronsUpDown } from "lucide-react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { useShell } from "./ShellContext";

export function UserCard({ collapsed = false }: { collapsed?: boolean }) {
  const { user } = useSession();
  const { setProfileOpen, setMobileNavOpen } = useShell();

  if (!user) return null;

  const roleLabel = ROLE_LABELS[user.role] ?? user.role;

  function open() {
    setMobileNavOpen(false);
    setProfileOpen(true);
  }

  return (
    <button
      type="button"
      onClick={open}
      aria-haspopup="dialog"
      aria-label={`Open profile for ${user.fullName}`}
      title={collapsed ? `${user.fullName} · ${roleLabel}` : undefined}
      className={`group flex w-full items-center gap-2.5 rounded-xl text-left text-foreground transition hover:bg-black/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-foreground ${
        collapsed ? "justify-center p-1.5" : "bg-black/[0.07] p-2"
      }`}
    >
      <InitialsAvatar name={user.fullName} avatarUrl={user.avatarUrl} size="sm" />
      {!collapsed && (
        <>
          <span className="min-w-0 flex-1">
            <span className="block truncate text-xs font-bold leading-tight">{user.fullName}</span>
            <span className="block truncate text-[11px] leading-tight text-foreground/75">{roleLabel}</span>
          </span>
          <ChevronsUpDown className="h-3.5 w-3.5 shrink-0 text-foreground/60" aria-hidden="true" />
        </>
      )}
    </button>
  );
}
