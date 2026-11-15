/**
 * src/providers/SessionExpiryWatcher.tsx
 *
 * WHAT: Sends the user to the login page (with the page they were on) when the API reports the session has ended
 * REQUIREMENTS: FR-07
 * STATUS: implemented
 */

"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";
import { AUTH_ROUTES } from "@/lib/constants/routes";
import { watchSessionExpiry } from "@/lib/auth/sessionExpiry";

export function SessionExpiryWatcher() {
  const pathname = usePathname();

  useEffect(() => {
    if (AUTH_ROUTES.some((r) => pathname === r || pathname.startsWith(`${r}/`))) return;
    return watchSessionExpiry(window, () => {
      const here = `${window.location.pathname}${window.location.search}`;
      window.location.assign(`/login?error=expired&returnTo=${encodeURIComponent(here)}`);
    });
  }, [pathname]);

  return null;
}
