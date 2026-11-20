/**
 * src/features/settings/components/JoinRequestsForm.tsx
 *
 * WHAT: Whether requests to join a specific community are approved at once (default) or wait for a super-mentor
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { fetchSettings, saveJoinRequestSettings } from "@/features/settings/queries";
import type { JoinRequestSettings } from "@/features/settings/schemas";

export function JoinRequestsForm() {
  const [autoApprove, setAutoApprove] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    let active = true;
    fetchSettings<JoinRequestSettings>("joinRequests").then((s) => {
      if (active && s) setAutoApprove(s.autoApprove !== false);
    });
    return () => {
      active = false;
    };
  }, []);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setSaved(false);
    try {
      await saveJoinRequestSettings({ autoApprove });
      setSaved(true);
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      {saved && (
        <p role="status" className="text-xs font-medium text-ink">
          Join request setting saved.
        </p>
      )}
      <label className="flex items-start gap-2 text-sm">
        <input
          type="checkbox"
          className="mt-0.5 h-4 w-4 accent-primary"
          checked={autoApprove}
          onChange={(e) => setAutoApprove(e.target.checked)}
        />
        <span>
          Approve requests to join a specific caregroup automatically
          <span className="block text-xs text-muted-foreground">
            Students join at once. Turn off to have super-mentors approve each request (Join requests list).
          </span>
        </span>
      </label>
      <button
        type="submit"
        disabled={saving}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
      >
        {saving ? "Saving..." : "Save"}
      </button>
    </form>
  );
}
