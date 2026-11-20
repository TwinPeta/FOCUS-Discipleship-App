/**
 * src/components/feedback/ErrorState.tsx
 *
 * WHAT: Inline error with retry action and alert role
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { AlertCircle, RotateCcw } from "lucide-react";

interface ErrorStateProps {
  title?: string;
  message?: string;
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  title = "Failed to load content",
  message = "An error occurred while communicating with the server. Please try again.",
  onRetry,
  className = "",
}: ErrorStateProps) {
  return (
    <div
      role="alert"
      className={`flex flex-col items-center justify-center rounded-xl border border-danger/40 bg-danger-soft/50 p-6 text-center text-sm sm:p-8 ${className}`}
    >
      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-danger-soft text-danger mb-3">
        <AlertCircle className="h-5 w-5" aria-hidden="true" />
      </div>
      <h3 className="font-semibold text-danger">{title}</h3>
      <p className="mt-1 text-xs text-danger max-w-sm">{message}</p>
      {onRetry && (
        <button
          type="button"
          onClick={onRetry}
          className="mt-4 inline-flex items-center gap-1.5 rounded-md bg-white border border-danger/40 px-3 py-1.5 text-xs font-medium text-danger hover:bg-danger-soft transition shadow-sm"
        >
          <RotateCcw className="h-3.5 w-3.5" />
          <span>Retry</span>
        </button>
      )}
    </div>
  );
}
