/**
 * src/features/roles/components/MatrixEditor.tsx
 *
 * WHAT: Checkbox grid of modules by permission (View, Create, Edit, Approve, Delete, Export) with an own-caregroup scope
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/13-roles-audit.md
 * STATUS: implemented
 */

"use client";

import { MODULE_HINTS, type RoleMatrix } from "../api";
import type { PermissionCode } from "../queries";

const COLUMNS: { code: PermissionCode; label: string }[] = [
  { code: "V", label: "View" },
  { code: "C", label: "Create" },
  { code: "E", label: "Edit" },
  { code: "A", label: "Approve" },
  { code: "D", label: "Delete" },
  { code: "X", label: "Export" },
];

interface MatrixEditorProps {
  modules: string[];
  value: RoleMatrix;
  onChange: (next: RoleMatrix) => void;
  disabled?: boolean;
}

export function MatrixEditor({ modules, value, onChange, disabled = false }: MatrixEditorProps) {
  function toggle(module: string, code: PermissionCode) {
    const cell = value[module] ?? { codes: [] };
    const has = cell.codes.includes(code);
    let codes = has ? cell.codes.filter((c) => c !== code) : [...cell.codes, code];
    // Anything beyond viewing needs viewing; removing View clears the rest
    if (!has && code !== "V" && !codes.includes("V")) codes = ["V", ...codes];
    if (has && code === "V") codes = [];
    const next = { ...value };
    if (codes.length === 0) delete next[module];
    else next[module] = { codes, own: cell.own };
    onChange(next);
  }

  function setScope(module: string, own: boolean) {
    const cell = value[module];
    if (!cell) return;
    onChange({ ...value, [module]: { ...cell, own } });
  }

  return (
    <div className="overflow-x-auto">
      <table className="plain-table w-full border-collapse text-left text-[15px]">
        <thead>
          <tr className="border-b-2 border-ink">
            <th className="px-2 py-2" />
            {COLUMNS.map((c) => (
              <th key={c.code} className="px-2 py-2 text-center text-[13px] font-black">
                {c.label}
              </th>
            ))}
            <th className="px-2 py-2 text-center text-[13px] font-black">Scope</th>
          </tr>
        </thead>
        <tbody>
          {modules.map((module) => {
            const cell = value[module];
            return (
              <tr key={module} className="border-b border-blue-soft">
                <td className="px-2 py-2.5">
                  <p className="text-[15px] font-extrabold leading-tight">{module}</p>
                  {MODULE_HINTS[module] && <p className="text-xs opacity-80">{MODULE_HINTS[module]}</p>}
                </td>
                {COLUMNS.map((c) => (
                  <td key={c.code} className="px-2 py-2.5 text-center">
                    <input
                      type="checkbox"
                      disabled={disabled}
                      checked={Boolean(cell?.codes.includes(c.code))}
                      onChange={() => toggle(module, c.code)}
                      aria-label={`${c.label} ${module}`}
                    />
                  </td>
                ))}
                <td className="px-2 py-2.5 text-center">
                  {cell ? (
                    <select
                      value={cell.own ? "own" : "all"}
                      disabled={disabled}
                      onChange={(e) => setScope(module, e.target.value === "own")}
                      aria-label={`Scope for ${module}`}
                      className="pill-select !h-9 !px-2 text-sm"
                    >
                      <option value="all">All</option>
                      <option value="own">Own caregroup</option>
                    </select>
                  ) : (
                    <span className="opacity-60">—</span>
                  )}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
