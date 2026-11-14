/**
 * src/features/settings/queries.ts
 *
 * WHAT: Settings queries and mutations for charter, consents, minors, and retention
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

import type {
  CharterSettings,
  ConsentTextsSettings,
  MinorsSettings,
  RetentionSettings,
} from "./schemas";

async function patchSettings<T>(section: string, payload: T): Promise<void> {
  const res = await fetch(`/api/proxy/settings/${section}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`Failed to save ${section} settings`);
  }
}

export const saveCharterSettings = (payload: CharterSettings) =>
  patchSettings("charter", payload);

export const saveConsentTextsSettings = (payload: ConsentTextsSettings) =>
  patchSettings("consents", payload);

export const saveMinorsSettings = (payload: MinorsSettings) =>
  patchSettings("minors", payload);

export const saveRetentionSettings = (payload: RetentionSettings) =>
  patchSettings("retention", payload);

/** Loads a saved settings section; resolves null when the backend is unreachable so forms keep their defaults. */
export async function fetchSettings<T>(section: string): Promise<T | null> {
  try {
    const res = await fetch(`/api/proxy/settings/${section}`, { cache: "no-store" });
    if (res.ok) return (await res.json()) as T;
  } catch {
    // keep form defaults
  }
  return null;
}
