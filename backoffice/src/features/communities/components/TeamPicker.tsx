/**
 * src/features/communities/components/TeamPicker.tsx
 *
 * WHAT: Super-mentor and mentors picker for a community
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

export interface StaffOption {
  id: string;
  fullName: string;
  email: string;
}

interface TeamPickerProps {
  superMentorId?: string;
  mentorIds: string[];
  candidates: StaffOption[];
  onSuperMentorChange: (id: string) => void;
  onMentorIdsChange: (ids: string[]) => void;
  disabled?: boolean;
}

export function TeamPicker({
  superMentorId = "",
  mentorIds,
  candidates,
  onSuperMentorChange,
  onMentorIdsChange,
  disabled = false,
}: TeamPickerProps) {
  function toggleMentor(id: string) {
    if (mentorIds.includes(id)) {
      onMentorIdsChange(mentorIds.filter((m) => m !== id));
    } else {
      onMentorIdsChange([...mentorIds, id]);
    }
  }

  return (
    <div className="space-y-4">
      <div className="space-y-1.5">
        <label htmlFor="superMentorId" className="block text-[13px] font-extrabold">
          Super-mentor
        </label>
        <select
          id="superMentorId"
          value={superMentorId}
          disabled={disabled}
          onChange={(e) => onSuperMentorChange(e.target.value)}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm disabled:bg-surface"
        >
          <option value="">Unassigned</option>
          {candidates.map((c) => (
            <option key={c.id} value={c.id}>
              {c.fullName} ({c.email})
            </option>
          ))}
        </select>
      </div>

      <fieldset disabled={disabled} className="space-y-2">
        <legend className="text-sm font-medium text-foreground">Mentors</legend>
        {candidates.length === 0 ? (
          <p className="text-xs text-muted-foreground">No mentor candidates loaded.</p>
        ) : (
          <div className="grid gap-2 sm:grid-cols-2">
            {candidates.map((c) => (
              <label
                key={c.id}
                className="flex items-center gap-2 rounded-md border border-border bg-white px-3 py-2 text-sm"
              >
                <input
                  type="checkbox"
                  checked={mentorIds.includes(c.id)}
                  onChange={() => toggleMentor(c.id)}
                  className="h-4 w-4 rounded border-border accent-primary"
                />
                <span className="truncate">{c.fullName}</span>
              </label>
            ))}
          </div>
        )}
      </fieldset>
    </div>
  );
}
