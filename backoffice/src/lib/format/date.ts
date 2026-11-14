/**
 * src/lib/format/date.ts
 *
 * WHAT: Date and relative-time formatting with East Africa Time (Africa/Kampala) default
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

const KAMPALA_TZ = "Africa/Kampala";

export function formatDate(
  dateInput: string | number | Date,
  options?: Intl.DateTimeFormatOptions,
): string {
  const d = new Date(dateInput);
  if (isNaN(d.getTime())) return "—";

  return new Intl.DateTimeFormat("en-UG", {
    timeZone: KAMPALA_TZ,
    year: "numeric",
    month: "short",
    day: "numeric",
    ...options,
  }).format(d);
}

export function formatDateTime(
  dateInput: string | number | Date,
): string {
  return formatDate(dateInput, {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}

export function formatRelativeTime(dateInput: string | number | Date): string {
  const d = new Date(dateInput);
  if (isNaN(d.getTime())) return "—";

  const diffMs = Date.now() - d.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHours = Math.floor(diffMin / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffDays > 30) return formatDate(d);
  if (diffDays > 1) return `${diffDays} days ago`;
  if (diffDays === 1) return "Yesterday";
  if (diffHours >= 1) return `${diffHours} ${diffHours === 1 ? "hour" : "hours"} ago`;
  if (diffMin >= 1) return `${diffMin} min ago`;
  return "Just now";
}
