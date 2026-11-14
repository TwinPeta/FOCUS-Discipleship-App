/**
 * tests/unit/password-rules.test.ts
 *
 * WHAT: At least 10 characters, a letter and a number, different from last passwords
 * REQUIREMENTS: -
 * SPEC: start/CONVENTIONS.md (testing section)
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import {
  evaluatePasswordRules,
  hasLetter,
  hasMinLength,
  hasNumber,
  isDifferentFromPrevious,
  isPasswordValid,
} from "@/features/auth/password-rules";

describe("password rules", () => {
  it("requires at least 10 characters", () => {
    expect(hasMinLength("abc123456")).toBe(false);
    expect(hasMinLength("abc1234567")).toBe(true);
  });

  it("requires at least one letter and one number", () => {
    expect(hasLetter("1234567890")).toBe(false);
    expect(hasLetter("123456789a")).toBe(true);
    expect(hasNumber("abcdefghij")).toBe(false);
    expect(hasNumber("abcdefghi1")).toBe(true);
  });

  it("rejects previously used passwords", () => {
    expect(isDifferentFromPrevious("Focus2026!", ["Focus2026!"])).toBe(false);
    expect(isDifferentFromPrevious("Focus2027!", ["Focus2026!"])).toBe(true);
  });

  it("evaluates all rules together", () => {
    expect(isPasswordValid("short1")).toBe(false);
    expect(isPasswordValid("alllettersno")).toBe(false);
    expect(isPasswordValid("1234567890")).toBe(false);
    expect(isPasswordValid("FocusUganda1")).toBe(true);
    expect(isPasswordValid("FocusUganda1", ["FocusUganda1"])).toBe(false);

    const results = evaluatePasswordRules("FocusUganda1", ["OldPass1234"]);
    expect(results.every((r) => r.passed)).toBe(true);
  });
});
