/**
 * src/features/roles/components/MobileMatrix.tsx
 *
 * WHAT: B31 matrix of what each role can do in the mobile app
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

import { Check } from "lucide-react";
import { MOBILE_MATRIX, MOBILE_ROLE_COLUMNS } from "../mobile-matrix";

export function MobileMatrix() {
  return (
    <section className="card flex flex-col gap-2">
      <p className="text-[15px]">
        What each role can do in the mobile app. Content admins and system admins use the Backoffice only.
      </p>
      <div className="overflow-x-auto">
        <table className="plain-table w-full border-collapse text-left text-[15px]">
          <thead>
            <tr className="border-b-2 border-ink">
              <th className="px-2 py-2" />
              {MOBILE_ROLE_COLUMNS.map((c) => (
                <th key={c} className="px-2 py-2 text-center text-[13px] font-black">
                  {c}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {MOBILE_MATRIX.map((group) => (
              <MobileGroupRows key={group.group} group={group} />
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function MobileGroupRows({ group }: { group: (typeof MOBILE_MATRIX)[number] }) {
  return (
    <>
      <tr>
        <td colSpan={MOBILE_ROLE_COLUMNS.length + 1} className="px-2 pb-1 pt-4 text-[13px] font-black uppercase tracking-[0.08em]">
          {group.group}
        </td>
      </tr>
      {group.rows.map((row) => (
        <tr key={row.feature} className="border-b border-blue-soft">
          <td className="px-2 py-2.5">
            <p className="text-[15px] font-extrabold leading-tight">{row.feature}</p>
            {row.hint && <p className="text-xs opacity-80">{row.hint}</p>}
          </td>
          {row.cells.map((cell, i) => (
            <td key={MOBILE_ROLE_COLUMNS[i]} className="px-2 py-2.5 text-center">
              {cell.allowed ? (
                <span className="inline-flex flex-col items-center gap-0.5">
                  <span className="grid h-[30px] w-[30px] place-items-center rounded-full border-2 border-ink bg-grad-yellow">
                    <Check className="h-4 w-4" strokeWidth={3} aria-label="Allowed" />
                  </span>
                  {cell.note && <span className="chip">{cell.note}</span>}
                </span>
              ) : (
                <span className="opacity-60" aria-label="Not allowed">–</span>
              )}
            </td>
          ))}
        </tr>
      ))}
    </>
  );
}
