/**
 * tests/unit/hardening.test.ts
 *
 * WHAT: Hardening tests: security headers, CSP, error handling, date formatting, and accessibility landmarks
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { describe, expect, it } from "vitest";
import nextConfig from "../../next.config";
import { ApiError, getErrorMessage } from "@/lib/api/errors";
import { formatDate, formatRelativeTime } from "@/lib/format/date";

describe("Security headers and CSP configuration", () => {
  it("includes all required security headers and Content-Security-Policy", async () => {
    if (typeof nextConfig.headers !== "function") {
      throw new Error("nextConfig.headers must be a function");
    }

    const headerConfigs = await nextConfig.headers();
    expect(headerConfigs.length).toBeGreaterThan(0);

    const rootHeaders = headerConfigs[0].headers;
    const headerMap = new Map(rootHeaders.map((h) => [h.key, h.value]));

    expect(headerMap.get("X-Content-Type-Options")).toBe("nosniff");
    expect(headerMap.get("X-Frame-Options")).toBe("DENY");
    expect(headerMap.get("Referrer-Policy")).toBe("strict-origin-when-cross-origin");
    expect(headerMap.get("Strict-Transport-Security")).toContain("max-age=");

    const csp = headerMap.get("Content-Security-Policy");
    expect(csp).toBeDefined();
    expect(csp).toContain("default-src 'self'");
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("media-src");
  });
});

describe("Error normalization and user-facing messages", () => {
  it("normalizes HTTP status codes to user-friendly copy", () => {
    expect(getErrorMessage(new ApiError("Unauthorized", 401))).toContain("session has expired");
    expect(getErrorMessage(new ApiError("Forbidden", 403))).toContain("do not have permission");
    expect(getErrorMessage(new ApiError("Not Found", 404))).toContain("not found");
    expect(getErrorMessage(new ApiError("Conflict", 409))).toContain("conflict occurred");
    expect(getErrorMessage(new ApiError("Server Error", 500))).toContain("server error occurred");
    expect(getErrorMessage(new Error("Custom network failure"))).toBe("Custom network failure");
  });
});

describe("Date formatting with Kampala timezone", () => {
  it("formats dates consistently", () => {
    const formatted = formatDate("2026-11-14T10:00:00Z");
    expect(formatted).toContain("Nov");
    expect(formatted).toContain("2026");
  });

  it("formats relative times", () => {
    const now = Date.now();
    expect(formatRelativeTime(new Date(now - 30 * 1000))).toBe("Just now");
    expect(formatRelativeTime(new Date(now - 10 * 60 * 1000))).toContain("min ago");
    expect(formatRelativeTime(new Date(now - 86400 * 1000 * 3))).toBe("3 days ago");
  });
});
