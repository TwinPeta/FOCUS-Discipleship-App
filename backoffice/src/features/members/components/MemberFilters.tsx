/**
 * src/features/members/components/MemberFilters.tsx
 *
 * WHAT: Search, campus/institution, and status filters for members list
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { Search } from "lucide-react";
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
    <div className="mb-1.5 flex flex-wrap items-center gap-2.5">
      <div className="relative min-w-[220px] flex-1">
        <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
        <input
          type="search"
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          placeholder="Search by name, username or email"
          aria-label="Search members"
          className="field-soft w-full pl-10 pr-3"
        />
      </div>

      <select
        value={institutionFilter}
        onChange={(e) => onInstitutionChange(e.target.value)}
        aria-label="Filter by campus"
        className="pill-select"
      >
        <option value="ALL">All campuses</option>
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
        className="pill-select"
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
