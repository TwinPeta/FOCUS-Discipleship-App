/**
 * src/features/badges/components/RuleSelect.tsx
 *
 * WHAT: Rule selector and target quantity configuration for badges
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import {
  RULE_DEFINITIONS,
  type BadgeRuleType,
} from "../queries";

interface RuleSelectProps {
  ruleType: BadgeRuleType;
  ruleTargetCount: number;
  onRuleTypeChange: (ruleType: BadgeRuleType) => void;
  onTargetCountChange: (count: number) => void;
  disabled?: boolean;
}

export function RuleSelect({
  ruleType,
  ruleTargetCount,
  onRuleTypeChange,
  onTargetCountChange,
  disabled,
}: RuleSelectProps) {
  const currentMeta = RULE_DEFINITIONS[ruleType];
  const requiresCount =
    ruleType === "finish_quizzes" ||
    ruleType === "pray_requests" ||
    ruleType === "attend_meetings_streak";

  function handleTypeChange(newType: BadgeRuleType) {
    onRuleTypeChange(newType);
    onTargetCountChange(RULE_DEFINITIONS[newType].defaultCount);
  }

  return (
    <div className="space-y-4 rounded-lg border border-border bg-slate-50/50 p-4">
      <div className="space-y-1.5">
        <label htmlFor="badge-rule-type" className="block text-sm font-medium text-foreground">
          Earning rule
        </label>
        <select
          id="badge-rule-type"
          value={ruleType}
          onChange={(e) => handleTypeChange(e.target.value as BadgeRuleType)}
          disabled={disabled}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
        >
          {Object.entries(RULE_DEFINITIONS).map(([key, def]) => (
            <option key={key} value={key}>
              {def.label}
            </option>
          ))}
        </select>
      </div>

      {requiresCount && (
        <div className="space-y-1.5">
          <label htmlFor="badge-rule-count" className="block text-sm font-medium text-foreground">
            Target number required
          </label>
          <input
            id="badge-rule-count"
            type="number"
            min={1}
            max={100}
            value={ruleTargetCount}
            onChange={(e) => onTargetCountChange(Math.max(1, parseInt(e.target.value) || 1))}
            disabled={disabled}
            className="w-full max-w-xs rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
          />
        </div>
      )}

      <div className="rounded-md border border-border bg-white p-2.5 text-xs text-muted">
        <span className="font-semibold text-foreground">Rule preview: </span>
        {currentMeta.formatDescription(ruleTargetCount)}
      </div>
    </div>
  );
}
