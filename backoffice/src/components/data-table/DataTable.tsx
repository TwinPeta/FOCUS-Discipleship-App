/**
 * src/components/data-table/DataTable.tsx
 *
 * WHAT: Responsive TanStack-compatible data table wrapper with loading skeleton and empty state
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { TableSkeleton } from "@/components/feedback/Skeletons";
import { EmptyState } from "@/components/feedback/EmptyState";

export interface DataTableColumn<T> {
  key: string;
  header: ReactNode;
  cell: (item: T) => ReactNode;
  className?: string;
  align?: "left" | "center" | "right";
}

interface DataTableProps<T> {
  data: T[];
  columns: DataTableColumn<T>[];
  keyExtractor: (item: T) => string;
  loading?: boolean;
  emptyTitle?: string;
  emptyDescription?: string;
  caption?: string;
  className?: string;
}

export function DataTable<T>({
  data,
  columns,
  keyExtractor,
  loading = false,
  emptyTitle,
  emptyDescription,
  caption,
  className = "",
}: DataTableProps<T>) {
  if (loading) {
    return <TableSkeleton rows={5} />;
  }

  if (data.length === 0) {
    return <EmptyState title={emptyTitle} description={emptyDescription} />;
  }

  return (
    <div className={`card overflow-x-auto ${className}`}>
      <table className="data-table w-full text-left">
        {caption && <caption className="sr-only">{caption}</caption>}
        <thead>
          <tr>
            {columns.map((col) => {
              const alignClass =
                col.align === "center"
                  ? "text-center"
                  : col.align === "right"
                    ? "text-right"
                    : "text-left";
              return (
                <th key={col.key} scope="col" className={`${alignClass} ${col.className ?? ""}`}>
                  {col.header}
                </th>
              );
            })}
          </tr>
        </thead>
        <tbody>
          {data.map((item) => (
            <tr key={keyExtractor(item)}>
              {columns.map((col) => {
                const alignClass =
                  col.align === "center"
                    ? "text-center"
                    : col.align === "right"
                      ? "text-right"
                      : "text-left";
                return (
                  <td key={col.key} className={`${alignClass} ${col.className ?? ""}`}>
                    {col.cell(item)}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
