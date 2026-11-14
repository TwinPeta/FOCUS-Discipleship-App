/**
 * src/features/bible/components/BibleLinkSelect.tsx
 *
 * WHAT: Dropdown to link content or quiz to a Bible character or text
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { STATIC_BIBLE_LINKS, type BibleLinkOption } from "@/features/bible/queries";

interface BibleLinkSelectProps {
  id?: string;
  value: string;
  onChange: (value: string) => void;
  options?: BibleLinkOption[];
}

export function BibleLinkSelect({
  id = "bible-link-select",
  value,
  onChange,
  options = STATIC_BIBLE_LINKS,
}: BibleLinkSelectProps) {
  return (
    <select
      id={id}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
    >
      <option value="">Select Bible character or text</option>
      {options.map((opt) => (
        <option key={opt.id} value={opt.label}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}
