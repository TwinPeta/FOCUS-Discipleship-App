/**
 * src/lib/api/mutate.ts
 *
 * WHAT: Write helper for the back office: sends the change through the proxy and, if the API refuses it
 *       (or cannot be reached), shows the API's own message and rethrows so the UI never reports a save that did not happen.
 */

import { toast } from "sonner";
import { apiClient } from "./client";

export async function mutate<T = void>(
  path: string,
  method: "POST" | "PUT" | "PATCH" | "DELETE",
  body?: unknown,
  action = "save your changes",
): Promise<T> {
  try {
    return await apiClient<T>(path, {
      method,
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
  } catch (error) {
    const message = error instanceof Error && error.message && !/^HTTP error/.test(error.message)
      ? error.message
      : `Could not ${action}. The server rejected the request or is unreachable.`;
    toast.error(message);
    throw error;
  }
}
