/**
 * src/app/page.tsx
 *
 * WHAT: Root: redirects signed-in staff to their home (dashboard or my-community), others to /login
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: placeholder, not implemented
 */

import { redirect } from "next/navigation";

export default function Home() {
  // TODO: read the session: staff -> /dashboard, super-mentor -> /my-community, otherwise /login
  redirect("/dashboard");
}
