/**
 * src/features/account/components/SignOutButton.tsx
 *
 * WHAT: Sign out of this device from the My account page
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { LogOut } from "lucide-react";
import { useSignOut } from "@/features/auth/hooks/useSignOut";

export function SignOutButton() {
  const { signOut, signingOut } = useSignOut();
  return (
    <button type="button" onClick={signOut} disabled={signingOut} className="btn btn-secondary">
      <LogOut className="h-4 w-4" aria-hidden="true" />
      {signingOut ? "Signing out…" : "Sign out"}
    </button>
  );
}
