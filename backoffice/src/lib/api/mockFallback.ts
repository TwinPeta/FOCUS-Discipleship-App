/**
 * src/lib/api/mockFallback.ts
 *
 * WHAT: Lets save/delete helpers fall back to local demo behaviour only when API mocking is on
 * REQUIREMENTS: FR-07
 * SPEC: docs/api-needs.md
 * STATUS: implemented
 */

import { toast } from "sonner";

const MOCKING = process.env.NEXT_PUBLIC_API_MOCKING === "enabled";

/**
 * Call after a failed request. With mocking enabled the caller continues with its demo result;
 * otherwise the failure is surfaced so the UI never reports success for something that was not saved.
 */
export function requireBackend(action = "save your changes"): void {
  if (MOCKING) return;
  const message = `Could not ${action}. The server rejected the request or is unreachable.`;
  toast.error(message);
  throw new Error(message);
}
