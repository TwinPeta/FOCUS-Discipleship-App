/**
 * src/components/layout/UserCard.tsx
 *
 * WHAT: Initials avatar, user full name, role badge, and accessible sign out action
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROUTES } from "@/lib/constants/routes";
import { ROLE_LABELS } from "@/lib/permissions/roles";

export function UserCard() {
  const router = useRouter();
  const { user } = useSession();
  const [signingOut, setSigningOut] = useState(false);

  if (!user) return null;

  async function handleSignOut() {
    setSigningOut(true);
    try {
      await fetch("/api/proxy/auth/logout", { method: "POST" });
    } finally {
      router.push(ROUTES.login);
      router.refresh();
    }
  }

  return (
    <div className="flex items-center justify-between gap-2.5 rounded-xl bg-black/10 p-2.5 text-foreground">
      <div className="flex items-center gap-2.5 min-w-0">
        <InitialsAvatar name={user.fullName} size="sm" />
        <div className="min-w-0">
          <p className="truncate text-xs font-bold leading-tight text-foreground">
            {user.fullName}
          </p>
          <p className="truncate text-[11px] text-foreground/80 leading-tight">
            {ROLE_LABELS[user.role] ?? user.role}
          </p>
        </div>
      </div>

      <button
        type="button"
        onClick={handleSignOut}
        disabled={signingOut}
        title="Sign out of backoffice"
        aria-label="Sign out"
        className="rounded-lg p-1.5 text-foreground/80 hover:bg-black/10 hover:text-foreground transition disabled:opacity-50 shrink-0"
      >
        <LogOut className="h-4 w-4" />
      </button>
    </div>
  );
}
