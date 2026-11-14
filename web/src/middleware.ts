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
    const loginUrl = new URL(ROUTES.login, req.url);
    if (pathname !== ROUTES.home) {
      loginUrl.searchParams.set("returnTo", `${pathname}${search}`);
    }
    return NextResponse.redirect(loginUrl);
  }

  // Coarse role check when token carries a mock role prefix
  if (
    accessToken === "mock:SUPER_MENTOR" &&
    !pathname.startsWith(MY_COMMUNITY_PREFIX) &&
    pathname !== ROUTES.account
  ) {
    return NextResponse.redirect(new URL(ROUTES.myCommunity, req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/health).*)"],
};
