/**
 * src/features/badges/components/BadgeForm.tsx
 *
 * WHAT: Create and edit badge modal dialog
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import { X } from "lucide-react";
import { IconPicker } from "./IconPicker";
import { RuleSelect } from "./RuleSelect";
import {
  saveBadge,
  type Badge,
  type BadgeRuleType,
} from "../queries";

interface BadgeFormProps {
  badge?: Badge | null;
  onSaved: (badge: Badge) => void;
  onClose: () => void;
}

export function BadgeForm({ badge, onSaved, onClose }: BadgeFormProps) {
  const [name, setName] = useState(badge?.name ?? "");
  const [description, setDescription] = useState(badge?.description ?? "");
  const [icon, setIcon] = useState(badge?.icon ?? "award");
  const [ruleType, setRuleType] = useState<BadgeRuleType>(badge?.ruleType ?? "complete_pathway");
  const [ruleTargetCount, setRuleTargetCount] = useState<number>(badge?.ruleTargetCount ?? 1);
  const [visibleOnProfile, setVisibleOnProfile] = useState<boolean>(badge?.visibleOnProfile ?? true);
  const [status, setStatus] = useState<"active" | "draft" | "archived">(badge?.status ?? "active");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!name.trim()) {
      setError("Badge name is required.");
      return;
    }
    if (!description.trim()) {
      setError("Description is required.");
      return;
    }

    setSaving(true);
    try {
      const saved = await saveBadge(
        {
          name: name.trim(),
          description: description.trim(),
          icon,
          ruleType,
          ruleTargetCount,
          visibleOnProfile,
          status,
        },
        badge?.id,
      );
      onSaved(saved);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save badge.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={badge ? "Edit badge" : "New badge"}
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    >
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-lg space-y-4 rounded-xl border border-border bg-white p-6 shadow-xl max-h-[90vh] overflow-y-auto"
      >
        <div className="flex items-center justify-between border-b border-border pb-3">
          <div>
            <h3 className="text-base font-semibold text-foreground">
              {badge ? "Edit Discipleship Badge" : "New Discipleship Badge"}
            </h3>
            <p className="text-xs text-muted">
              Define achievement badge criteria, icon and profile visibility.
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded p-1 text-muted hover:text-foreground"
            aria-label="Close dialog"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {error && (
          <div role="alert" className="rounded-md border border-rose-200 bg-rose-50 p-2.5 text-xs text-rose-800">
            {error}
          </div>
        )}

        <div className="space-y-1.5">
          <label htmlFor="badge-name-input" className="block text-sm font-medium text-foreground">
            Badge name
          </label>
          <input
            id="badge-name-input"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. Faithful Disciple"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            required
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="badge-desc-input" className="block text-sm font-medium text-foreground">
            Description
          </label>
          <textarea
            id="badge-desc-input"
            rows={2}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Short spiritual celebration description..."
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            required
          />
        </div>

        <IconPicker value={icon} onChange={setIcon} />

        <RuleSelect
          ruleType={ruleType}
          ruleTargetCount={ruleTargetCount}
          onRuleTypeChange={setRuleType}
          onTargetCountChange={setRuleTargetCount}
        />

        <div className="grid gap-3 sm:grid-cols-2 pt-1">
          <div className="space-y-1.5">
            <label htmlFor="badge-status-select" className="block text-sm font-medium text-foreground">
              Status
            </label>
            <select
              id="badge-status-select"
              value={status}
              onChange={(e) => setStatus(e.target.value as "active" | "draft" | "archived")}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            >
              <option value="active">Active (Awardable)</option>
              <option value="draft">Draft</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <div className="flex items-center pt-6">
            <label className="flex items-center gap-2 text-xs font-medium text-foreground cursor-pointer">
              <input
                type="checkbox"
                checked={visibleOnProfile}
                onChange={(e) => setVisibleOnProfile(e.target.checked)}
                className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
              />
              <span>Visible on student profile</span>
            </label>
          </div>
        </div>

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
            disabled={saving}
            className="rounded-md bg-primary px-4 py-1.5 text-xs font-medium text-white hover:opacity-90 disabled:opacity-50"
          >
            {saving ? "Saving…" : badge ? "Save changes" : "Create badge"}
          </button>
        </div>
      </form>
    </div>
  );
}
