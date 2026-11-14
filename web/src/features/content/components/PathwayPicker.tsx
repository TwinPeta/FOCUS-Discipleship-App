/**
 * src/features/content/components/PathwayPicker.tsx
 *
 * WHAT: Optional pathway assignment checkboxes for content publishing card
 * REQUIREMENTS: FR-01
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

interface PathwayOption {
  id: string;
  name: string;
}

interface PathwayPickerProps {
  selectedIds: string[];
  onChange: (ids: string[]) => void;
  pathways?: PathwayOption[];
}

export function PathwayPicker({
  selectedIds,
  onChange,
  pathways = [],
}: PathwayPickerProps) {
  function toggle(id: string) {
    if (selectedIds.includes(id)) {
      onChange(selectedIds.filter((item) => item !== id));
    } else {
      onChange([...selectedIds, id]);
    }
  }

  return (
    <div className="space-y-1.5">
      <p className="text-sm font-medium text-foreground">Add to pathway</p>
      {pathways.length === 0 ? (
        <p className="text-xs text-muted-foreground">No pathways available yet.</p>
      ) : (
        <div className="space-y-1.5">
          {pathways.map((p) => (
            <label key={p.id} className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={selectedIds.includes(p.id)}
                onChange={() => toggle(p.id)}
                className="h-4 w-4 rounded border-border accent-primary"
              />
              <span>{p.name}</span>
            </label>
          ))}
        </div>
      )}
    </div>
  );
}
