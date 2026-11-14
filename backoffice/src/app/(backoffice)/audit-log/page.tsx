/**
 * src/app/(backoffice)/audit-log/page.tsx
 *
 * WHAT: B26 Audit log: search, action, role and date filters, export
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { AuditNotice } from "@/components/common/AuditNotice";
import { AuditFilters } from "@/features/audit/components/AuditFilters";
import { AuditTable } from "@/features/audit/components/AuditTable";
import { ExportAuditButton } from "@/features/audit/components/ExportAuditButton";
import {
  fetchAuditEntries,
  MOCK_AUDIT_ENTRIES,
  type AuditEntry,
  type AuditFilterState,
} from "@/features/audit/queries";

export default function AuditLogPage() {
  const [filters, setFilters] = useState<AuditFilterState>({
    search: "",
    action: "all",
    role: "all",
    period: "30d",
  });
  const [entries, setEntries] = useState<AuditEntry[]>(MOCK_AUDIT_ENTRIES);

  useEffect(() => {
    let active = true;
    fetchAuditEntries(filters).then((data) => {
      if (active) setEntries(data);
    });
    return () => {
      active = false;
    };
  }, [filters]);

  return (
    <main className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">Audit log</h1>
          <p className="mt-1 text-sm text-muted">
            Immutable record of administrative, moderation, and privacy actions.
          </p>
        </div>
        <ExportAuditButton entries={entries} />
      </div>

      <AuditNotice message="Audit entries are immutable. Exporting this log records an audit event under your account." />
      <AuditFilters value={filters} onChange={setFilters} />
      <AuditTable entries={entries} />
    </main>
  );
}
