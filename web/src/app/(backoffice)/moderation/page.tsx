/**
 * src/app/(backoffice)/moderation/page.tsx
 *
 * WHAT: Redirects to the reports tab
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: placeholder, not implemented
 */

import { redirect } from "next/navigation";

export default function ModerationIndex() {
  redirect("/moderation/reports");
}
