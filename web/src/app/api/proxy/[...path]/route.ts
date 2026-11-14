/**
 * src/app/api/proxy/[...path]/route.ts
 *
 * WHAT: Forwards browser API calls to the backend and attaches auth from httpOnly cookies
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { getAuthCookieNames } from "@/lib/auth/cookies";
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

  // Handle logout cookie clearing
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
