/**
 * src/lib/monitoring/sentry.ts
 *
 * WHAT: Sentry initialisation, error reporting, and context tagging
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import * as Sentry from "@sentry/nextjs";

const SENTRY_DSN = process.env.NEXT_PUBLIC_SENTRY_DSN || process.env.SENTRY_DSN;

export function initSentry() {
  if (!SENTRY_DSN) {
    return;
  }

  Sentry.init({
    dsn: SENTRY_DSN,
    tracesSampleRate: process.env.NODE_ENV === "production" ? 0.2 : 1.0,
    debug: false,
    environment: process.env.NODE_ENV || "development",
  });
}

export function captureAppError(error: unknown, context?: Record<string, unknown>) {
  if (process.env.NODE_ENV !== "production") {
    // Also log to console in non-production environments
    console.error("[AppError]", error, context);
  }

  if (SENTRY_DSN) {
    Sentry.withScope((scope) => {
      if (context) {
        scope.setExtras(context);
      }
      Sentry.captureException(error);
    });
  }
}

export function setUserMonitoringContext(user: { id: string; email?: string; role?: string }) {
  if (SENTRY_DSN) {
    Sentry.setUser({
      id: user.id,
      email: user.email,
      role: user.role,
    });
  }
}

export function clearUserMonitoringContext() {
  if (SENTRY_DSN) {
    Sentry.setUser(null);
  }
}
