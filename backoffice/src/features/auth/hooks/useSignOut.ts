/**
 * src/features/auth/hooks/useSignOut.ts
 *
 * WHAT: Shared sign-out action used by the user card, profile dialog and command palette
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { ROUTES } from "@/lib/constants/routes";

export function useSignOut() {
  const router = useRouter();
  const [signingOut, setSigningOut] = useState(false);

  const signOut = useCallback(async () => {
    setSigningOut(true);
    try {
      await fetch("/api/proxy/auth/logout", { method: "POST" });
    } finally {
      router.push(ROUTES.login);
      router.refresh();
    }
  }, [router]);

  return { signOut, signingOut };
}
