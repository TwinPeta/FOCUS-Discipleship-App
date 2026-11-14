/**
 * src/features/content/components/ContentFilters.tsx
 *
 * WHAT: Search by title/Bible link, filter by content type and Bible link
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

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
    <div className="flex flex-wrap items-center gap-3">
      <input
        type="search"
        value={search}
        onChange={(e) => onSearchChange(e.target.value)}
        placeholder="Search by title or Bible character/text..."
        aria-label="Search content"
        className="w-full max-w-sm rounded-md border border-border bg-white px-3 py-2 text-sm"
      />

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
