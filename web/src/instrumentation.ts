/**
 * src/instrumentation.ts
 *
 * WHAT: Next.js instrumentation hook: registers Sentry and server monitoring on runtime start
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { initSentry } from "@/lib/monitoring/sentry";

export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    initSentry();
  }

  if (process.env.NEXT_RUNTIME === "edge") {
    initSentry();
  }
}
