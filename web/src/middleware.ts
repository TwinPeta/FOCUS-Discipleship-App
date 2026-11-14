/**
 * src/middleware.ts
 *
 * WHAT: Coarse protection: unauthenticated to /login; super-mentors kept inside /my-community
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: placeholder, not implemented
 */

import { NextResponse, type NextRequest } from "next/server";

export function middleware(_req: NextRequest) {
  // TODO: unauthenticated -> /login; super-mentors kept inside /my-community (see docs/features/01-staff-access.md)
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api/health).*)"],
};
