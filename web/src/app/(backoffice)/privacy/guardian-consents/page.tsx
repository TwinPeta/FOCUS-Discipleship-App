/**
 * src/app/(backoffice)/privacy/guardian-consents/page.tsx
 *
 * WHAT: B23 Guardian consents: minors consent status and reminders
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

import { GuardianConsentTable } from "@/features/privacy/components/GuardianConsentTable";
import type { GuardianConsentRecord } from "@/features/privacy/queries";

export default function GuardianConsentsPage() {
  const initialItems: GuardianConsentRecord[] = [];
  return <GuardianConsentTable initialItems={initialItems} />;
}
