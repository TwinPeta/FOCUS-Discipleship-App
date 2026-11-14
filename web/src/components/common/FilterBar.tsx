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
    <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-white p-3.5 shadow-xs">
      <div className="flex flex-1 flex-wrap items-center gap-3 min-w-[240px]">
        {onSearchChange && (
          <div className="relative flex-1 min-w-[200px] max-w-sm">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted pointer-events-none" />
            <input
              type="search"
              value={searchQuery}
              onChange={(e) => onSearchChange(e.target.value)}
              placeholder={searchPlaceholder}
              className="w-full rounded-md border border-border pl-9 pr-3 py-1.5 text-xs text-foreground placeholder:text-muted focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
        )}

        {children}
      </div>

      {hasActiveFilters && onClearFilters && (
        <button
          type="button"
          onClick={onClearFilters}
          className="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-medium text-muted hover:text-foreground hover:bg-slate-50 transition"
        >
          <X className="h-3.5 w-3.5" />
          <span>Clear filters</span>
        </button>
      )}
    </div>
  );
}
