/**
 * src/features/bible/queries.ts
 *
 * WHAT: Bible characters and texts lookup (static fallback until backend endpoint is confirmed)
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

export interface BibleLinkOption {
  id: string;
  label: string;
  kind: "CHARACTER" | "TEXT";
}

export const STATIC_BIBLE_LINKS: BibleLinkOption[] = [
  { id: "char-david", label: "David (Character)", kind: "CHARACTER" },
  { id: "char-paul", label: "Paul (Character)", kind: "CHARACTER" },
  { id: "char-ruth", label: "Ruth (Character)", kind: "CHARACTER" },
  { id: "char-daniel", label: "Daniel (Character)", kind: "CHARACTER" },
  { id: "text-psalm-23", label: "Psalm 23", kind: "TEXT" },
  { id: "text-romans-8", label: "Romans 8", kind: "TEXT" },
  { id: "text-john-15", label: "John 15", kind: "TEXT" },
  { id: "text-philippians-4", label: "Philippians 4", kind: "TEXT" },
];

export async function fetchBibleLinks(): Promise<BibleLinkOption[]> {
  try {
    const res = await fetch("/api/proxy/bible-links", { cache: "no-store" });
    if (!res.ok) return STATIC_BIBLE_LINKS;
    const data = (await res.json()) as { items?: BibleLinkOption[] };
    return data.items?.length ? data.items : STATIC_BIBLE_LINKS;
  } catch {
    return STATIC_BIBLE_LINKS;
  }
}
