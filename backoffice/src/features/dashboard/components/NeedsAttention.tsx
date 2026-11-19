/**
 * src/features/dashboard/components/NeedsAttention.tsx
 *
 * WHAT: Pending join requests, reports, testimonies, content in review with deep links
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ChevronRight } from "lucide-react";
import type { AttentionItem } from "../queries";

export function NeedsAttention({ items }: { items: AttentionItem[] }) {
  return (
    <section className="card flex h-full flex-col gap-1">
      <h2 className="eyebrow mb-1">Needs your attention</h2>
      {items.length === 0 && <p className="py-2 text-sm text-muted-foreground">Nothing is waiting for review right now.</p>}
      <ul className="divide-y-[1.5px] divide-border">
        {items.map((item) => (
          <li key={item.id}>
            <Link href={item.href} className="flex items-center gap-3 py-2.5 hover:opacity-80">
              <span className="grid h-9 min-w-9 shrink-0 place-items-center rounded-[10px] bg-blue-soft px-2 text-sm font-extrabold text-blue">
                {item.count}
              </span>
              <span className="flex-1 text-base font-extrabold">{item.label}</span>
              <ChevronRight className="h-5 w-5 shrink-0" aria-hidden="true" />
            </Link>
          </li>
        ))}
      </ul>
    </section>
  );
}
