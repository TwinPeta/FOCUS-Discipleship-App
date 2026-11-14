/**
 * src/app/(backoffice)/moderation/reports/page.tsx
 *
 * WHAT: B7 Moderation reports: queue with reason, reporter, reported user, screenshot, L1/L2 actions
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import { ReportQueue } from "@/features/moderation/components/ReportQueue";
import type { ModerationReport } from "@/features/moderation/schemas";

export default function ModerationReportsPage() {
  const initialItems: ModerationReport[] = [];
  return <ReportQueue initialItems={initialItems} />;
}
