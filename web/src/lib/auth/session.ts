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
import { MemberStatus, Role } from "@/types/enums";
import type { Session, SessionUser } from "@/types/user";
import { getAuthCookieNames } from "./cookies";

const MOCK_USERS: Record<string, SessionUser> = {
  SYSTEM_ADMIN: {
    id: "staff-sys-1",
    email: "admin@focusuganda.org",
    fullName: "Grace Nakato",
    role: Role.SystemAdmin,
    status: MemberStatus.Active,
  },
  CONTENT_ADMIN: {
    id: "staff-cnt-1",
    email: "content@focusuganda.org",
    fullName: "Daniel Okello",
    role: Role.ContentAdmin,
    status: MemberStatus.Active,
  },
  SUPER_MENTOR: {
    id: "staff-sm-1",
    email: "mentor@focusuganda.org",
    fullName: "Sarah Namukasa",
    role: Role.SuperMentor,
    status: MemberStatus.Active,
    communityId: "comm-mak-1",
    communityName: "Makerere University CU",
  },
};

export function parseMockAccessToken(token: string | undefined): SessionUser | null {
  if (!token || !token.startsWith("mock:")) return null;
  const roleKey = token.slice("mock:".length);
  return MOCK_USERS[roleKey] ?? null;
}

export async function getServerSession(): Promise<Session | null> {
  const cookieStore = await cookies();
  const { access } = getAuthCookieNames();
  const token = cookieStore.get(access)?.value;

  if (!token) return null;

  const env = getServerEnv();

  if (env.NEXT_PUBLIC_API_MOCKING === "enabled") {
    const mockUser = parseMockAccessToken(token);
    if (mockUser) {
      return { user: mockUser };
    }
  }

  try {
    const res = await fetch(`${env.API_BASE_URL}/auth/me`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
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
