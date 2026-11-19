/**
 * src/features/notifications/components/InactivityDaysField.tsx
 *
 * WHAT: Configurable inactivity threshold days field (default 14 days)
 * REQUIREMENTS: FR-19,FR-05
 * SPEC: docs/features/10-notifications.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { Clock } from "lucide-react";
import { updateInactivityDays } from "../queries";

interface InactivityDaysFieldProps {
  initialDays: number;
}

export function InactivityDaysField({ initialDays }: InactivityDaysFieldProps) {
  const [days, setDays] = useState(initialDays);
  const [savedNote, setSavedNote] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    setSaving(true);
    setSavedNote(null);
    try {
      await updateInactivityDays(days);
      setSavedNote("Threshold saved successfully.");
      setTimeout(() => setSavedNote(null), 3000);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-border bg-white p-5 shadow-sm">
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <Clock className="h-4 w-4 text-primary" />
          <h2 className="eyebrow">
            Inactivity Follow-Up Threshold
          </h2>
        </div>
        <p className="text-xs text-muted max-w-xl">
          Members with no login activity past this number of days are flagged in the Super-mentor follow-up list and triggered for inactivity check-in notifications.
        </p>
      </div>

      <div className="flex items-center gap-3">
        {savedNote && (
          <span className="text-xs text-ink" role="status">
            {savedNote}
          </span>
        )}
        <div className="flex items-center gap-2">
          <input
            id="inactivity-threshold"
            type="number"
            min={1}
            max={365}
            value={days}
            onChange={(e) => setDays(Math.max(1, parseInt(e.target.value) || 1))}
            className="w-20 rounded-md border border-border px-3 py-1.5 text-center text-sm text-foreground focus:ring-2 focus:ring-primary"
            aria-label="Inactivity threshold in days"
          />
          <span className="text-xs text-muted">days</span>
        </div>
        <button
          type="button"
          onClick={handleSave}
          disabled={saving}
          className="rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
        >
          {saving ? "Saving…" : "Save threshold"}
        </button>
      </div>
    </div>
  );
}
