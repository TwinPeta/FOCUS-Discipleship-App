/**
 * src/features/reports/components/ScheduleReportDialog.tsx
 *
 * WHAT: Create a scheduled report: report type, cadence, recipient email
 * REQUIREMENTS: FR-04
 * SPEC: docs/features/02-dashboard-reports.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { CalendarPlus } from "lucide-react";
import { createScheduledReport, type ScheduledReport } from "../queries";
import { scheduleReportSchema, type ScheduleReportInput } from "../schemas";

export function ScheduleReportDialog({
  onCreated,
}: {
  onCreated: (schedule: ScheduledReport) => void;
}) {
  const [open, setOpen] = useState(false);
  const [reportType, setReportType] =
    useState<ScheduleReportInput["reportType"]>("discipleship_summary");
  const [cadence, setCadence] = useState<ScheduleReportInput["cadence"]>("monthly");
  const [recipientEmail, setRecipientEmail] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    const parsed = scheduleReportSchema.safeParse({
      reportType,
      cadence,
      recipientEmail: recipientEmail.trim(),
    });
    if (!parsed.success) {
      setError(parsed.error.issues[0]?.message ?? "Invalid schedule settings.");
      return;
    }

    setSubmitting(true);
    try {
      const created = await createScheduledReport(parsed.data);
      onCreated(created);
      setRecipientEmail("");
      setOpen(false);
    } finally {
      setSubmitting(false);
    }
  }

  if (!open) {
    return (
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3.5 py-2 text-xs font-medium text-white hover:opacity-90"
      >
        <CalendarPlus className="h-3.5 w-3.5" aria-hidden="true" />
        <span>Schedule report</span>
      </button>
    );
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Schedule recurring report"
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md space-y-4 rounded-xl border border-border bg-white p-5 shadow-lg"
      >
        <h3 className="text-base font-semibold text-foreground">
          Schedule recurring report
        </h3>

        {error && (
          <div
            role="alert"
            className="rounded-md border border-danger/40 bg-danger-soft px-3 py-2 text-xs text-danger"
          >
            {error}
          </div>
        )}

        <div className="space-y-1">
          <label htmlFor="sched-type" className="block text-[13px] font-extrabold">
            Report type
          </label>
          <select
            id="sched-type"
            value={reportType}
            onChange={(e) =>
              setReportType(e.target.value as ScheduleReportInput["reportType"])
            }
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
          >
            <option value="discipleship_summary">Discipleship summary</option>
            <option value="community_health">Caregroup health &amp; attendance</option>
            <option value="content_completions">Content completions</option>
          </select>
        </div>

        <div className="space-y-1">
          <label htmlFor="sched-cadence" className="block text-[13px] font-extrabold">
            Cadence
          </label>
          <select
            id="sched-cadence"
            value={cadence}
            onChange={(e) =>
              setCadence(e.target.value as ScheduleReportInput["cadence"])
            }
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
          >
            <option value="weekly">Weekly</option>
            <option value="monthly">Monthly</option>
            <option value="quarterly">Quarterly</option>
          </select>
        </div>

        <div className="space-y-1">
          <label htmlFor="sched-email" className="block text-[13px] font-extrabold">
            Recipient email
          </label>
          <input
            id="sched-email"
            type="email"
            value={recipientEmail}
            onChange={(e) => setRecipientEmail(e.target.value)}
            placeholder="leadership@focusuganda.org"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground"
            required
          />
        </div>

        <div className="flex justify-end gap-2 pt-2">
          <button
            type="button"
            onClick={() => setOpen(false)}
            className="rounded-md border border-border px-3.5 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="rounded-md bg-primary px-3.5 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
          >
            {submitting ? "Saving…" : "Create schedule"}
          </button>
        </div>
      </form>
    </div>
  );
}
