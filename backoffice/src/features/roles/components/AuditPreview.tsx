/**
 * src/features/roles/components/AuditPreview.tsx
 *
 * WHAT: Latest audit entries with link to full log
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { fetchAuditEntries } from "@/features/audit/queries";
import { ROUTES } from "@/lib/constants/routes";
import { formatDateTime } from "@/lib/format/date";
import { useRemoteData } from "@/lib/hooks/useRemoteData";

export function AuditPreview() {
  const { data, loading, error } = useRemoteData(() => fetchAuditEntries({ search: "", action: "all", role: "all", period: "all" }));
  const entries = (data ?? []).slice(0, 5);
  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div className="flex items-center justify-between gap-2">
        <div>
          <h2 className="text-base font-semibold text-foreground">
            Recent audit activity
          </h2>
          <p className="text-xs text-muted">
            Latest security-sensitive actions recorded across the backoffice.
          </p>
        </div>
        <Link
          href={ROUTES.auditLog}
          className="inline-flex items-center gap-1 text-xs font-medium text-primary hover:underline"
        >
          <span>View full audit log</span>
          <ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
        </Link>
      </div>

      <div className="divide-y divide-border rounded-lg border border-border">
        {error && <p role="alert" className="px-3 py-2.5 text-xs text-red-700">{error}</p>}
        {!error && !loading && entries.length === 0 && (
          <p className="px-3 py-2.5 text-xs text-muted">No audit activity recorded yet.</p>
        )}
        {entries.map((entry) => (
          <div
            key={entry.id}
            className="flex flex-wrap items-center justify-between gap-2 px-3 py-2.5 text-xs"
          >
            <div>
              <span className="font-semibold text-foreground">{entry.actorName}</span>{" "}
              <span className="text-muted">· {entry.actionLabel} ·</span>{" "}
              <span className="text-foreground">{entry.target}</span>
            </div>
            <span className="text-muted">{formatDateTime(entry.occurredAt)}</span>
          </div>
        ))}
      </div>
    </section>
  );
}
