/**
 * src/features/roles/components/AuditPreview.tsx
 *
 * WHAT: Latest audit entries with link to full log
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";

export interface AuditPreviewItem {
  id: string;
  actor: string;
  action: string;
  target: string;
  timestamp: string;
}

const DEFAULT_RECENT_ENTRIES: AuditPreviewItem[] = [
  {
    id: "aud-101",
    actor: "Sarah K. (System admin)",
    action: "Updated role",
    target: "Peter O. -> Super-mentor (Makerere)",
    timestamp: "Today, 09:42",
  },
  {
    id: "aud-102",
    actor: "David M. (Content admin)",
    action: "Published devotional",
    target: "Walking in Faith — Week 4",
    timestamp: "Yesterday, 16:15",
  },
  {
    id: "aud-103",
    actor: "Sarah K. (System admin)",
    action: "Exported audit log",
    target: "Last 30 days (CSV)",
    timestamp: "Yesterday, 11:08",
  },
];

export function AuditPreview({
  entries = DEFAULT_RECENT_ENTRIES,
}: {
  entries?: AuditPreviewItem[];
}) {
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
        {entries.map((entry) => (
          <div
            key={entry.id}
            className="flex flex-wrap items-center justify-between gap-2 px-3 py-2.5 text-xs"
          >
            <div>
              <span className="font-semibold text-foreground">{entry.actor}</span>{" "}
              <span className="text-muted">· {entry.action} ·</span>{" "}
              <span className="text-foreground">{entry.target}</span>
            </div>
            <span className="text-muted">{entry.timestamp}</span>
          </div>
        ))}
      </div>
    </section>
  );
}
