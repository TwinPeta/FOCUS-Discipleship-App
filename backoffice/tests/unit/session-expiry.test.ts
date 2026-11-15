import { describe, expect, it, vi } from "vitest";
import { isSessionExpiredResponse, watchSessionExpiry } from "@/lib/auth/sessionExpiry";

describe("session expiry", () => {
  it("treats a 401 from the API as an ended session, except for the sign-in calls", () => {
    expect(isSessionExpiredResponse("/api/proxy/members", 401)).toBe(true);
    expect(isSessionExpiredResponse("/api/proxy/members?x=1", 401)).toBe(true);
    expect(isSessionExpiredResponse("/api/proxy/members", 403)).toBe(false);
    expect(isSessionExpiredResponse("/api/proxy/auth/login", 401)).toBe(false);
    expect(isSessionExpiredResponse("/api/proxy/auth/reset-password", 401)).toBe(false);
    expect(isSessionExpiredResponse("https://other.example/x", 401)).toBe(false);
  });

  it("fires once, passes responses through, and can be removed", async () => {
    const fake = vi.fn(async () => new Response("{}", { status: 401 }));
    const target = { fetch: fake as unknown as typeof fetch };
    const onExpired = vi.fn();
    const stop = watchSessionExpiry(target, onExpired);

    const res = await target.fetch("/api/proxy/dashboard");
    await target.fetch("/api/proxy/members");
    expect(res.status).toBe(401);
    expect(onExpired).toHaveBeenCalledTimes(1);

    stop();
    expect(target.fetch).toBe(fake);
  });
});
