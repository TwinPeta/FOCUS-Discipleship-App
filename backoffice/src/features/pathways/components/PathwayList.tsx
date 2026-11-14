/**
 * src/features/pathways/components/PathwayList.tsx
 *
 * WHAT: Table of pathways with steps, learners count, locked state and action links
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { Edit, Lock, Unlock, Users } from "lucide-react";
import { ROUTES } from "@/lib/constants/routes";
import type { Pathway } from "../queries";

interface PathwayListProps {
  pathways: Pathway[];
  onDelete?: (id: string) => void;
}

export function PathwayList({ pathways }: PathwayListProps) {
  if (pathways.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-white p-8 text-center text-sm text-muted">
        No pathways created yet. Click &quot;New pathway&quot; above to create the first discipleship track.
      </div>
    );
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-white shadow-sm">
      <table className="w-full border-collapse text-left text-sm">
        <thead>
          <tr className="border-b border-border bg-slate-50 text-xs font-semibold uppercase tracking-wide text-muted">
            <th className="px-4 py-3">Pathway</th>
            <th className="px-4 py-3">Level / Theme</th>
            <th className="px-4 py-3 text-center">Steps</th>
            <th className="px-4 py-3 text-center">Active Learners</th>
            <th className="px-4 py-3">Unlock rule</th>
            <th className="px-4 py-3 text-center">Status</th>
            <th className="px-4 py-3 text-right">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {pathways.map((pw) => (
            <tr key={pw.id} className="hover:bg-slate-50/50">
              <td className="px-4 py-3.5">
                <div className="font-semibold text-foreground">{pw.name}</div>
                {pw.description && (
                  <div className="line-clamp-1 text-xs text-muted">{pw.description}</div>
                )}
                {pw.badgeName && (
                  <span className="mt-1 inline-block text-[11px] font-medium text-amber-700 bg-amber-50 px-2 py-0.5 rounded">
                    Awards: {pw.badgeName}
                  </span>
                )}
              </td>
              <td className="px-4 py-3.5 text-xs">
                <span className="font-medium text-foreground">{pw.theme}</span>
                <span className="ml-1 text-muted">({pw.level})</span>
              </td>
              <td className="px-4 py-3.5 text-center text-xs font-medium text-foreground">
                {pw.steps.length} {pw.steps.length === 1 ? "step" : "steps"}
              </td>
              <td className="px-4 py-3.5 text-center text-xs text-foreground">
                <span className="inline-flex items-center gap-1 font-medium">
                  <Users className="h-3.5 w-3.5 text-muted" />
                  {pw.learnersCount}
                </span>
              </td>
              <td className="px-4 py-3.5 text-xs text-muted">
                <div className="flex items-center gap-1.5">
                  {pw.unlockRule === "none" ? (
                    <Unlock className="h-3.5 w-3.5 text-emerald-600" />
                  ) : (
                    <Lock className="h-3.5 w-3.5 text-amber-600" />
                  )}
                  <span className="line-clamp-1">{pw.lockedUntilInfo ?? pw.unlockRule}</span>
                </div>
              </td>
              <td className="px-4 py-3.5 text-center">
                <span
                  className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                    pw.published
                      ? "bg-emerald-50 text-emerald-700"
                      : "bg-slate-100 text-muted"
                  }`}
                >
                  {pw.published ? "Published" : "Draft"}
                </span>
              </td>
              <td className="px-4 py-3.5 text-right">
                <Link
                  href={ROUTES.pathwayDetail(pw.id)}
                  className="inline-flex items-center gap-1 rounded-md border border-border px-2.5 py-1 text-xs font-medium text-foreground hover:bg-slate-50"
                >
                  <Edit className="h-3 w-3" />
                  <span>Edit</span>
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
