/**
 * src/app/api/proxy/[...path]/route.ts
 *
 * WHAT: Forwards browser API calls to the backend, handing over the httpOnly session cookie and relaying Set-Cookie. No session logic lives here.
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
  // fetch() already decompressed the body, so these would describe bytes we no longer have
  "content-encoding",
  "content-length",
]);

async function forwardRequest(
  req: NextRequest,
  context: { params: Promise<{ path: string[] }> },
) {
  const { path } = await context.params;
  const env = getServerEnv();
  const { access } = getAuthCookieNames();
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

  // Sessions are owned by the API: the cookie is an opaque handle that the API looks up on every request.
  // The proxy only hands it over (and relays the API's Set-Cookie back); it never reads or decides anything.
  if (accessToken) {
    headers.set("cookie", `${access}=${encodeURIComponent(accessToken)}`);
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
    const k = key.toLowerCase();
    if (!HOP_BY_HOP_HEADERS.has(k) && k !== "set-cookie") {
      resHeaders.set(key, value);
    }
  });
  // Keep every cookie (forEach/set would keep only the last one)
  for (const cookie of upstream.headers.getSetCookie()) {
    resHeaders.append("set-cookie", cookie);
  }

  // 204/205/304 must not carry a body (an empty one makes the Response constructor throw)
  const noBody = [204, 205, 304].includes(upstream.status);
  const res = new NextResponse(noBody ? null : responseBody, {
    status: upstream.status,
    statusText: upstream.statusText,
    headers: resHeaders,
  });

  return res;
}

export const GET = forwardRequest;
export const POST = forwardRequest;
export const PUT = forwardRequest;
export const PATCH = forwardRequest;
export const DELETE = forwardRequest;
