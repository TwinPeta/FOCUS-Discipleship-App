/**
 * next.config.ts
 *
 * WHAT: Next.js configuration: security headers now. The backoffice is a staff desktop tool, so no PWA/offline setup.
 * SPEC: docs/security-privacy.md
 * STATUS: baseline
 */
import type { NextConfig } from "next";

const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  // TODO: add a Content-Security-Policy once the video/media host and upload endpoint are known
];

const nextConfig: NextConfig = {
  reactStrictMode: true,
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
