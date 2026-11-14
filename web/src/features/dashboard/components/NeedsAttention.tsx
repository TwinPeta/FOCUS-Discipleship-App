/**
 * src/features/dashboard/components/NeedsAttention.tsx
 *
 * WHAT: Pending join requests, reports, testimonies, content in review with deep links
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ArrowRight } from "lucide-react";
import type { AttentionItem } from "../queries";

export function NeedsAttention({ items }: { items: AttentionItem[] }) {
  return (
    <section className="space-y-3 rounded-xl border border-border bg-white p-5">
      <div>
        <h2 className="text-base font-semibold text-foreground">
          Needs your attention
        </h2>
        <p className="text-xs text-muted">
          Items currently queued for staff review or approval.
        </p>
      </div>

      <div className="grid gap-2.5 sm:grid-cols-2">
        {items.map((item) => (
          <Link
            key={item.id}
            href={item.href}
            className="flex items-center justify-between rounded-lg border border-border px-3.5 py-3 transition hover:border-primary hover:bg-primary-soft/40"
          >
            <div>
              <p className="text-xs font-medium text-muted">{item.label}</p>
              <p className="mt-0.5 text-lg font-semibold text-foreground">
                {item.count}
              </p>
            </div>
            <ArrowRight className="h-4 w-4 text-muted" aria-hidden="true" />
          </Link>
        ))}
      </div>
    </section>
  );
}
