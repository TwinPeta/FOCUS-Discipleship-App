/**
 * src/features/badges/components/BadgeTable.tsx
 *
 * WHAT: Table of badges with rule description, earned count, status and edit trigger
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { Edit, Eye, EyeOff } from "lucide-react";
import { BADGE_ICONS } from "./IconPicker";
import type { Badge } from "../queries";

interface BadgeTableProps {
  badges: Badge[];
  onEditBadge: (badge: Badge) => void;
}

export function BadgeTable({ badges, onEditBadge }: BadgeTableProps) {
  if (badges.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-white p-8 text-center text-sm text-muted">
        No badges defined yet. Click &quot;New badge&quot; above to add one.
      </div>
    );
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-white shadow-sm">
      <table className="w-full border-collapse text-left text-sm">
        <thead>
          <tr className="border-b border-border bg-slate-50 text-xs font-semibold uppercase tracking-wide text-muted">
            <th className="px-4 py-3">Badge</th>
            <th className="px-4 py-3">Earning Rule</th>
            <th className="px-4 py-3 text-center">Earned Count</th>
            <th className="px-4 py-3 text-center">Profile Display</th>
            <th className="px-4 py-3 text-center">Status</th>
            <th className="px-4 py-3 text-right">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {badges.map((badge) => {
            const IconComp = BADGE_ICONS[badge.icon]?.icon ?? BADGE_ICONS.award.icon;
            return (
              <tr key={badge.id} className="hover:bg-slate-50/50">
                <td className="px-4 py-3.5">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary-soft text-primary">
                      <IconComp className="h-5 w-5" />
                    </div>
                    <div>
                      <div className="font-semibold text-foreground">{badge.name}</div>
                      <div className="line-clamp-1 text-xs text-muted">{badge.description}</div>
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3.5 text-xs text-foreground">
                  <p className="line-clamp-2">{badge.ruleDescription}</p>
                </td>
                <td className="px-4 py-3.5 text-center text-xs font-semibold text-foreground">
                  {badge.earnedCount}
                </td>
                <td className="px-4 py-3.5 text-center">
                  <span
                    className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[11px] font-medium ${
                      badge.visibleOnProfile
                        ? "bg-slate-100 text-foreground"
                        : "bg-slate-50 text-muted"
                    }`}
                  >
                    {badge.visibleOnProfile ? (
                      <>
                        <Eye className="h-3 w-3" />
                        <span>Visible</span>
                      </>
                    ) : (
                      <>
                        <EyeOff className="h-3 w-3" />
                        <span>Hidden</span>
                      </>
                    )}
                  </span>
                </td>
                <td className="px-4 py-3.5 text-center">
                  <span
                    className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium capitalize ${
                      badge.status === "active"
                        ? "bg-emerald-50 text-emerald-700"
                        : badge.status === "draft"
                          ? "bg-amber-50 text-amber-700"
                          : "bg-slate-100 text-muted"
                    }`}
                  >
                    {badge.status}
                  </span>
                </td>
                <td className="px-4 py-3.5 text-right">
                  <button
                    type="button"
                    onClick={() => onEditBadge(badge)}
                    className="inline-flex items-center gap-1 rounded-md border border-border px-2.5 py-1 text-xs font-medium text-foreground hover:bg-slate-50"
                  >
                    <Edit className="h-3 w-3" />
                    <span>Edit</span>
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
