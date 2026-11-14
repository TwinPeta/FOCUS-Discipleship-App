/**
 * src/components/common/DateRangeSelect.tsx
 *
 * WHAT: Standard period selector dropdown (7d, 30d, 90d, 12m, all)
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

interface DateRangeSelectProps {
  value: string;
  onChange: (value: string) => void;
  className?: string;
}

export function DateRangeSelect({
  value,
  onChange,
  className = "",
}: DateRangeSelectProps) {
  return (
    <div className={`space-y-1 ${className}`}>
      <label htmlFor="date-range-select" className="sr-only">
        Date range
      </label>
      <select
        id="date-range-select"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="rounded-md border border-border bg-white px-3 py-1.5 text-xs text-foreground focus:ring-2 focus:ring-primary focus:outline-none"
      >
        <option value="7d">Last 7 days</option>
        <option value="30d">Last 30 days</option>
        <option value="90d">Last 90 days</option>
        <option value="12m">Last 12 months</option>
        <option value="all">All time</option>
      </select>
    </div>
  );
}
