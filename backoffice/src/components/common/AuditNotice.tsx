/**
 * src/components/common/AuditNotice.tsx
 *
 * WHAT: Standard note that the action is recorded in the audit log
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { ShieldCheck } from "lucide-react";

interface AuditNoticeProps {
  message?: string;
}

export function AuditNotice({
  message = "Viewing personal data and taking account or moderation actions are recorded in the audit log.",
}: AuditNoticeProps) {
  return (
    <div role="note" className="notice">
      <ShieldCheck className="h-[22px] w-[22px] shrink-0" aria-hidden="true" />
      <span>{message}</span>
    </div>
  );
}
