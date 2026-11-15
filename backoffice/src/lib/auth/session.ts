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

export type SessionState =
  | { status: "ok"; session: Session }
  | { status: "none" } // not signed in
  | { status: "expired" } // the API no longer recognises the cookie
  | { status: "suspended" }
  | { status: "unavailable" }; // the API could not be reached

/** Asks the API who this cookie belongs to. The API owns the session; this only reports its answer. */
export async function getSessionState(): Promise<SessionState> {
  const cookieStore = await cookies();
  const { access } = getAuthCookieNames();
  const token = cookieStore.get(access)?.value;
  if (!token) return { status: "none" };

  const env = getServerEnv();
  try {
    const res = await fetch(`${env.API_BASE_URL}/auth/me`, {
      headers: { cookie: `${access}=${encodeURIComponent(token)}` },
      cache: "no-store",
    });

    if (res.status === 401) return { status: "expired" };
    if (res.status === 403) {
      const body = (await res.json().catch(() => ({}))) as { code?: string };
      return body.code?.toLowerCase() === "account_suspended"
        ? { status: "suspended" }
        : { status: "expired" };
    }
    if (!res.ok) return { status: "unavailable" };

    const data = (await res.json()) as { user?: SessionUser } | SessionUser;
    const user = "user" in data && data.user ? data.user : (data as SessionUser);
    if (!user?.id || !user?.role) return { status: "expired" };
    return { status: "ok", session: { user } };
  } catch {
    return { status: "unavailable" };
  }
}

export async function getServerSession(): Promise<Session | null> {
  const state = await getSessionState();
  return state.status === "ok" ? state.session : null;
}
