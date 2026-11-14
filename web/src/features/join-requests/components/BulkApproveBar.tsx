/**
 * src/features/join-requests/components/BulkApproveBar.tsx
 *
 * WHAT: Action bar for bulk-approving selected join requests while skipping conflicts
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

"use client";

interface BulkApproveBarProps {
  selectedCount: number;
  approvableCount: number;
  skippedConflictCount: number;
  isSubmitting: boolean;
  onApproveSelected: () => void;
  onClearSelection: () => void;
}

export function BulkApproveBar({
  selectedCount,
  approvableCount,
  skippedConflictCount,
  isSubmitting,
  onApproveSelected,
  onClearSelection,
}: BulkApproveBarProps) {
  if (selectedCount === 0) return null;

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 rounded-md border border-border bg-primary-soft px-4 py-3 text-sm">
      <div>
        <span className="font-semibold">{selectedCount} selected</span>
        {skippedConflictCount > 0 && (
          <span className="ml-2 text-amber-900">
            ({skippedConflictCount} with community conflicts will be skipped)
          </span>
        )}
      </div>

      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={onClearSelection}
          className="rounded-md border border-border bg-white px-3 py-1.5 text-xs font-medium hover:bg-surface"
        >
          Clear
        </button>
        <button
          type="button"
          disabled={approvableCount === 0 || isSubmitting}
          onClick={onApproveSelected}
          className="rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          {isSubmitting
            ? "Approving..."
            : `Approve ${approvableCount} request${approvableCount === 1 ? "" : "s"}`}
        </button>
      </div>
    </div>
  );
}
