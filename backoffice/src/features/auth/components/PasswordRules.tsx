/**
 * src/features/auth/components/PasswordRules.tsx
 *
 * WHAT: Checklist: at least 10 characters, a letter and a number, different from last passwords
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { Check, Circle } from "lucide-react";
import { evaluatePasswordRules } from "@/features/auth/password-rules";

interface PasswordRulesProps {
  password: string;
  previousPasswords?: string[];
}

export function PasswordRules({
  password,
  previousPasswords = [],
}: PasswordRulesProps) {
  const rules = evaluatePasswordRules(password, previousPasswords);

  return (
    <ul
      aria-label="Password requirements"
      className="space-y-1.5 rounded-md border border-border bg-surface p-3 text-xs"
    >
      {rules.map((rule) => (
        <li
          key={rule.id}
          className={`flex items-center gap-2 ${
            rule.passed ? "text-emerald-700 font-medium" : "text-muted-foreground"
          }`}
        >
          {rule.passed ? (
            <Check className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
          ) : (
            <Circle className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
          )}
          <span>{rule.label}</span>
        </li>
      ))}
    </ul>
  );
}
