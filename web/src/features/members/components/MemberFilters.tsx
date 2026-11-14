/**
 * src/features/members/components/MemberFilters.tsx
 *
 * WHAT: Search, campus/institution, and status filters for members list
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { MemberStatus } from "@/types/enums";

interface MemberFiltersProps {
  search: string;
  onSearchChange: (value: string) => void;
  institutionFilter: string;
  onInstitutionChange: (value: string) => void;
  institutions: string[];
  statusFilter: string;
  onStatusChange: (value: string) => void;
}

export function MemberFilters({
  search,
  onSearchChange,
  institutionFilter,
  onInstitutionChange,
  institutions,
  statusFilter,
  onStatusChange,
}: MemberFiltersProps) {
  return (
    <div className="flex flex-wrap items-center gap-3">
      <input
        type="search"
        value={search}
        onChange={(e) => onSearchChange(e.target.value)}
        placeholder="Search by name, username, or email..."
        aria-label="Search members"
        className="w-full max-w-sm rounded-md border border-border bg-white px-3 py-2 text-sm"
      />

      <select
        value={institutionFilter}
        onChange={(e) => onInstitutionChange(e.target.value)}
        aria-label="Filter by institution"
        className="rounded-md border border-border bg-white px-3 py-2 text-sm"
      >
        <option value="ALL">All institutions</option>
        {institutions.map((name) => (
          <option key={name} value={name}>
            {name}
          </option>
        ))}
      </select>

      <select
        value={statusFilter}
        onChange={(e) => onStatusChange(e.target.value)}
        aria-label="Filter by status"
        className="rounded-md border border-border bg-white px-3 py-2 text-sm"
      >
        <option value="ALL">All statuses</option>
        <option value={MemberStatus.Active}>Active</option>
        <option value={MemberStatus.Inactive}>Inactive</option>
        <option value={MemberStatus.Invited}>Invited</option>
        <option value={MemberStatus.Suspended}>Suspended</option>
      </select>
    </div>
  );
}
