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
import { Search } from "lucide-react";
import { getInitials } from "@/components/common/InitialsAvatar";
import { StatusPill } from "@/components/data-table/StatusPill";
import { CommunityStatus, type Community } from "@/features/communities/schemas";
import { ROUTES } from "@/lib/constants/routes";
import { CommunityKind } from "@/types/enums";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchCommunities } from "@/features/communities/queries";

interface CommunityTableProps {
  items: Community[];
}

export function CommunityTable({ items: seedItems }: CommunityTableProps) {
  const [items] = useRemoteItems<Community>(seedItems, fetchCommunities);
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
    <section className="card flex flex-col gap-2">
      <div className="mb-1.5 flex flex-wrap items-center gap-2.5">
        <div className="relative min-w-[220px] flex-1">
          <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
          <input
            type="search"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search a caregroup"
            aria-label="Search caregroups"
            className="field-soft w-full pl-10 pr-3"
          />
        </div>
        <select
          value={kindFilter}
          onChange={(e) => setKindFilter(e.target.value)}
          aria-label="Filter by caregroup kind"
          className="pill-select"
        >
          <option value="ALL">All types</option>
          <option value={CommunityKind.Specific}>Specific</option>
          <option value={CommunityKind.General}>General</option>
        </select>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left">
          <thead>
            <tr>
              <th>Cover</th>
              <th>Caregroup</th>
              <th>Super-mentor</th>
              <th>Members</th>
              <th>Status</th>
              <th className="text-right">
                <span className="sr-only">Actions</span>
              </th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={6} className="text-center text-muted-foreground">
                  No caregroups found.
                </td>
              </tr>
            ) : (
              filtered.map((comm) => {
                const general = comm.kind === CommunityKind.General;
                return (
                  <tr key={comm.id}>
                    <td className="w-[88px]">
                      <span className="grid h-10 w-[68px] place-items-center rounded-[10px] border-2 border-ink bg-grad-yellow text-sm font-black">
                        {general ? "GEN" : getInitials(comm.name).slice(0, 2)}
                      </span>
                    </td>
                    <td>
                      <p className="text-base font-extrabold">{general ? `${comm.institutionName ?? ""} general caregroup`.trim() : comm.name}</p>
                      <p className="text-[13px] opacity-80">
                        {comm.institutionName ?? "—"} · {general ? "General" : "Specific"}
                      </p>
                    </td>
                    <td>{comm.superMentorName ?? (general ? "All campus" : "Unassigned")}</td>
                    <td className="font-extrabold">{comm.memberCount}</td>
                    <td>
                      <StatusPill
                        status={comm.status === CommunityStatus.Active ? "Active" : "Closed"}
                        variant={comm.status === CommunityStatus.Active ? "active" : "inactive"}
                      />
                    </td>
                    <td className="text-right">
                      <Link href={ROUTES.communityDetail(comm.id)} className="btn btn-secondary btn-sm">
                        Manage
                      </Link>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}
