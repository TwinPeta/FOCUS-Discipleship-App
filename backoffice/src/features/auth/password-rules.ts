/**
 * src/features/auth/password-rules.ts
 *
 * WHAT: Pure password rule checks shared by reset, change password and staff creation
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

export const MIN_PASSWORD_LENGTH = 10;

export interface PasswordRuleResult {
  id: "minLength" | "hasLetter" | "hasNumber" | "notReused";
  label: string;
  passed: boolean;
}

export function hasMinLength(password: string): boolean {
  return password.length >= MIN_PASSWORD_LENGTH;
}

export function hasLetter(password: string): boolean {
  return /[a-zA-Z]/.test(password);
}

export function hasNumber(password: string): boolean {
  return /\d/.test(password);
}

export function isDifferentFromPrevious(
  password: string,
  previousPasswords: string[] = [],
): boolean {
  if (!password) return false;
  return !previousPasswords.includes(password);
}

export function evaluatePasswordRules(
  password: string,
  previousPasswords: string[] = [],
): PasswordRuleResult[] {
  const results: PasswordRuleResult[] = [
    {
      id: "minLength",
      label: `At least ${MIN_PASSWORD_LENGTH} characters`,
      passed: hasMinLength(password),
    },
    {
      id: "hasLetter",
      label: "Contains at least one letter",
      passed: hasLetter(password),
    },
    {
      id: "hasNumber",
      label: "Contains at least one number",
      passed: hasNumber(password),
    },
  ];

  if (previousPasswords.length > 0) {
    results.push({
      id: "notReused",
      label: "Different from your recent passwords",
      passed: isDifferentFromPrevious(password, previousPasswords),
    });
  }

  return results;
}

export function isPasswordValid(
  password: string,
  previousPasswords: string[] = [],
): boolean {
  return evaluatePasswordRules(password, previousPasswords).every((r) => r.passed);
}
