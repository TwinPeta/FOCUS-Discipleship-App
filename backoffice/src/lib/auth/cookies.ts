/**
 * src/lib/auth/cookies.ts
 *
 * WHAT: Names of the httpOnly auth cookies (the API sets and clears them)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { getServerEnv } from "@/lib/env";

export function getAuthCookieNames() {
  const env = getServerEnv();
  return {
    access: env.AUTH_ACCESS_COOKIE,
    refresh: env.AUTH_REFRESH_COOKIE,
  };
}
