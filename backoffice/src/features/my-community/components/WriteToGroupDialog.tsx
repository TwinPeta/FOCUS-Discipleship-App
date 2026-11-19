/**
 * src/features/my-community/components/WriteToGroupDialog.tsx
 *
 * WHAT: Send a message to the whole community group
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { Megaphone } from "lucide-react";
import { writeToCommunityGroup } from "../queries";

export function WriteToGroupDialog({ communityName }: { communityName: string }) {
  const [open, setOpen] = useState(false);
  const [subject, setSubject] = useState("");
  const [message, setMessage] = useState("");
  const [sending, setSending] = useState(false);
  const [sentBanner, setSentBanner] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!subject.trim() || !message.trim()) return;
    setSending(true);
    try {
      await writeToCommunityGroup({
        subject: subject.trim(),
        message: message.trim(),
      });
      setSentBanner(`Notification sent to ${communityName}.`);
      setSubject("");
      setMessage("");
      setOpen(false);
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="flex items-center gap-3">
      {sentBanner && (
        <span className="text-xs text-ink" role="status">
          {sentBanner}
        </span>
      )}

      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90"
      >
        <Megaphone className="h-4 w-4" aria-hidden="true" />
        <span>Write to the group</span>
      </button>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Write to caregroup group"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
        >
          <form
            onSubmit={handleSubmit}
            className="w-full max-w-md space-y-4 rounded-xl border border-border bg-white p-5 shadow-lg"
          >
            <div>
              <h3 className="text-base font-semibold text-foreground">
                Write to {communityName}
              </h3>
              <p className="mt-0.5 text-xs text-muted">
                Sends a notification to all members of your caregroup.
              </p>
            </div>

            <div className="space-y-1">
              <label htmlFor="group-msg-subject" className="block text-[13px] font-extrabold">
                Subject
              </label>
              <input
                id="group-msg-subject"
                type="text"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                placeholder="e.g. Thursday fellowship location update"
                className="w-full rounded-md border border-border px-3 py-2 text-sm text-foreground"
                required
              />
            </div>

            <div className="space-y-1">
              <label htmlFor="group-msg-body" className="block text-[13px] font-extrabold">
                Message
              </label>
              <textarea
                id="group-msg-body"
                rows={4}
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Write your announcement…"
                className="w-full rounded-md border border-border px-3 py-2 text-sm text-foreground"
                required
              />
            </div>

            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-md border border-border px-3.5 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={sending}
                className="rounded-md bg-primary px-3.5 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
              >
                {sending ? "Sending…" : "Send notification"}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
