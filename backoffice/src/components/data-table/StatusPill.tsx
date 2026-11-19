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

const POSITIVE = "bg-blue-soft text-ink";
const WARM = "bg-primary-soft text-ink";
const MUTED = "bg-[#F5F6F8] text-muted-foreground";
const NEGATIVE = "bg-danger-soft text-danger";

const VARIANT_STYLES: Record<string, string> = {
  active: POSITIVE,
  published: POSITIVE,
  approved: POSITIVE,
  validated: POSITIVE,
  pending: WARM,
  in_review: WARM,
  draft: MUTED,
  inactive: MUTED,
  archived: MUTED,
  declined: NEGATIVE,
  suspended: NEGATIVE,
};

export function StatusPill({ status, variant, className = "" }: StatusPillProps) {
  const normalizedKey = variant ?? status.toLowerCase().replace(/\s+/g, "_");
  const style = VARIANT_STYLES[normalizedKey] ?? POSITIVE;

  return (
    <span className={`chip select-none capitalize ${style} ${className}`}>
      {status}
    </span>
  );
}
