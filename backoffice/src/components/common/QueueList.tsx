/**
 * src/components/common/QueueList.tsx
 *
 * WHAT: List of review items shown as selectable pill-cards (title, status chip, two detail lines), as in the design's
 *       moderation queues
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { StatusPill } from "@/components/data-table/StatusPill";

export interface QueueItem {
  id: string;
  title: string;
  status: string;
  /** Tone for the status chip; defaults to the status text */
  variant?: "active" | "pending" | "inactive" | "suspended";
  lines: string[];
}

interface QueueListProps {
  items: QueueItem[];
  selectedId?: string | null;
  onSelect: (id: string) => void;
  emptyText: string;
}

export function QueueList({ items, selectedId, onSelect, emptyText }: QueueListProps) {
  return (
    <section className="card flex flex-col gap-2">
      {items.length === 0 ? (
        <p className="py-6 text-center text-muted-foreground">{emptyText}</p>
      ) : (
        <ul className="flex flex-col gap-2">
          {items.map((item) => (
            <li key={item.id}>
              <button
                type="button"
                onClick={() => onSelect(item.id)}
                aria-pressed={selectedId === item.id}
                className={`row-card block w-full px-3.5 py-3 text-left ${selectedId === item.id ? "is-selected" : ""}`}
              >
                <span className="flex items-center justify-between gap-3">
                  <span className="text-base font-extrabold">{item.title}</span>
                  <StatusPill status={item.status} variant={item.variant} />
                </span>
                {item.lines.map((line) => (
                  <span key={line} className="block text-[13px] opacity-80">
                    {line}
                  </span>
                ))}
              </button>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
