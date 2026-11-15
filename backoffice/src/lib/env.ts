/**
 * src/lib/env.ts
 *
 * WHAT: Zod-validated environment variables that fail fast
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { z } from "zod";

/**
 * The staff API lives at <host>/v1/admin. Operators set API_BASE_URL in different ways (just the host, the /v1 root,
 * or the full path), so accept all of them and always return the full path without a trailing slash.
 */
export function normalizeApiBaseUrl(value: string): string {
  const base = value.trim().replace(/\/+$/, "");
  if (/\/v1\/admin$/.test(base)) return base;
  if (/\/v1$/.test(base)) return `${base}/admin`;
  return `${base}/v1/admin`;
}

const publicEnvSchema = z.object({
  NEXT_PUBLIC_APP_NAME: z.string().min(1).default("FCU Backoffice"),
});

const serverEnvSchema = publicEnvSchema.extend({
  API_BASE_URL: z
    .string()
    .url()
    .default("http://localhost:4000")
    .transform(normalizeApiBaseUrl),
  AUTH_ACCESS_COOKIE: z.string().min(1).default("fcu_access"),
  AUTH_REFRESH_COOKIE: z.string().min(1).default("fcu_refresh"),
  SENTRY_DSN: z.string().optional().default(""),
});

export const publicEnv = publicEnvSchema.parse({
  NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
});

export function getServerEnv() {
  return serverEnvSchema.parse({
    NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
    API_BASE_URL: process.env.API_BASE_URL,
    AUTH_ACCESS_COOKIE: process.env.AUTH_ACCESS_COOKIE,
    AUTH_REFRESH_COOKIE: process.env.AUTH_REFRESH_COOKIE,
    SENTRY_DSN: process.env.SENTRY_DSN,
  });
}
