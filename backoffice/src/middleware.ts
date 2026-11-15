/**
 * src/middleware.ts
 *
 * WHAT: Coarse protection: unauthenticated to /login; super-mentors kept inside /my-community
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { NextResponse, type NextRequest } from "next/server";
import { AUTH_ROUTES, MY_COMMUNITY_PREFIX, ROUTES } from "@/lib/constants/routes";

const ACCESS_COOKIE_NAME = process.env.AUTH_ACCESS_COOKIE || "fcu_access";

/**
 * Redirect using the public host. Behind nginx, req.url carries the internal address (127.0.0.1:3001), so
 * `new URL(path, req.url)` would send users there; the browser's own host arrives in the forwarded headers.
 */
function redirectTo(req: NextRequest, location: string): NextResponse {
  const host = req.headers.get("x-forwarded-host") ?? req.headers.get("host") ?? req.nextUrl.host;
  const proto = (req.headers.get("x-forwarded-proto") ?? req.nextUrl.protocol.replace(":", "")).split(",")[0].trim();
  return NextResponse.redirect(new URL(location, `${proto}://${host.split(",")[0].trim()}`));
}

function isPublicPath(pathname: string): boolean {
  if (AUTH_ROUTES.some((route) => pathname === route || pathname.startsWith(`${route}/`))) {
    return true;
  }
  if (pathname === ROUTES.forbidden || pathname.startsWith("/api/")) {
    return true;
  }
  return false;
}

export function middleware(req: NextRequest) {
  const { pathname, search } = req.nextUrl;
  const accessToken = req.cookies.get(ACCESS_COOKIE_NAME)?.value;

  if (isPublicPath(pathname)) {
    return NextResponse.next();
  }

  if (!accessToken) {
    const query =
      pathname !== ROUTES.home
        ? `?returnTo=${encodeURIComponent(`${pathname}${search}`)}`
        : "";
    return redirectTo(req, `${ROUTES.login}${query}`);
  }

  // Coarse role check when token carries a mock role prefix
  if (
    accessToken === "mock:SUPER_MENTOR" &&
    !pathname.startsWith(MY_COMMUNITY_PREFIX) &&
    pathname !== ROUTES.account
  ) {
    return redirectTo(req, ROUTES.myCommunity);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/health).*)"],
};
