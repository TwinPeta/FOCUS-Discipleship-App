/**
 * src/lib/api/errors.ts
 *
 * WHAT: Normalised API error shape and user-facing messages
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

export class ApiError extends Error {
  status: number;
  code?: string;
  details?: Record<string, unknown>;

  constructor(message: string, status = 500, code?: string, details?: Record<string, unknown>) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    if (error.status === 401) return "Your session has expired. Please log in again.";
    if (error.status === 403) return "You do not have permission to perform this action.";
    if (error.status === 404) return "The requested record was not found.";
    if (error.status === 409) return "A conflict occurred with an existing record.";
    if (error.status >= 500) return "A server error occurred. Please try again shortly.";
    return error.message;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "An unexpected error occurred.";
}
