/**
 * src/lib/auth/publicOrigin.ts
 *
 * WHAT: The address the browser actually used (scheme + host), for building redirect URLs behind a reverse proxy.
 *       Behind nginx the Next server only sees http://127.0.0.1:3001, so the scheme and host come from the forwarded headers.
 *       In production a public hostname is always https: the session cookie is secure-only, and a redirect to http://
 *       would drop it and send the user back to the login page. (The proxy header cannot be trusted for this: Next fills
 *       in `x-forwarded-proto: http` itself when the proxy sends none.)
 * REQUIREMENTS: FR-07
 * STATUS: implemented
 */

const LOCAL_HOST = /^(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/;

export function publicOrigin(
  headers: { get(name: string): string | null },
  fallback: { host: string; protocol: string },
  isProduction: boolean,
): string {
  const first = (v: string | null) => v?.split(",")[0].trim() || null;
  const host = first(headers.get("x-forwarded-host")) ?? first(headers.get("host")) ?? fallback.host;
  const forwardedProto = first(headers.get("x-forwarded-proto"));
  const proto =
    isProduction && !LOCAL_HOST.test(host)
      ? "https"
      : (forwardedProto ?? fallback.protocol.replace(":", ""));
  return `${proto}://${host}`;
}
