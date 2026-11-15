import { describe, expect, it } from "vitest";
import { publicOrigin } from "@/lib/auth/publicOrigin";

const h = (o: Record<string, string>) => ({ get: (k: string) => o[k.toLowerCase()] ?? null });
const internal = { host: "127.0.0.1:3001", protocol: "http:" };

describe("publicOrigin", () => {
  it("uses the forwarded scheme and host", () => {
    expect(
      publicOrigin(h({ "x-forwarded-host": "backoffice.focusuganda.org", "x-forwarded-proto": "https" }), internal, true),
    ).toBe("https://backoffice.focusuganda.org");
  });

  it("takes the first value of a comma list", () => {
    expect(publicOrigin(h({ host: "a.example, b.example", "x-forwarded-proto": "https, http" }), internal, true)).toBe(
      "https://a.example",
    );
  });

  it("in production a public host is always https, even if the header says http (never downgrades)", () => {
    expect(publicOrigin(h({ host: "backoffice.focusuganda.org" }), internal, true)).toBe(
      "https://backoffice.focusuganda.org",
    );
    expect(
      publicOrigin(h({ host: "backoffice.focusuganda.org", "x-forwarded-proto": "http" }), internal, true),
    ).toBe("https://backoffice.focusuganda.org");
  });

  it("keeps http on a local machine", () => {
    expect(publicOrigin(h({ host: "localhost:3011" }), { host: "localhost:3011", protocol: "http:" }, false)).toBe(
      "http://localhost:3011",
    );
    expect(publicOrigin(h({ host: "localhost:3000" }), { host: "localhost:3000", protocol: "http:" }, true)).toBe(
      "http://localhost:3000",
    );
  });
});
