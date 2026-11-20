/**
 * src/features/badges/components/BadgeTable.tsx
 *
 * WHAT: Table of badges with rule description, earned count, status and edit trigger
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { StatusPill } from "@/components/data-table/StatusPill";
import { BADGE_ICONS } from "./IconPicker";
import type { Badge } from "../queries";

interface BadgeTableProps {
  badges: Badge[];
  onEditBadge: (badge: Badge) => void;
  selectedId?: string | null;
}

export function BadgeTable({ badges, onEditBadge, selectedId }: BadgeTableProps) {
  return (
    <section className="card min-w-0 flex-[999_1_560px]">
      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead>
            <tr>
              <th>Badge</th>
              <th>Rule</th>
              <th>Earned</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {badges.length === 0 ? (
              <tr>
                <td colSpan={4} className="text-center text-muted-foreground">
                  No badges defined yet. Use “New badge” to add one.
                </td>
              </tr>
            ) : (
              badges.map((badge) => {
                const IconComp = BADGE_ICONS[badge.icon]?.icon ?? BADGE_ICONS.award.icon;
                return (
                  <tr
                    key={badge.id}
                    tabIndex={0}
                    aria-selected={selectedId === badge.id}
                    onClick={() => onEditBadge(badge)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        onEditBadge(badge);
                      }
                    }}
                    className="cursor-pointer"
                  >
                    <td>
                      <div className="flex items-center gap-3">
                        <span className="grid h-10 w-10 shrink-0 place-items-center rounded-full border-2 border-ink bg-grad-yellow">
                          <IconComp className="h-5 w-5" aria-hidden="true" />
                        </span>
                        <span className="text-base font-extrabold">{badge.name}</span>
                      </div>
                    </td>
                    <td>{badge.ruleDescription}</td>
                    <td className="font-extrabold">{badge.earnedCount}</td>
                    <td>
                      <StatusPill status={badge.status} variant={badge.status === "active" ? "active" : badge.status === "draft" ? "draft" : "inactive"} />
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
