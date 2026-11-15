import { describe, expect, it } from "vitest";
import { normalizeApiBaseUrl } from "@/lib/env";

describe("normalizeApiBaseUrl", () => {
  it("always ends up at <host>/v1/admin", () => {
    for (const input of [
      "https://apis.focusuganda.org",
      "https://apis.focusuganda.org/",
      "https://apis.focusuganda.org/v1",
      "https://apis.focusuganda.org/v1/",
      "https://apis.focusuganda.org/v1/admin",
      "https://apis.focusuganda.org/v1/admin/",
      "  https://apis.focusuganda.org  ",
    ]) {
      expect(normalizeApiBaseUrl(input)).toBe("https://apis.focusuganda.org/v1/admin");
    }
  });

  it("keeps a port and a path prefix", () => {
    expect(normalizeApiBaseUrl("http://localhost:4000")).toBe("http://localhost:4000/v1/admin");
    expect(normalizeApiBaseUrl("https://x.test/api")).toBe("https://x.test/api/v1/admin");
  });
});
