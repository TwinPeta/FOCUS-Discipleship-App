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
  type AuditEntry,
  type AuditFilterState,
} from "@/features/audit/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function AuditLogPage() {
  const [filters, setFilters] = useState<AuditFilterState>({
    search: "",
    action: "all",
    role: "all",
    period: "30d",
  });
  const [entries, setEntries] = useState<AuditEntry[]>([]);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchAuditEntries(filters)
      .then((data) => {
        if (active) {
          setEntries(data);
          setLoadError(null);
        }
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    return () => {
      active = false;
    };
  }, [filters]);

  return (
    <div className="flex flex-col gap-5">
      {loadError && <ErrorState message={loadError} />}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Audit log</h1>
          <p className="mt-1 text-sm text-muted">
            Immutable record of administrative, moderation, and privacy actions.
          </p>
        </div>
        <ExportAuditButton entries={entries} />
      </div>

      <section className="card flex flex-col gap-2">
        <AuditFilters value={filters} onChange={setFilters} />
        <AuditTable entries={entries} />
      </section>
      <AuditNotice message="The audit log cannot be edited or deleted. Exporting this log records an audit event under your account." />
    </div>
  );
}
