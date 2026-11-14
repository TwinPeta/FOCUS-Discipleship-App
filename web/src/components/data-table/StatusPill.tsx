/**
 * src/components/data-table/StatusPill.tsx
 *
 * WHAT: Accessible status pills with high contrast tokens for members and workflow states
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

export type StatusVariant =
  | "active"
  | "inactive"
  | "pending"
  | "approved"
  | "declined"
  | "draft"
  | "in_review"
  | "validated"
  | "published"
  | "suspended"
  | "archived";

interface StatusPillProps {
  status: string;
  variant?: StatusVariant;
  className?: string;
}

const VARIANT_STYLES: Record<string, string> = {
  active: "bg-emerald-50 text-emerald-800 border-emerald-200",
  published: "bg-emerald-50 text-emerald-800 border-emerald-200",
  approved: "bg-emerald-50 text-emerald-800 border-emerald-200",
  validated: "bg-sky-50 text-sky-800 border-sky-200",
  pending: "bg-amber-50 text-amber-800 border-amber-200",
  in_review: "bg-amber-50 text-amber-800 border-amber-200",
  draft: "bg-slate-100 text-slate-800 border-slate-200",
  inactive: "bg-slate-100 text-slate-600 border-slate-200",
  declined: "bg-rose-50 text-rose-800 border-rose-200",
  suspended: "bg-rose-50 text-rose-800 border-rose-200",
  archived: "bg-slate-100 text-slate-500 border-slate-200",
};

export function StatusPill({ status, variant, className = "" }: StatusPillProps) {
  const normalizedKey = variant ?? status.toLowerCase().replace(/\s+/g, "_");
  const style = VARIANT_STYLES[normalizedKey] ?? "bg-slate-100 text-foreground border-border";

  return (
    <span
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold capitalize tracking-wide select-none ${style} ${className}`}
    >
      {status}
    </span>
  );
}
