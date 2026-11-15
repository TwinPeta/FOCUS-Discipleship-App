/**
 * src/lib/auth/sessionExpiry.ts
 *
 * WHAT: One place that reacts when the API says the session is gone (401) on any back-office call:
 *       the user is sent to the login page with a clear message instead of every screen failing on its own.
 * REQUIREMENTS: FR-07
 * STATUS: implemented
 */

const PROXY = "/api/proxy/";
// Calls that legitimately answer 401 / are made without a session
const IGNORED = ["auth/login", "auth/logout", "auth/forgot-password", "auth/reset-password"];

export function isSessionExpiredResponse(url: string, status: number): boolean {
  if (status !== 401) return false;
  const i = url.indexOf(PROXY);
  if (i === -1) return false;
  const path = url.slice(i + PROXY.length).split("?")[0];
  return !IGNORED.some((p) => path === p || path.startsWith(`${p}/`));
}

/**
 * Wraps `fetch` so a 401 from the API triggers [onExpired] once. Returns a function that restores the original.
 * Everything else passes through untouched.
 */
export function watchSessionExpiry(target: { fetch: typeof fetch }, onExpired: () => void): () => void {
  const original = target.fetch;
  let fired = false;
  target.fetch = async (input, init) => {
    const response = await original.call(target, input, init);
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    if (!fired && isSessionExpiredResponse(url, response.status)) {
      fired = true;
      onExpired();
    }
    return response;
  };
  return () => {
    target.fetch = original;
  };
}
