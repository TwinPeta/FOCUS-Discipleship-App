/**
 * src/app/error.tsx
 *
 * WHAT: Route-level error boundary with retry and Sentry report
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect } from "react";
import Link from "next/link";
import { AlertTriangle, RotateCcw } from "lucide-react";
import { captureAppError } from "@/lib/monitoring/sentry";

export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    captureAppError(error, { digest: error.digest });
  }, [error]);

  return (
    <div
      role="alert"
      className="flex min-h-[50vh] flex-col items-center justify-center p-6 text-center"
    >
      <div className="flex h-12 w-12 items-center justify-center rounded-full bg-danger-soft text-danger mb-4">
        <AlertTriangle className="h-6 w-6" aria-hidden="true" />
      </div>
      <h2 className="text-xl font-bold text-foreground">Something went wrong</h2>
      <p className="mt-2 text-sm text-muted max-w-md">
        An unexpected error occurred. This event has been logged for system administrators.
      </p>
      {error.digest && (
        <p className="mt-1 font-mono text-xs text-muted/80">
          Error ID: {error.digest}
        </p>
      )}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-3">
        <button
          type="button"
          onClick={() => reset()}
          className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2"
        >
          <RotateCcw className="h-4 w-4" />
          <span>Try again</span>
        </button>
        <Link
          href="/"
          className="rounded-md border border-border bg-white px-4 py-2 text-sm font-medium text-foreground hover:bg-blue-tint"
        >
          Go to home
        </Link>
      </div>
    </div>
  );
}
