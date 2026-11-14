/**
 * src/app/api/proxy/[...path]/route.ts
 *
 * WHAT: Forwards browser API calls to the backend and attaches auth from httpOnly cookies
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: placeholder, not implemented
 */

export async function GET() {
  return Response.json({ error: "Not implemented" }, { status: 501 });
}

export async function POST() {
  return Response.json({ error: "Not implemented" }, { status: 501 });
}

export async function PUT() {
  return Response.json({ error: "Not implemented" }, { status: 501 });
}

export async function PATCH() {
  return Response.json({ error: "Not implemented" }, { status: 501 });
}

export async function DELETE() {
  return Response.json({ error: "Not implemented" }, { status: 501 });
}
