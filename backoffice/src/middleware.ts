/**
 * src/middleware.ts
 *
 * WHAT: Coarse protection: unauthenticated to /login; super-mentors kept inside /my-community
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { NextResponse, type NextRequest } from "next/server";
import { publicOrigin } from "@/lib/auth/publicOrigin";
import { AUTH_ROUTES, ROUTES } from "@/lib/constants/routes";

const ACCESS_COOKIE_NAME = process.env.AUTH_ACCESS_COOKIE || "fcu_access";

/** Redirect to the address the browser used, not the server's internal one (see lib/auth/publicOrigin.ts). */
function redirectTo(req: NextRequest, location: string): NextResponse {
  const origin = publicOrigin(req.headers, req.nextUrl, process.env.NODE_ENV === "production");
  return NextResponse.redirect(new URL(location, origin));
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

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/health).*)"],
};
