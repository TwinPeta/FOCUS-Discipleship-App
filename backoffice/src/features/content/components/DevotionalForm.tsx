/**
 * src/features/content/components/DevotionalForm.tsx
 *
 * WHAT: Devotional text body editor
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

interface DevotionalFormProps {
  body: string;
  onChange: (value: string) => void;
}

export function DevotionalForm({ body, onChange }: DevotionalFormProps) {
  return (
    <div className="space-y-1.5">
      <label htmlFor="devotional-body" className="block text-[13px] font-extrabold">
        Devotional text
      </label>
      <textarea
        id="devotional-body"
        rows={10}
        value={body}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Write the scripture reflection, discussion prompts, and prayer..."
        className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm leading-relaxed"
      />
    </div>
  );
}
