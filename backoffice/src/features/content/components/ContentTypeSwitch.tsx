/**
 * src/features/content/components/ContentTypeSwitch.tsx
 *
 * WHAT: Switch between Video, Devotional, Quiz, and Document content types
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { ContentType } from "@/types/enums";

interface ContentTypeSwitchProps {
  value: ContentType;
  onChange: (type: ContentType) => void;
}

const OPTIONS: { type: ContentType; label: string }[] = [
  { type: ContentType.Video, label: "Video" },
  { type: ContentType.Devotional, label: "Devotional" },
  { type: ContentType.Quiz, label: "Quiz" },
  { type: ContentType.Document, label: "Document" },
];

export function ContentTypeSwitch({ value, onChange }: ContentTypeSwitchProps) {
  return (
    <div className="flex flex-wrap gap-2" role="tablist">
      {OPTIONS.map((opt) => (
        <button
          key={opt.type}
          type="button"
          role="tab"
          aria-selected={value === opt.type}
          onClick={() => onChange(opt.type)}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
