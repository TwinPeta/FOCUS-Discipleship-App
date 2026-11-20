/**
 * src/features/content/components/ContentFilters.tsx
 *
 * WHAT: Search by title/Bible link, filter by content type and Bible link
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { Search } from "lucide-react";
import { ContentType } from "@/types/enums";

interface ContentFiltersProps {
  search: string;
  onSearchChange: (v: string) => void;
  typeFilter: string;
  onTypeChange: (v: string) => void;
}

export function ContentFilters({
  search,
  onSearchChange,
  typeFilter,
  onTypeChange,
}: ContentFiltersProps) {
  return (
    <div className="mb-1.5 flex flex-wrap items-center gap-2.5">
      <div className="relative min-w-[220px] flex-1">
      <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" aria-hidden="true" />
      <input
        type="search"
        value={search}
        onChange={(e) => onSearchChange(e.target.value)}
        placeholder="Search by title or Bible character or text"
        aria-label="Search content"
        className="field-soft w-full pl-10 pr-3"
      />
      </div>

      <select
        value={typeFilter}
        onChange={(e) => onTypeChange(e.target.value)}
        aria-label="Filter by content type"
        className="rounded-md border border-border bg-white px-3 py-2 text-sm"
      >
        <option value="ALL">All types</option>
        <option value={ContentType.Video}>Video</option>
        <option value={ContentType.Devotional}>Devotional</option>
        <option value={ContentType.Quiz}>Quiz</option>
        <option value={ContentType.Document}>Document</option>
      </select>
    </div>
  );
}
