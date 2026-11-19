/**
 * src/app/(backoffice)/moderation/layout.tsx
 *
 * WHAT: Moderation shell: community filter and tabs (reports, testimonies, prayer and posts, sanctions) with counts
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

import type { ReactNode } from "react";
import { AuditNotice } from "@/components/common/AuditNotice";
import { ModerationTabs } from "@/features/moderation/components/ModerationTabs";

export default function ModerationLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">Moderation</h1>
        <p>Review reports, testimonies, prayer requests, posts, and user sanctions.</p>
      </div>

      <ModerationTabs />
      <AuditNotice message="All moderation actions, escalations, sanctions, and reinstatements are recorded in the audit log." />
      {children}
    </div>
  );
}
