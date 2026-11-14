/**
 * src/app/(backoffice)/privacy/data-requests/page.tsx
 *
 * WHAT: B23 Data requests: export and deletion requests with 30-day deadline badges
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/12-privacy-consents.md
 * STATUS: implemented
 */

import { DataRequestsTable } from "@/features/privacy/components/DataRequestsTable";
import type { DataRequestRecord } from "@/features/privacy/queries";

export default function DataRequestsPage() {
  const initialItems: DataRequestRecord[] = [];
  return <DataRequestsTable initialItems={initialItems} />;
}
