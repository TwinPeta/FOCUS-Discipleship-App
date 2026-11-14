/**
 * src/lib/auth/cookies.ts
 *
 * WHAT: Names and options for httpOnly auth cookies set by the proxy
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import type { ResponseCookie } from "next/dist/compiled/@edge-runtime/cookies";
import { getServerEnv } from "@/lib/env";

export function getAuthCookieNames() {
  const env = getServerEnv();
  return {
    access: env.AUTH_ACCESS_COOKIE,
    refresh: env.AUTH_REFRESH_COOKIE,
  };
}

export function getAuthCookieOptions(maxAgeSeconds?: number): Partial<ResponseCookie> {
  const isProd = process.env.NODE_ENV === "production";
  return {
    httpOnly: true,
    secure: isProd,
    sameSite: "lax",
    path: "/",
    ...(typeof maxAgeSeconds === "number" ? { maxAge: maxAgeSeconds } : {}),
  };
}
