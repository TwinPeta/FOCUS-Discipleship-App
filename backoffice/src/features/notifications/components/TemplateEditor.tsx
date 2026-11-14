/**
 * src/features/notifications/components/TemplateEditor.tsx
 *
 * WHAT: Editor for notification templates with variable chips and live preview
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { X } from "lucide-react";
import { NotificationPreview } from "./NotificationPreview";
import type { NotificationRule } from "../queries";

interface TemplateEditorProps {
  rule: NotificationRule;
  onSave: (updates: Partial<NotificationRule>) => void;
  onClose: () => void;
}

const TEMPLATE_VARIABLES = [
  { tag: "{{member_name}}", label: "Member name" },
  { tag: "{{community_name}}", label: "Community name" },
  { tag: "{{item_title}}", label: "Item / Event title" },
  { tag: "{{message_preview}}", label: "Message preview" },
];

export function TemplateEditor({ rule, onSave, onClose }: TemplateEditorProps) {
  const [title, setTitle] = useState(rule.template.title);
  const [message, setMessage] = useState(rule.template.message);
  const [inApp, setInApp] = useState(rule.channels.inApp);
  const [email, setEmail] = useState(rule.channels.email);
  const [error, setError] = useState<string | null>(null);

  function insertVariable(tag: string) {
    setMessage((prev) => `${prev} ${tag}`);
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!title.trim() || !message.trim()) {
      setError("Both title and message are required.");
      return;
    }
    if (!inApp && !email) {
      setError("At least one notification channel must be enabled.");
      return;
    }

    onSave({
      template: { title: title.trim(), message: message.trim() },
      channels: { ...rule.channels, inApp, email },
    });
    onClose();
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Edit notification template"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <div className="w-full max-w-2xl space-y-4 rounded-xl border border-border bg-white p-6 shadow-xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between border-b border-border pb-3">
          <div>
            <h3 className="text-base font-semibold text-foreground">
              Edit Template: {rule.triggerLabel}
            </h3>
            <p className="text-xs text-muted">Recipient: {rule.recipient}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded p-1 text-muted hover:text-foreground"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {error && (
          <div role="alert" className="rounded-md border border-rose-200 bg-rose-50 p-2.5 text-xs text-rose-800">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label htmlFor="tpl-title" className="block text-xs font-medium text-muted">
              Notification Title
            </label>
            <input
              id="tpl-title"
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full rounded-md border border-border px-3 py-1.5 text-sm text-foreground focus:ring-2 focus:ring-primary"
              required
            />
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <label htmlFor="tpl-message" className="block text-xs font-medium text-muted">
                Message Content
              </label>
              <span className="text-[11px] text-muted">Click a variable tag to append</span>
            </div>
            <textarea
              id="tpl-message"
              rows={3}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="w-full rounded-md border border-border px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
              required
            />
            <div className="flex flex-wrap gap-1.5 pt-1">
              {TEMPLATE_VARIABLES.map((v) => (
                <button
                  key={v.tag}
                  type="button"
                  onClick={() => insertVariable(v.tag)}
                  className="rounded border border-border bg-slate-50 px-2 py-0.5 text-[11px] font-mono text-foreground hover:bg-slate-100"
                >
                  + {v.tag}
                </button>
              ))}
            </div>
          </div>

          <div className="space-y-1.5 pt-1">
            <label className="block text-xs font-medium text-muted">Enabled Delivery Channels</label>
            <div className="flex gap-4">
              <label className="flex items-center gap-2 text-xs font-medium text-foreground cursor-pointer">
                <input
                  type="checkbox"
                  checked={inApp}
                  onChange={(e) => setInApp(e.target.checked)}
                  className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                />
                <span>In-App Notification</span>
              </label>
              <label className="flex items-center gap-2 text-xs font-medium text-foreground cursor-pointer">
                <input
                  type="checkbox"
                  checked={email}
                  onChange={(e) => setEmail(e.target.checked)}
                  className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
                />
                <span>Email Delivery</span>
              </label>
            </div>
          </div>

          <NotificationPreview
            template={{ title, message }}
            channels={{ inApp, email }}
          />

          <div className="flex items-center justify-end gap-2 border-t border-border pt-4">
            <button
              type="button"
              onClick={onClose}
              className="rounded-md border border-border px-3.5 py-1.5 text-xs font-medium text-foreground hover:bg-slate-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="rounded-md bg-primary px-4 py-1.5 text-xs font-medium text-white hover:opacity-90"
            >
              Save Template
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
