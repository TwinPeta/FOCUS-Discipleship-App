/**
 * src/lib/auth/session.ts
 *
 * WHAT: Server-side session reader (httpOnly cookies) for layouts, middleware and route handlers
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { cookies } from "next/headers";
import { getServerEnv } from "@/lib/env";
import type { Session, SessionUser } from "@/types/user";
import { getAuthCookieNames } from "./cookies";

export async function getServerSession(): Promise<Session | null> {
  const cookieStore = await cookies();
  const { access } = getAuthCookieNames();
  const token = cookieStore.get(access)?.value;

  if (!token) return null;

  const env = getServerEnv();

  try {
    const res = await fetch(`${env.API_BASE_URL}/auth/me`, {
      // The API owns the session; ask it who this cookie belongs to
      headers: { cookie: `${access}=${encodeURIComponent(token)}` },
      cache: "no-store",
    });

    if (!res.ok) return null;
    const data = (await res.json()) as { user?: SessionUser } | SessionUser;
    const user = "user" in data && data.user ? data.user : (data as SessionUser);
    if (!user?.id || !user?.role) return null;

    return { user };
  } catch {
    return null;
  }
}
