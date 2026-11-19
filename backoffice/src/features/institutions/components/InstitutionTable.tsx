/**
 * src/features/institutions/components/InstitutionTable.tsx
 *
 * WHAT: Institutions list with counts and side-panel editing
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { Search, X } from "lucide-react";
import { StatusPill } from "@/components/data-table/StatusPill";
import { institutionTypeLabel, type Institution, type InstitutionInput } from "@/features/institutions/schemas";
import { updateInstitution } from "@/features/institutions/queries";
import { InstitutionForm } from "./InstitutionForm";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchInstitutions } from "@/features/institutions/queries";

interface InstitutionTableProps {
  initialItems: Institution[];
}

export function InstitutionTable({ initialItems }: InstitutionTableProps) {
  const [items, setItems] = useRemoteItems<Institution>(initialItems, fetchInstitutions);
  const [selected, setSelected] = useState<Institution | null>(null);
  const [search, setSearch] = useState("");

  const filtered = items.filter((item) =>
    `${item.name} ${item.city} ${item.country}`
      .toLowerCase()
      .includes(search.toLowerCase()),
  );

  async function handleUpdate(values: InstitutionInput) {
    if (!selected) return;
    const updated = await updateInstitution(selected.id, values);
    setItems((prev) => prev.map((i) => (i.id === selected.id ? updated : i)));
    setSelected(null);
  }

  return (
    <div className="flex flex-wrap items-start gap-4">
      <section className="card flex min-w-0 flex-[999_1_560px] flex-col gap-2">
        <div className="relative mb-1.5">
          <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search a campus"
            aria-label="Search campuses"
            className="field-soft w-full pl-10 pr-3"
          />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr>
                <th>Campus</th>
                <th>Type</th>
                <th>City</th>
                <th>Caregroups</th>
                <th>Students</th>
                <th>Sign-up list</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center text-muted-foreground">
                    No campuses found.
                  </td>
                </tr>
              ) : (
                filtered.map((inst) => (
                  <tr
                    key={inst.id}
                    aria-selected={selected?.id === inst.id}
                    tabIndex={0}
                    onClick={() => setSelected(inst)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        setSelected(inst);
                      }
                    }}
                    className="cursor-pointer"
                  >
                    <td className="text-base font-extrabold">{inst.name}</td>
                    <td>
                      <span className="chip">{institutionTypeLabel(inst.type)}</span>
                    </td>
                    <td>
                      {inst.city}, {inst.country}
                    </td>
                    <td className="font-extrabold">{inst.communityCount}</td>
                    <td className="font-extrabold">{inst.studentCount}</td>
                    <td>
                      <StatusPill status={inst.shownInSignup ? "Visible" : "Hidden"} variant={inst.shownInSignup ? "active" : "inactive"} />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </section>

      {selected && (
        <aside className="card min-w-0 flex-[1_1_340px] lg:max-w-[400px]">
          <div className="mb-3 flex items-center justify-between gap-3">
            <h2 className="text-[22px] font-black">Edit campus</h2>
            <button
              type="button"
              onClick={() => setSelected(null)}
              aria-label="Close"
              className="rounded-md p-1 hover:bg-blue-soft"
            >
              <X className="h-5 w-5" aria-hidden="true" />
            </button>
          </div>
          <InstitutionForm
            key={selected.id}
            initial={selected}
            onSubmit={handleUpdate}
            onCancel={() => setSelected(null)}
          />
        </aside>
      )}
    </div>
  );
}
