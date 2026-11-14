/**
 * src/features/communities/components/CommunityTable.tsx
 *
 * WHAT: Communities list with kind, institution, super-mentor, members, and status
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { CommunityStatus, type Community } from "@/features/communities/schemas";
import { ROUTES } from "@/lib/constants/routes";
import { CommunityKind } from "@/types/enums";

interface CommunityTableProps {
  items: Community[];
}

export function CommunityTable({ items }: CommunityTableProps) {
  const [search, setSearch] = useState("");
  const [kindFilter, setKindFilter] = useState<string>("ALL");

  const filtered = items.filter((item) => {
    const matchesSearch = `${item.name} ${item.institutionName ?? ""}`
      .toLowerCase()
      .includes(search.toLowerCase());
    const matchesKind = kindFilter === "ALL" || item.kind === kindFilter;
    return matchesSearch && matchesKind;
  });

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <input
          type="search"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search communities..."
          aria-label="Search communities"
          className="w-full max-w-sm rounded-md border border-border bg-white px-3 py-2 text-sm"
        />
        <select
          value={kindFilter}
          onChange={(e) => setKindFilter(e.target.value)}
          aria-label="Filter by community kind"
          className="rounded-md border border-border bg-white px-3 py-2 text-sm"
        >
          <option value="ALL">All types</option>
          <option value={CommunityKind.Specific}>Specific</option>
          <option value={CommunityKind.General}>General</option>
        </select>
      </div>

      <div className="overflow-x-auto rounded-card border border-border bg-white">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
            <tr>
              <th className="px-4 py-3">Community</th>
              <th className="px-4 py-3">Type</th>
              <th className="px-4 py-3">Institution</th>
              <th className="px-4 py-3">Super-mentor</th>
              <th className="px-4 py-3">Members</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                  No communities found.
                </td>
              </tr>
            ) : (
              filtered.map((comm) => (
                <tr key={comm.id} className="hover:bg-surface/60">
                  <td className="px-4 py-3 font-medium text-foreground">{comm.name}</td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {comm.kind === CommunityKind.General ? "General" : "Specific"}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {comm.institutionName ?? "—"}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {comm.superMentorName ?? "Unassigned"}
                  </td>
                  <td className="px-4 py-3">{comm.memberCount}</td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                        comm.status === CommunityStatus.Active
                          ? "bg-emerald-100 text-emerald-800"
                          : "bg-stone-100 text-stone-700"
                      }`}
                    >
                      {comm.status === CommunityStatus.Active ? "Active" : "Closed"}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Link
                      href={ROUTES.communityDetail(comm.id)}
                      className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                    >
                      Manage
                    </Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
