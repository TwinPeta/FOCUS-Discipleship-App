/**
 * src/features/notifications/components/NotificationRuleTable.tsx
 *
 * WHAT: Rules table with triggers, recipients, channel badges, on/off toggles and edit template button
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

"use client";

import { Bell, Edit2, Mail } from "lucide-react";
import type { NotificationRule } from "../queries";

interface NotificationRuleTableProps {
  rules: NotificationRule[];
  onToggleRule: (id: string, enabled: boolean) => void;
  onEditTemplate: (rule: NotificationRule) => void;
}

export function NotificationRuleTable({
  rules,
  onToggleRule,
  onEditTemplate,
}: NotificationRuleTableProps) {
  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-white shadow-sm">
      <table className="w-full border-collapse text-left text-sm">
        <thead>
          <tr className="border-b border-border bg-blue-tint text-xs font-semibold uppercase tracking-wide text-muted">
            <th className="px-4 py-3">Event / Trigger</th>
            <th className="px-4 py-3">Recipient</th>
            <th className="px-4 py-3 text-center">Channels</th>
            <th className="px-4 py-3">Message Summary</th>
            <th className="px-4 py-3 text-center">Status</th>
            <th className="px-4 py-3 text-right">Template</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-border">
          {rules.map((rule) => (
            <tr key={rule.id} className="hover:bg-blue-tint">
              <td className="px-4 py-3.5">
                <div className="font-semibold text-foreground">{rule.triggerLabel}</div>
                <div className="text-[11px] font-mono text-muted">{rule.triggerKey}</div>
              </td>
              <td className="px-4 py-3.5 text-xs text-foreground font-medium">
                {rule.recipient}
              </td>
              <td className="px-4 py-3.5 text-center">
                <div className="flex items-center justify-center gap-2">
                  <span
                    title={rule.channels.inApp ? "In-App Active" : "In-App Inactive"}
                    className={`rounded p-1 ${
                      rule.channels.inApp
                        ? "bg-primary-soft text-primary"
                        : "bg-blue-tint text-slate-300"
                    }`}
                  >
                    <Bell className="h-3.5 w-3.5" />
                  </span>
                  <span
                    title={rule.channels.email ? "Email Active" : "Email Inactive"}
                    className={`rounded p-1 ${
                      rule.channels.email
                        ? "bg-purple-50 text-purple-700"
                        : "bg-blue-tint text-slate-300"
                    }`}
                  >
                    <Mail className="h-3.5 w-3.5" />
                  </span>
                </div>
              </td>
              <td className="px-4 py-3.5 text-xs text-foreground">
                <p className="font-medium line-clamp-1">{rule.template.title}</p>
                <p className="text-muted line-clamp-1">{rule.template.message}</p>
              </td>
              <td className="px-4 py-3.5 text-center">
                <button
                  type="button"
                  onClick={() => onToggleRule(rule.id, !rule.enabled)}
                  className={`rounded-full px-2.5 py-0.5 text-xs font-medium transition ${
                    rule.enabled
                      ? "bg-blue-soft text-ink"
                      : "bg-blue-tint text-muted"
                  }`}
                >
                  {rule.enabled ? "Active" : "Disabled"}
                </button>
              </td>
              <td className="px-4 py-3.5 text-right">
                <button
                  type="button"
                  onClick={() => onEditTemplate(rule)}
                  className="inline-flex items-center gap-1 rounded-md border border-border px-2.5 py-1 text-xs font-medium text-foreground hover:bg-blue-tint"
                >
                  <Edit2 className="h-3 w-3" />
                  <span>Edit</span>
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
