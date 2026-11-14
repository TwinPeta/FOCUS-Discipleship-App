/**
 * src/lib/api/unwrap.ts
 *
 * WHAT: Accepts a list response either as a bare array or as `{ items: [...] }`
 * REQUIREMENTS: FR-07
 * SPEC: docs/api-needs.md
 * STATUS: implemented
 */

export function unwrapList<T>(body: unknown): T[] {
  if (Array.isArray(body)) return body as T[];
  if (body && typeof body === "object" && Array.isArray((body as { items?: unknown }).items)) {
    return (body as { items: T[] }).items;
  }
  return [];
}
