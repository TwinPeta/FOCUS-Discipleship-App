/**
 * src/features/content/components/ValidatorField.tsx
 *
 * WHAT: Pastor or committee validator input (supports recorded name until validator user model is confirmed)
 * REQUIREMENTS: FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

interface ValidatorFieldProps {
  value: string;
  onChange: (value: string) => void;
}

export function ValidatorField({ value, onChange }: ValidatorFieldProps) {
  return (
    <div className="space-y-1.5">
      <label htmlFor="validator-name" className="block text-sm font-medium text-foreground">
        Validator (pastor or committee)
      </label>
      <input
        id="validator-name"
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="e.g. Rev. Peter Kato or Doctrine Committee"
        className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
      />
    </div>
  );
}
