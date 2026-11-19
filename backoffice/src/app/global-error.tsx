/**
 * src/app/global-error.tsx
 *
 * WHAT: Root error boundary fallback with Sentry reporting
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

"use client";

import { useEffect } from "react";
import { captureAppError } from "@/lib/monitoring/sentry";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    captureAppError(error, { level: "fatal", digest: error.digest });
  }, [error]);

  return (
    <html lang="en">
      <body className="flex min-h-screen flex-col items-center justify-center p-6 bg-blue-tint text-foreground font-sans text-center">
        <div role="alert" className="max-w-md space-y-4">
          <h1 className="text-[34px] leading-[1.05]">System Error</h1>
          <p className="text-sm text-muted-foreground">
            A critical error occurred while loading the application.
          </p>
          {error.digest && (
            <p className="font-mono text-xs text-slate-400">
              Ref: {error.digest}
            </p>
          )}
          <button
            type="button"
            onClick={() => reset()}
            className="rounded-md bg-yellow-500 px-4 py-2 text-sm font-medium text-black hover:bg-yellow-600 focus:outline-none focus:ring-2 focus:ring-yellow-500"
          >
            Reload application
          </button>
        </div>
      </body>
    </html>
  );
}
