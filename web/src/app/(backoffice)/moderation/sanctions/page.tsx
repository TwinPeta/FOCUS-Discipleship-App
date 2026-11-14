/**
 * src/app/(backoffice)/moderation/sanctions/page.tsx
 *
 * WHAT: B18 Moderation sanctions: warnings and suspensions with reason, author, date and reinstate
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import { SanctionsTable } from "@/features/moderation/components/SanctionsTable";
import type { SanctionRecord } from "@/features/moderation/schemas";

export default function ModerationSanctionsPage() {
  const initialItems: SanctionRecord[] = [];
  return <SanctionsTable initialItems={initialItems} />;
}
