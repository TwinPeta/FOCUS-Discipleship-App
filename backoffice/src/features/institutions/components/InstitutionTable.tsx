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
import { InstitutionType, type Institution, type InstitutionInput } from "@/features/institutions/schemas";
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
    <div className="grid gap-6 lg:grid-cols-3">
      <div className={selected ? "lg:col-span-2 space-y-4" : "lg:col-span-3 space-y-4"}>
        <input
          type="search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search institutions by name or city..."
          aria-label="Search institutions"
          className="w-full max-w-sm rounded-md border border-border bg-white px-3 py-2 text-sm"
        />

        <div className="overflow-x-auto rounded-card border border-border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
              <tr>
                <th className="px-4 py-3">Institution</th>
                <th className="px-4 py-3">Type</th>
                <th className="px-4 py-3">Location</th>
                <th className="px-4 py-3">Communities</th>
                <th className="px-4 py-3">Students</th>
                <th className="px-4 py-3">Sign-up list</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                    No institutions found.
                  </td>
                </tr>
              ) : (
                filtered.map((inst) => (
                  <tr key={inst.id} className="hover:bg-surface/60">
                    <td className="px-4 py-3 font-medium text-foreground">{inst.name}</td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {inst.type === InstitutionType.University ? "University" : "High school"}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {inst.city}, {inst.country}
                    </td>
                    <td className="px-4 py-3">{inst.communityCount}</td>
                    <td className="px-4 py-3">{inst.studentCount}</td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          inst.shownInSignup
                            ? "bg-emerald-100 text-emerald-800"
                            : "bg-stone-100 text-stone-700"
                        }`}
                      >
                        {inst.shownInSignup ? "Visible" : "Hidden"}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => setSelected(inst)}
                        className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                      >
                        Edit
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {selected && (
        <aside className="rounded-card border border-border bg-white p-5">
          <div className="mb-4 flex items-center justify-between">
            <h2 className="text-base font-semibold text-foreground">
              Edit {selected.name}
            </h2>
            <button
              type="button"
              onClick={() => setSelected(null)}
              className="text-xs text-muted-foreground hover:text-foreground"
            >
              Close
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
