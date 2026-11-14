/**
 * src/features/members/components/MemberTable.tsx
 *
 * WHAT: Members table with role tabs with counts, filters, and detail side panel
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import type { Member } from "@/features/members/schemas";
import { formatRelativeTime } from "@/lib/format/date";
import { ROLE_LABELS } from "@/lib/permissions/roles";
import { MemberStatus, Role } from "@/types/enums";
import { MemberDetailPanel } from "./MemberDetailPanel";
import { MemberFilters } from "./MemberFilters";
import { MinorBadge } from "./MinorBadge";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchMembers } from "@/features/members/queries";

interface MemberTableProps {
  initialItems: Member[];
}

export function MemberTable({ initialItems }: MemberTableProps) {
  const [items, setItems] = useRemoteItems<Member>(initialItems, fetchMembers);
  const [roleTab, setRoleTab] = useState<string>("ALL");
  const [search, setSearch] = useState("");
  const [institutionFilter, setInstitutionFilter] = useState("ALL");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [selected, setSelected] = useState<Member | null>(null);

  const institutions = Array.from(new Set(items.map((m) => m.institutionName)));

  const tabs = [
    { key: "ALL", label: "All", count: items.length },
    {
      key: Role.Student,
      label: "Students",
      count: items.filter((m) => m.role === Role.Student).length,
    },
    {
      key: Role.Mentor,
      label: "Mentors",
      count: items.filter((m) => m.role === Role.Mentor).length,
    },
    {
      key: Role.SuperMentor,
      label: "Super-mentors",
      count: items.filter((m) => m.role === Role.SuperMentor).length,
    },
    {
      key: Role.Alumni,
      label: "Alumni",
      count: items.filter((m) => m.role === Role.Alumni).length,
    },
  ];

  const filtered = items.filter((m) => {
    if (roleTab !== "ALL" && m.role !== roleTab) return false;
    if (institutionFilter !== "ALL" && m.institutionName !== institutionFilter) return false;
    if (statusFilter !== "ALL" && m.status !== statusFilter) return false;
    if (search.trim()) {
      const q = search.toLowerCase();
      return (
        m.fullName.toLowerCase().includes(q) ||
        m.username.toLowerCase().includes(q) ||
        m.email.toLowerCase().includes(q)
      );
    }
    return true;
  });

  function handleUpdated(updated: Member) {
    setItems((prev) => prev.map((m) => (m.id === updated.id ? updated : m)));
    setSelected(updated);
  }

  return (
    <div className="grid gap-6 lg:grid-cols-3">
      <div className={selected ? "lg:col-span-2 space-y-4" : "lg:col-span-3 space-y-4"}>
        <div className="flex flex-wrap gap-2 border-b border-border pb-2" role="tablist">
          {tabs.map((tab) => (
            <button
              key={tab.key}
              type="button"
              role="tab"
              aria-selected={roleTab === tab.key}
              onClick={() => setRoleTab(tab.key)}
              className={`rounded-md px-3 py-1.5 text-sm font-medium ${
                roleTab === tab.key
                  ? "bg-primary text-foreground"
                  : "text-muted-foreground hover:bg-surface"
              }`}
            >
              {tab.label} ({tab.count})
            </button>
          ))}
        </div>

        <MemberFilters
          search={search}
          onSearchChange={setSearch}
          institutionFilter={institutionFilter}
          onInstitutionChange={setInstitutionFilter}
          institutions={institutions}
          statusFilter={statusFilter}
          onStatusChange={setStatusFilter}
        />

        <div className="overflow-x-auto rounded-card border border-border bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
              <tr>
                <th className="px-4 py-3">Member</th>
                <th className="px-4 py-3">Role</th>
                <th className="px-4 py-3">Institution</th>
                <th className="px-4 py-3">Last active</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">
                    No members match your filters.
                  </td>
                </tr>
              ) : (
                filtered.map((member) => (
                  <tr key={member.id} className="hover:bg-surface/60">
                    <td className="px-4 py-3">
                      <p className="font-medium text-foreground">{member.fullName}</p>
                      <p className="text-xs text-muted-foreground">{member.email}</p>
                      {member.isMinor && (
                        <div className="mt-1">
                          <MinorBadge consentStatus={member.guardianConsentStatus} />
                        </div>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {ROLE_LABELS[member.role]}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {member.institutionName}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {member.lastActiveAt ? formatRelativeTime(member.lastActiveAt) : "—"}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          member.status === MemberStatus.Active
                            ? "bg-emerald-100 text-emerald-800"
                            : member.status === MemberStatus.Suspended
                              ? "bg-red-100 text-red-800"
                              : "bg-stone-100 text-stone-700"
                        }`}
                      >
                        {member.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-right">
                      <button
                        type="button"
                        onClick={() => setSelected(member)}
                        className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                      >
                        View
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
        <MemberDetailPanel
          member={selected}
          onUpdated={handleUpdated}
          onClose={() => setSelected(null)}
        />
      )}
    </div>
  );
}
