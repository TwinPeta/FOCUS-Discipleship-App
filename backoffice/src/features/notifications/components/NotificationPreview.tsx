/**
 * src/features/notifications/components/NotificationPreview.tsx
 *
 * WHAT: In-app banner and email simulation preview for notification templates
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

import { Bell, Mail } from "lucide-react";
import type { NotificationTemplate } from "../queries";

interface NotificationPreviewProps {
  template: NotificationTemplate;
  channels: { inApp: boolean; email: boolean };
}

function interpolateSample(text: string): string {
  return text
    .replace(/\{\{member_name\}\}/g, "[Member name]")
    .replace(/\{\{community_name\}\}/g, "[Community name]")
    .replace(/\{\{item_title\}\}/g, "Faithful Discipleship")
    .replace(/\{\{message_preview\}\}/g, "Registration has opened for the annual conference.");
}

export function NotificationPreview({ template, channels }: NotificationPreviewProps) {
  const renderedTitle = interpolateSample(template.title);
  const renderedMessage = interpolateSample(template.message);

  return (
    <div className="space-y-4 rounded-xl border border-border bg-slate-50/50 p-4">
      <h3 className="text-xs font-semibold uppercase tracking-wider text-muted">
        Live Message Preview
      </h3>

      {channels.inApp && (
        <div className="space-y-1.5">
          <div className="flex items-center gap-1.5 text-xs font-medium text-foreground">
            <Bell className="h-3.5 w-3.5 text-primary" />
            <span>In-App Mobile Push Notification</span>
          </div>
          <div className="rounded-lg border border-border bg-white p-3 shadow-sm">
            <div className="flex items-start gap-2.5">
              <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary text-white text-[10px] font-bold">
                FCU
              </div>
              <div className="space-y-0.5">
                <p className="text-xs font-bold text-foreground">{renderedTitle}</p>
                <p className="text-xs text-foreground/80">{renderedMessage}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {channels.email && (
        <div className="space-y-1.5">
          <div className="flex items-center gap-1.5 text-xs font-medium text-foreground">
            <Mail className="h-3.5 w-3.5 text-primary" />
            <span>Email Notification</span>
          </div>
          <div className="rounded-lg border border-border bg-white p-4 shadow-sm text-xs space-y-2">
            <div className="border-b border-border pb-1.5 text-muted">
              <span className="font-semibold text-foreground">Subject: </span>
              {renderedTitle}
            </div>
            <p className="text-foreground leading-relaxed whitespace-pre-line pt-1">
              {renderedMessage}
            </p>
            <div className="border-t border-border pt-2 text-[10px] text-muted">
              Sent by FOCUS Uganda Discipleship System · Unsubscribe settings available in app profile.
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
