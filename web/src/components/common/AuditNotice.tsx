/**
 * src/components/common/AuditNotice.tsx
 *
 * WHAT: Standard note that the action is recorded in the audit log
 * REQUIREMENTS: FR-12
 * SPEC: docs/features/16-shared-ui-brand.md
 * STATUS: implemented
 */

import { ShieldAlert } from "lucide-react";

interface AuditNoticeProps {
  message?: string;
}

export function AuditNotice({
  message = "Viewing personal data and taking account or moderation actions are recorded in the audit log.",
}: AuditNoticeProps) {
  return (
    <div
      role="note"
      className="flex items-start gap-2 rounded-md border border-border bg-primary-soft px-3 py-2 text-xs text-foreground"
    >
      <ShieldAlert className="mt-0.5 h-3.5 w-3.5 shrink-0" aria-hidden="true" />
      <span>{message}</span>
    </div>
  );
}
