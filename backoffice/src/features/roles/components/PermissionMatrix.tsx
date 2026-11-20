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
import { useRemoteData } from "@/lib/hooks/useRemoteData";
import { B30_LEGEND, B30_PERMISSION_GROUPS, type PermissionCode } from "../queries";
import { fetchRoles, MODULE_HINTS, type RoleDef } from "../api";

export function PermissionMatrix() {
  const [highlightCode, setHighlightCode] = useState<PermissionCode | null>(null);
  const { data } = useRemoteData(fetchRoles);
  // Roles without Backoffice access keep their column so the whole picture is visible
  const roles = data?.items ?? [];
  const modules = data?.modules ?? [];
  const groups = B30_PERMISSION_GROUPS.map((g) => ({ group: g.group, modules: g.rows.map((r) => r.module).filter((m) => modules.includes(m)) }));

  return (
    <section className="card flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-x-4 gap-y-2" role="group" aria-label="Permission legend">
        {B30_LEGEND.map((item) => {
          const active = highlightCode === item.code;
          return (
            <button
              key={item.code}
              type="button"
              onClick={() => setHighlightCode(active ? null : item.code)}
              aria-pressed={active}
              className={`inline-flex items-center gap-1.5 rounded-lg px-1.5 py-1 text-sm ${active ? "bg-grad-select" : ""}`}
            >
              <b className="grid h-6 w-6 place-items-center rounded-md border-2 border-ink bg-white text-xs font-black">{item.code}</b>
              <span>{item.label.toLowerCase()}</span>
            </button>
          );
        })}
        <span className="text-sm">
          <b>(own)</b> only their own caregroup. A dash means no access.
        </span>
      </div>

      <div className="overflow-x-auto">
        <table className="plain-table w-full border-collapse text-left text-[15px]">
          <thead>
            <tr className="border-b-2 border-ink">
              <th className="px-2 py-2" />
              {roles.map((r) => (
                <th key={r.id} id={r.slug} className="px-2 py-2 text-center text-[13px] font-black">
                  {r.name}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {groups.map((g) => (
              <Group key={g.group} group={g.group} modules={g.modules} roles={roles} highlightCode={highlightCode} />
            ))}
          </tbody>
        </table>
      </div>

      <p className="text-sm italic">Built-in roles start from the proposed matrix, to be validated with FOCUS Uganda. Edited roles show what is in force now.</p>
    </section>
  );
}

function Group({ group, modules, roles, highlightCode }: { group: string; modules: string[]; roles: RoleDef[]; highlightCode: PermissionCode | null }) {
  return (
    <>
      <tr>
        <td colSpan={roles.length + 1} className="px-2 pb-1 pt-4 text-[13px] font-black uppercase tracking-[0.08em]">
          {group}
        </td>
      </tr>
      {modules.map((module) => (
        <tr key={module} className="border-b border-blue-soft">
          <td className="px-2 py-2.5">
            <p className="text-[15px] font-extrabold leading-tight">{module}</p>
            {MODULE_HINTS[module] && <p className="text-xs opacity-80">{MODULE_HINTS[module]}</p>}
          </td>
          {roles.map((r) => {
            const cell = r.matrix[module];
            const has = Boolean(cell && cell.codes.length);
            const dimmed = highlightCode !== null && !(cell && cell.codes.includes(highlightCode));
            return (
              <td key={r.id} className={`px-2 py-2.5 text-center transition-opacity ${dimmed ? "opacity-25" : ""}`}>
                {has ? (
                  <span className="font-extrabold">
                    {cell.codes.join(" ")}
                    {cell.own && <span className="ml-1 font-semibold opacity-80">(own)</span>}
                  </span>
                ) : (
                  <span className="opacity-60">–</span>
                )}
              </td>
            );
          })}
        </tr>
      ))}
    </>
  );
}
