/**
 * src/app/(backoffice)/privacy/page.tsx
 *
 * WHAT: Redirects to guardian consents
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: placeholder, not implemented
 */

import { redirect } from "next/navigation";

export default function PrivacyIndex() {
  redirect("/privacy/guardian-consents");
}
