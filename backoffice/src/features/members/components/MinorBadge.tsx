/**
 * src/features/members/components/MinorBadge.tsx
 *
 * WHAT: Badge indicating a minor account and its guardian consent status
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

import { GuardianConsentStatus } from "@/types/enums";

interface MinorBadgeProps {
  consentStatus?: GuardianConsentStatus | null;
}

export function MinorBadge({ consentStatus }: MinorBadgeProps) {
  const received = consentStatus === GuardianConsentStatus.Received;

  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
        received
          ? "bg-blue-soft text-ink"
          : "bg-primary-soft text-ink"
      }`}
    >
      Minor · {received ? "Consent received" : "Consent pending"}
    </span>
  );
}
