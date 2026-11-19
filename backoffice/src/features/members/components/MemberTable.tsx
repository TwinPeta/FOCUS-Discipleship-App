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
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { StatusPill } from "@/components/data-table/StatusPill";
import { MemberDetailPanel } from "./MemberDetailPanel";
import { MemberFilters } from "./MemberFilters";
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
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap gap-2" role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            role="tab"
            aria-selected={roleTab === tab.key}
            onClick={() => setRoleTab(tab.key)}
            className="tab"
          >
            {tab.label} <span className="opacity-80">{tab.count.toLocaleString("en-US")}</span>
          </button>
        ))}
      </div>

      <div className="flex flex-wrap items-start gap-4">
        <section className="card flex min-w-0 flex-[999_1_560px] flex-col gap-2">
          <MemberFilters
            search={search}
            onSearchChange={setSearch}
            institutionFilter={institutionFilter}
            onInstitutionChange={setInstitutionFilter}
            institutions={institutions}
            statusFilter={statusFilter}
            onStatusChange={setStatusFilter}
          />

          <div className="overflow-x-auto">
            <table className="data-table w-full text-left">
              <thead>
                <tr>
                  <th>Member</th>
                  <th>Role</th>
                  <th>Specific caregroup</th>
                  <th>Last active</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0 ? (
                  <tr className="empty">
                    <td colSpan={5} className="text-center text-muted-foreground">
                      No members match your filters.
                    </td>
                  </tr>
                ) : (
                  filtered.map((member) => (
                    <tr
                      key={member.id}
                      aria-selected={selected?.id === member.id}
                      tabIndex={0}
                      onClick={() => setSelected(member)}
                      onKeyDown={(e) => {
                        if (e.key === "Enter" || e.key === " ") {
                          e.preventDefault();
                          setSelected(member);
                        }
                      }}
                      className="cursor-pointer"
                    >
                      <td>
                        <div className="flex items-center gap-2.5">
                          <InitialsAvatar name={member.fullName} />
                          <div className="min-w-0">
                            <p className="truncate text-base font-extrabold">{member.fullName}</p>
                            <p className="truncate text-[13px] opacity-80">
                              @{member.username} · {member.institutionName}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td>
                        <span className="chip">{member.customRoleName ?? ROLE_LABELS[member.role]}</span>
                      </td>
                      <td>{member.communityName ?? "No specific caregroup"}</td>
                      <td className="whitespace-nowrap text-sm">
                        {member.lastActiveAt ? formatRelativeTime(member.lastActiveAt) : "—"}
                      </td>
                      <td>
                        <StatusPill status={member.status.toLowerCase()} variant={member.status === MemberStatus.Active ? "active" : member.status === MemberStatus.Suspended ? "suspended" : "inactive"} />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </section>

        {selected && (
          <MemberDetailPanel
            member={selected}
            onUpdated={handleUpdated}
            onClose={() => setSelected(null)}
          />
        )}
      </div>
    </div>
  );
}
