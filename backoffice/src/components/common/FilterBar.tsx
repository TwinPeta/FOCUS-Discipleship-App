/**
 * src/components/common/FilterBar.tsx
 *
 * WHAT: Search input and filter selects row with clear button
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { Search, X } from "lucide-react";

interface FilterBarProps {
  searchQuery?: string;
  onSearchChange?: (query: string) => void;
  searchPlaceholder?: string;
  children?: ReactNode;
  onClearFilters?: () => void;
  hasActiveFilters?: boolean;
}

export function FilterBar({
  searchQuery = "",
  onSearchChange,
  searchPlaceholder = "Search records…",
  children,
  onClearFilters,
  hasActiveFilters,
}: FilterBarProps) {
  return (
    <div className="card flex flex-wrap items-center justify-between gap-3">
      <div className="flex flex-1 flex-wrap items-center gap-3 min-w-[240px]">
        {onSearchChange && (
          <div className="relative flex-1 min-w-[200px] max-w-md">
            <Search className="pointer-events-none absolute left-3.5 top-3.5 h-[18px] w-[18px] text-muted" />
            <input
              type="search"
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder={searchPlaceholder}
              className="field-soft w-full pl-10 pr-3 text-foreground placeholder:text-muted"
            />
          </div>
        )}

        {children}
      </div>

      {hasActiveFilters && onClearFilters && (
        <button
          type="button"
          onClick={onClearFilters}
          className="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-sm font-bold text-blue underline"
        >
          <X className="h-3.5 w-3.5" />
          <span>Clear filters</span>
        </button>
      )}
    </div>
  );
}
