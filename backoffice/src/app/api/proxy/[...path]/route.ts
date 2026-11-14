/**
 * src/app/api/proxy/[...path]/route.ts
 *
 * WHAT: Forwards browser API calls to the backend and attaches auth from httpOnly cookies (with dev mock auth support)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { getAuthCookieNames, getAuthCookieOptions } from "@/lib/auth/cookies";
import { parseMockAccessToken } from "@/lib/auth/session";
import { getServerEnv } from "@/lib/env";

const HOP_BY_HOP_HEADERS = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailers",
  "transfer-encoding",
  "upgrade",
  "host",
  "cookie",
]);

function resolveMockTokenForEmail(email: string): string {
  const lower = email.trim().toLowerCase();
  if (lower.includes("mentor")) return "mock:SUPER_MENTOR";
  if (lower.includes("content")) return "mock:CONTENT_ADMIN";
  return "mock:SYSTEM_ADMIN";
}

async function handleMockAuth(
  req: NextRequest,
  targetPath: string,
  accessToken: string | undefined,
): Promise<NextResponse | null> {
  const { access, refresh } = getAuthCookieNames();

  if (targetPath === "auth/login" && req.method === "POST") {
    const body = (await req.json().catch(() => ({}))) as {
      email?: string;
      rememberMe?: boolean;
    };
    const email = body.email ?? "admin@focusuganda.org";

    if (email.trim().toLowerCase() === "suspended@focusuganda.org") {
      return NextResponse.json(
        { code: "ACCOUNT_SUSPENDED", message: "Account suspended" },
        { status: 403 },
      );
    }

    const token = resolveMockTokenForEmail(email);
    const user = parseMockAccessToken(token);
    const res = NextResponse.json({ user });
    res.cookies.set(
      access,
      token,
      getAuthCookieOptions(body.rememberMe ? 60 * 60 * 24 * 7 : undefined),
    );
    return res;
  }

  if (targetPath === "auth/logout" && req.method === "POST") {
    const res = NextResponse.json({ ok: true });
    res.cookies.delete(access);
    res.cookies.delete(refresh);
    return res;
  }

  if (
    (targetPath === "auth/forgot-password" ||
      targetPath === "auth/reset-password") &&
    req.method === "POST"
  ) {
    return NextResponse.json({ ok: true });
  }

  if (targetPath === "auth/me" && req.method === "GET") {
    const user = parseMockAccessToken(accessToken);
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    return NextResponse.json({ user });
  }

  if (targetPath === "account/sessions" && req.method === "GET") {
    return NextResponse.json({
      sessions: [
        {
          id: "sess-current",
          deviceName: "Current browser",
          browser: "Chrome",
          os: "Windows",
          location: "Kampala, UG",
          lastActiveAt: "Just now",
          current: true,
        },
        {
          id: "sess-other",
          deviceName: "Office laptop",
          browser: "Edge",
          os: "Windows",
          location: "Kampala, UG",
          lastActiveAt: "2 hours ago",
          current: false,
        },
      ],
    });
  }

  if (
    (targetPath === "account/profile" && req.method === "PATCH") ||
    (targetPath === "account/password" && req.method === "POST") ||
    (targetPath.startsWith("account/sessions/") && req.method === "DELETE")
  ) {
    return NextResponse.json({ ok: true });
  }

  return null;
}

async function forwardRequest(
  req: NextRequest,
  context: { params: Promise<{ path: string[] }> },
) {
  const { path } = await context.params;
  const env = getServerEnv();
  const { access, refresh } = getAuthCookieNames();
  const cookieStore = await cookies();
  const accessToken = cookieStore.get(access)?.value;

  const targetPath = path.join("/");

  if (
    env.NEXT_PUBLIC_API_MOCKING === "enabled" &&
    process.env.NODE_ENV !== "production"
  ) {
    const mockRes = await handleMockAuth(req, targetPath, accessToken);
    if (mockRes) return mockRes;
  }

  const targetUrl = new URL(`${env.API_BASE_URL}/${targetPath}`);
  targetUrl.search = req.nextUrl.search;

  const headers = new Headers();
  req.headers.forEach((value, key) => {
    if (!HOP_BY_HOP_HEADERS.has(key.toLowerCase())) {
      headers.set(key, value);
    }
  });

  if (accessToken) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  const hasBody = req.method !== "GET" && req.method !== "HEAD";
  const body = hasBody ? await req.arrayBuffer() : undefined;

  let upstream: Response;
  try {
    upstream = await fetch(targetUrl.toString(), {
      method: req.method,
      headers,
      body,
      cache: "no-store",
    });
  } catch {
    return NextResponse.json(
      { error: "Unable to reach backend service" },
      { status: 502 },
    );
  }

  const responseBody = await upstream.arrayBuffer();
  const resHeaders = new Headers();
  upstream.headers.forEach((value, key) => {
    if (!HOP_BY_HOP_HEADERS.has(key.toLowerCase())) {
      resHeaders.set(key, value);
    }
  });

  const res = new NextResponse(responseBody, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers: resHeaders,
  });

  if (targetPath === "auth/logout" && upstream.ok) {
    res.cookies.delete(access);
    res.cookies.delete(refresh);
  }

  return res;
}

export const GET = forwardRequest;
export const POST = forwardRequest;
export const PUT = forwardRequest;
export const PATCH = forwardRequest;
export const DELETE = forwardRequest;
