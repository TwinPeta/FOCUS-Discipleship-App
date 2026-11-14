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
    <div className="inline-flex flex-wrap gap-1 rounded-md border border-border bg-surface p-1" role="tablist">
      {OPTIONS.map((opt) => (
        <button
          key={opt.type}
          type="button"
          role="tab"
          aria-selected={value === opt.type}
          onClick={() => onChange(opt.type)}
          className={`rounded px-3 py-1.5 text-sm font-medium transition ${
            value === opt.type
              ? "bg-white text-foreground shadow-sm"
              : "text-muted-foreground hover:text-foreground"
          }`}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}
