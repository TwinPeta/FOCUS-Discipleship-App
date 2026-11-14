/**
 * src/features/join-requests/components/ConflictBadge.tsx
 *
 * WHAT: Badge showing that a student already belongs to another specific community
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/04-join-requests.md
 * STATUS: implemented
 */

interface ConflictBadgeProps {
  communityName: string;
}

export function ConflictBadge({ communityName }: ConflictBadgeProps) {
  return (
    <span className="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-900">
      Already in {communityName}
    </span>
  );
}
