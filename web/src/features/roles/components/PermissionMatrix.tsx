/**
 * src/features/roles/components/PermissionMatrix.tsx
 *
 * WHAT: Matrix of roles by feature with V, C, E, A, D, X markers (B30 Backoffice Permissions)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import {
  B30_LEGEND,
  B30_PERMISSION_GROUPS,
  B30_ROLE_ORDER,
  type PermissionCode,
} from "../queries";

const CODE_STYLES: Record<PermissionCode, string> = {
  V: "bg-slate-100 text-slate-800 border-slate-300",
  C: "bg-emerald-50 text-emerald-800 border-emerald-300",
  E: "bg-sky-50 text-sky-800 border-sky-300",
  A: "bg-amber-50 text-amber-800 border-amber-300",
  D: "bg-rose-50 text-rose-800 border-rose-300",
  X: "bg-violet-50 text-violet-800 border-violet-300",
};

export function PermissionMatrix() {
  const [highlightCode, setHighlightCode] = useState<PermissionCode | null>(null);

  return (
    <section className="space-y-4 rounded-xl border border-border bg-white p-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-base font-semibold text-foreground">
            Backoffice permissions matrix (B30)
          </h2>
          <p className="mt-1 text-xs text-muted">
            Click a permission code to highlight all modules where that capability applies.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-1.5" role="group" aria-label="Permission legend">
          {B30_LEGEND.map((item) => {
            const active = highlightCode === item.code;
            return (
              <button
                key={item.code}
                type="button"
                onClick={() => setHighlightCode(active ? null : item.code)}
                className={`inline-flex items-center gap-1.5 rounded-md border px-2 py-1 text-xs transition ${
                  active
                    ? "border-primary bg-primary-soft font-semibold text-foreground"
                    : "border-border bg-white text-muted hover:text-foreground"
                }`}
              >
                <span
                  className={`inline-flex h-4 w-4 items-center justify-center rounded border text-[10px] font-bold ${CODE_STYLES[item.code]}`}
                >
                  {item.code}
                </span>
                <span>{item.label}</span>
              </button>
            );
          })}
          <span className="ml-1 inline-flex items-center rounded-md border border-dashed border-border px-2 py-1 text-[11px] text-muted">
            (own) = only their own community
          </span>
        </div>
      </div>

      <div className="overflow-x-auto rounded-lg border border-border">
        <table className="w-full border-collapse text-left text-xs">
          <thead>
            <tr className="border-b border-border bg-slate-50 text-[11px] font-semibold uppercase tracking-wide text-muted">
              <th className="px-3 py-2.5">Module</th>
              {B30_ROLE_ORDER.map((role) => (
                <th key={role} className="px-3 py-2.5 text-center">
                  {ROLE_LABELS[role]}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {B30_PERMISSION_GROUPS.map((group) => (
              <GroupRows
                key={group.group}
                group={group.group}
                rows={group.rows}
                highlightCode={highlightCode}
              />
            ))}
          </tbody>
        </table>
      </div>

      <p className="text-xs italic text-muted">
        Proposed matrix, to be validated with FOCUS Uganda.
      </p>
    </section>
  );
}

function GroupRows({
  group,
  rows,
  highlightCode,
}: {
  group: string;
  rows: (typeof B30_PERMISSION_GROUPS)[number]["rows"];
  highlightCode: PermissionCode | null;
}) {
  return (
    <>
      <tr className="border-b border-border bg-slate-50/70">
        <td
          colSpan={B30_ROLE_ORDER.length + 1}
          className="px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wider text-foreground"
        >
          {group}
        </td>
      </tr>
      {rows.map((row) => (
        <tr key={row.module} className="border-b border-border last:border-b-0 hover:bg-slate-50/50">
          <td className="px-3 py-2.5 font-medium text-foreground">{row.module}</td>
          {B30_ROLE_ORDER.map((role) => {
            const entry = row.cells[role];
            const hasCodes = entry.codes.length > 0;
            const dimmed =
              highlightCode !== null && !entry.codes.includes(highlightCode);

            return (
              <td
                key={role}
                className={`px-3 py-2.5 text-center transition-opacity ${
                  dimmed ? "opacity-30" : "opacity-100"
                }`}
              >
                {hasCodes ? (
                  <div className="inline-flex flex-wrap items-center justify-center gap-1">
                    {entry.codes.map((code) => (
                      <span
                        key={code}
                        className={`inline-flex h-5 min-w-[20px] items-center justify-center rounded border px-1 text-[11px] font-semibold ${CODE_STYLES[code]}`}
                      >
                        {code}
                      </span>
                    ))}
                    {entry.ownOnly && (
                      <span className="ml-0.5 rounded bg-slate-100 px-1 py-0.5 text-[10px] font-medium text-muted">
                        (own)
                      </span>
                    )}
                  </div>
                ) : (
                  <span className="text-muted">–</span>
                )}
              </td>
            );
          })}
        </tr>
      ))}
    </>
  );
}
