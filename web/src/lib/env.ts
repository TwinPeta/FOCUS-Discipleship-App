/**
 * src/lib/env.ts
 *
 * WHAT: Zod-validated environment variables that fail fast
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { z } from "zod";

const publicEnvSchema = z.object({
  NEXT_PUBLIC_APP_NAME: z.string().min(1).default("FCU Backoffice"),
  NEXT_PUBLIC_API_MOCKING: z.enum(["enabled", "disabled"]).default("disabled"),
  NEXT_PUBLIC_UPLOAD_ENDPOINT: z.string().optional().default(""),
});

const serverEnvSchema = publicEnvSchema.extend({
  API_BASE_URL: z.string().url().default("http://localhost:4000"),
  AUTH_ACCESS_COOKIE: z.string().min(1).default("fcu_access"),
  AUTH_REFRESH_COOKIE: z.string().min(1).default("fcu_refresh"),
  SENTRY_DSN: z.string().optional().default(""),
});

export const publicEnv = publicEnvSchema.parse({
  NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
  NEXT_PUBLIC_API_MOCKING: process.env.NEXT_PUBLIC_API_MOCKING,
  NEXT_PUBLIC_UPLOAD_ENDPOINT: process.env.NEXT_PUBLIC_UPLOAD_ENDPOINT,
});

export function getServerEnv() {
  return serverEnvSchema.parse({
    NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
    NEXT_PUBLIC_API_MOCKING: process.env.NEXT_PUBLIC_API_MOCKING,
    NEXT_PUBLIC_UPLOAD_ENDPOINT: process.env.NEXT_PUBLIC_UPLOAD_ENDPOINT,
    API_BASE_URL: process.env.API_BASE_URL,
    AUTH_ACCESS_COOKIE: process.env.AUTH_ACCESS_COOKIE,
    AUTH_REFRESH_COOKIE: process.env.AUTH_REFRESH_COOKIE,
    SENTRY_DSN: process.env.SENTRY_DSN,
  });
}
