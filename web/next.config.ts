/**
 * next.config.ts
 *
 * WHAT: Next.js configuration with Content Security Policy (CSP), security headers, and Sentry integration
 * SPEC: docs/security-privacy.md
 * STATUS: implemented
 */
import type { NextConfig } from "next";

const cspHeader = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-eval' 'unsafe-inline'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' blob: data: https:",
  "font-src 'self' data: https:",
  "media-src 'self' blob: data: https:",
  "connect-src 'self' blob: data: https: wss:",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join("; ");

const securityHeaders = [
  { key: "Content-Security-Policy", value: cspHeader },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
];

const nextConfig: NextConfig = {
  reactStrictMode: true,
  serverExternalPackages: [
    "@sentry/nextjs",
    "@sentry/node",
    "@opentelemetry/instrumentation",
    "require-in-the-middle",
  ],
  webpack: (config, { isServer }) => {
    config.ignoreWarnings = [
      ...(config.ignoreWarnings || []),
      { module: /require-in-the-middle/ },
      { module: /@opentelemetry\/instrumentation/ },
      { module: /@prisma\/instrumentation/ },
      /Critical dependency/,
    ];
    if (!isServer) {
      config.resolve.alias = {
        ...config.resolve.alias,
        "@sentry/node": false,
      };
    }
    return config;
  },
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
