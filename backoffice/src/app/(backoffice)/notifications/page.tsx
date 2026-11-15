/**
 * src/app/(backoffice)/notifications/page.tsx
 *
 * WHAT: B22 Notifications: rules table (when, who, channels, on) and template editor with preview
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { InactivityDaysField } from "@/features/notifications/components/InactivityDaysField";
import { NotificationRuleTable } from "@/features/notifications/components/NotificationRuleTable";
import { TemplateEditor } from "@/features/notifications/components/TemplateEditor";
import {
  fetchInactivityDays,
  fetchNotificationRules,
  updateNotificationRule,
  type NotificationRule,
} from "@/features/notifications/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function NotificationsPage() {
  const [rules, setRules] = useState<NotificationRule[]>([]);
  const [inactivityDays, setInactivityDays] = useState<number | null>(null);
  const [editingRule, setEditingRule] = useState<NotificationRule | null>(null);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchNotificationRules()
      .then((res) => {
        if (active) setRules(res);
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    fetchInactivityDays()
      .then((days) => {
        if (active) setInactivityDays(days);
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    return () => {
      active = false;
    };
  }, []);

  async function handleToggleRule(id: string, enabled: boolean) {
    const updated = await updateNotificationRule(id, { enabled });
    setRules((prev) => prev.map((r) => (r.id === id ? updated : r)));
  }

  async function handleSaveTemplate(updates: Partial<NotificationRule>) {
    if (!editingRule) return;
    const updated = await updateNotificationRule(editingRule.id, updates);
    setRules((prev) => prev.map((r) => (r.id === editingRule.id ? updated : r)));
  }

  return (
    <main className="space-y-6">
      {loadError && <ErrorState message={loadError} />}
      <div>
        <h1 className="text-2xl font-semibold text-foreground">
          Notifications &amp; Inactivity Rules
        </h1>
        <p className="mt-1 text-sm text-muted">
          Configure automated notification triggers, delivery channels, template wording, and member follow-up thresholds.
        </p>
      </div>

      <div className="rounded-lg border border-border bg-slate-50 p-3.5 text-xs text-muted">
        <span className="font-semibold text-foreground">Channel Scope (Open Question #12): </span>
        Push notifications and transactional emails are delivered across all configured triggers. SMS delivery mentioned in initial BRD is deferred pending telecom gateway integration.
      </div>

      {inactivityDays !== null && (
        <InactivityDaysField key={inactivityDays} initialDays={inactivityDays} />
      )}

      <section className="space-y-3">
        <h2 className="text-base font-semibold text-foreground">Notification Triggers</h2>
        <NotificationRuleTable
          rules={rules}
          onToggleRule={handleToggleRule}
          onEditTemplate={(rule) => setEditingRule(rule)}
        />
      </section>

      {editingRule && (
        <TemplateEditor
          rule={editingRule}
          onSave={handleSaveTemplate}
          onClose={() => setEditingRule(null)}
        />
      )}
    </main>
  );
}
