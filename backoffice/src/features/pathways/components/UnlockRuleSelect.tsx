/**
 * src/features/pathways/components/UnlockRuleSelect.tsx
 *
 * WHAT: Dropdown for pathway unlock rule
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

import type { UnlockRuleType } from "../queries";

interface UnlockRuleSelectProps {
  value: UnlockRuleType;
  onChange: (rule: UnlockRuleType) => void;
  disabled?: boolean;
}

const UNLOCK_RULES: { value: UnlockRuleType; label: string; description: string }[] = [
  { value: "none", label: "None (Always unlocked)", description: "Open to all students immediately upon joining." },
  { value: "previous_pathway", label: "Complete previous pathway", description: "Unlocks after finishing earlier required pathways." },
  { value: "profile_complete", label: "Profile completed", description: "Unlocks once student bio and academic year are saved." },
  { value: "mentor_assigned", label: "Mentor assigned", description: "Unlocks once a mentor is assigned to the student." },
];

export function UnlockRuleSelect({ value, onChange, disabled }: UnlockRuleSelectProps) {
  return (
    <div className="space-y-1.5">
      <label htmlFor="unlock-rule-select" className="block text-[13px] font-extrabold">
        Unlock requirement
      </label>
      <select
        id="unlock-rule-select"
        value={value}
        onChange={(e) => onChange(e.target.value as UnlockRuleType)}
        disabled={disabled}
        className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
      >
        {UNLOCK_RULES.map((rule) => (
          <option key={rule.value} value={rule.value}>
            {rule.label}
          </option>
        ))}
      </select>
      <p className="text-xs text-muted">
        {UNLOCK_RULES.find((r) => r.value === value)?.description}
      </p>
    </div>
  );
}
