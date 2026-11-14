/**
 * src/components/feedback/Skeletons.tsx
 *
 * WHAT: Table, card and side panel loading skeletons
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

export function TableSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="w-full space-y-3 rounded-xl border border-border bg-white p-4 animate-pulse">
      <div className="h-8 w-1/3 rounded bg-slate-200" />
      <div className="space-y-2 pt-2">
        {Array.from({ length: rows }).map((_, i) => (
          <div key={i} className="flex gap-4">
            <div className="h-6 w-1/4 rounded bg-slate-100" />
            <div className="h-6 w-1/3 rounded bg-slate-100" />
            <div className="h-6 w-1/6 rounded bg-slate-100" />
            <div className="h-6 w-1/4 rounded bg-slate-100" />
          </div>
        ))}
      </div>
    </div>
  );
}

export function CardSkeleton() {
  return (
    <div className="space-y-3 rounded-xl border border-border bg-white p-5 animate-pulse">
      <div className="h-4 w-1/3 rounded bg-slate-200" />
      <div className="h-8 w-1/2 rounded bg-slate-100" />
      <div className="h-3 w-3/4 rounded bg-slate-100" />
    </div>
  );
}

export function PanelSkeleton() {
  return (
    <div className="space-y-4 rounded-xl border border-border bg-white p-6 animate-pulse">
      <div className="h-6 w-1/2 rounded bg-slate-200" />
      <div className="space-y-2">
        <div className="h-4 w-full rounded bg-slate-100" />
        <div className="h-4 w-5/6 rounded bg-slate-100" />
      </div>
      <div className="h-24 w-full rounded bg-slate-100" />
    </div>
  );
}

export function Skeletons() {
  return <TableSkeleton />;
}
