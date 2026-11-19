/**
 * src/features/churches/ChurchList.tsx
 *
 * WHAT: Local churches: searchable list with students and mentors per church, and a detail card for the selected one
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { Search, X } from "lucide-react";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchChurches, type LocalChurch } from "./queries";

export function ChurchList() {
  const [items, , { loading, error }] = useRemoteItems<LocalChurch>([], fetchChurches);
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<LocalChurch | null>(null);

  const q = search.trim().toLowerCase();
  const filtered = items.filter((c) => `${c.name} ${c.location} ${c.pastor}`.toLowerCase().includes(q));

  return (
    <div className="flex flex-wrap items-start gap-4">
      <section className="card flex min-w-0 flex-[999_1_560px] flex-col gap-2">
        <div className="relative mb-1.5">
          <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search a church"
            aria-label="Search churches"
            className="field-soft w-full pl-10 pr-3"
          />
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr>
                <th>Church</th>
                <th>Pastor</th>
                <th>City</th>
                <th>Students</th>
                <th>Mentors</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center text-muted-foreground">
                    {loading
                      ? "Loading churches…"
                      : error
                        ? "Could not load churches."
                        : "No local churches yet. They appear here as students add their home church in the app."}
                  </td>
                </tr>
              ) : (
                filtered.map((c) => (
                  <tr
                    key={c.id}
                    aria-selected={selected?.id === c.id}
                    tabIndex={0}
                    onClick={() => setSelected(c)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        setSelected(c);
                      }
                    }}
                    className="cursor-pointer"
                  >
                    <td className="text-base font-extrabold">{c.name}</td>
                    <td>{c.pastor || "—"}</td>
                    <td>{c.location || "—"}</td>
                    <td className="font-extrabold">{c.students}</td>
                    <td className="font-extrabold">{c.mentors}</td>
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
            <h2 className="text-[22px] font-black">{selected.name}</h2>
            <button type="button" onClick={() => setSelected(null)} aria-label="Close" className="rounded-md p-1 hover:bg-blue-soft">
              <X className="h-5 w-5" aria-hidden="true" />
            </button>
          </div>
          <dl className="divide-y-[1.5px] divide-border text-[15px]">
            {(
              [
                ["Pastor", selected.pastor || "—"],
                ["City", selected.location || "—"],
                ["Students", String(selected.students)],
                ["Mentors", String(selected.mentors)],
              ] as const
            ).map(([label, value]) => (
              <div key={label} className="flex justify-between gap-3 py-2">
                <dt>{label}</dt>
                <dd className="font-extrabold">{value}</dd>
              </div>
            ))}
          </dl>
          <p className="mt-3 rounded-xl bg-blue-tint p-3 text-sm">
            Churches come from the home church each student enters when they sign up, so they are read-only here.
          </p>
        </aside>
      )}
    </div>
  );
}
