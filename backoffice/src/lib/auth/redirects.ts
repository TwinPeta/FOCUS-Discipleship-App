/**
 * src/lib/auth/redirects.ts
 *
 * WHAT: Safe return-to URL handling after login (prevents open redirects)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { getHomeRouteForRole } from "@/lib/constants/routes";
import type { Role } from "@/types/enums";

/**
 * Validates a relative return-to path to prevent open redirects.
 * Rejects protocol-relative URLs (//evil.com), full URLs (https://...), backslashes, and auth routes.
 */
export function sanitizeReturnTo(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (!trimmed.startsWith("/")) return null;
  if (trimmed.startsWith("//") || trimmed.startsWith("/\\")) return null;

  // Reject any scheme-like prefix or control characters
  if (/[\r\n\t]/.test(trimmed)) return null;

  // Avoid redirecting back into auth pages
  if (
    trimmed === "/login" ||
    trimmed.startsWith("/login?") ||
    trimmed === "/forgot-password" ||
    trimmed === "/reset-password"
  ) {
    return null;
  }

  return trimmed;
}

export function resolvePostLoginRedirect(
  role: Role,
  returnTo: string | null | undefined,
): string {
  const safe = sanitizeReturnTo(returnTo);
  const home = getHomeRouteForRole(role);

  if (!safe) return home;

  // Super-mentors are strictly scoped to /my-community
  if (role === "SUPER_MENTOR" && !safe.startsWith("/my-community")) {
    return home;
  }

  return safe;
}
