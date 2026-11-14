/**
 * src/features/moderation/components/CommunityFilter.tsx
 *
 * WHAT: Community filter for moderation queues (hidden for scope-locked super-mentors)
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import { useSession } from "@/features/auth/hooks/useSession";
import { shouldHideCrossCommunityControls } from "@/lib/permissions/scope";

interface CommunityFilterProps {
  value: string;
  onChange: (communityId: string) => void;
  communities?: { id: string; name: string }[];
}

export function CommunityFilter({
  value,
  onChange,
  communities = [],
}: CommunityFilterProps) {
  const { user } = useSession();

  if (shouldHideCrossCommunityControls(user)) {
    return null;
  }

  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      aria-label="Filter moderation by community"
      className="rounded-md border border-border bg-white px-3 py-2 text-sm"
    >
      <option value="ALL">All communities</option>
      {communities.map((c) => (
        <option key={c.id} value={c.id}>
          {c.name}
        </option>
      ))}
    </select>
  );
}
