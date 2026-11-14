/**
 * src/app/api/health/route.ts
 *
 * WHAT: Liveness endpoint for hosting checks
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: placeholder, not implemented
 */

export async function GET() {
  return Response.json({ status: "ok" });
}
