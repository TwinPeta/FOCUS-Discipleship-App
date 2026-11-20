/**
 * src/features/pathways/components/PathwayEditor.tsx
 *
 * WHAT: Full pathway editor: name, theme, level, ordered steps, unlock rule, badge awarded, draft/publish
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { useState, type FormEvent } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ROUTES } from "@/lib/constants/routes";
import { AddStepDialog } from "./AddStepDialog";
import { StepList } from "./StepList";
import { UnlockRuleSelect } from "./UnlockRuleSelect";
import {
  savePathway,
  type Pathway,
  type PathwayLevel,
  type PathwayStep,
  type UnlockRuleType,
} from "../queries";

interface PathwayEditorProps {
  initialPathway?: Pathway | null;
  /** When given, the editor stays on the page (inline panel) instead of navigating away */
  onSaved?: (saved: Pathway) => void;
  onCancel?: () => void;
}

const AVAILABLE_BADGES = [
  { id: "bdg-1", name: "Faithful Disciple" },
  { id: "bdg-2", name: "Servant Leader" },
  { id: "bdg-3", name: "Bible Scholar" },
  { id: "bdg-4", name: "Prayer Champion" },
];

export function PathwayEditor({ initialPathway, onSaved, onCancel }: PathwayEditorProps) {
  const router = useRouter();
  const [name, setName] = useState(initialPathway?.name ?? "");
  const [theme, setTheme] = useState(initialPathway?.theme ?? "");
  const [level, setLevel] = useState<PathwayLevel>(initialPathway?.level ?? "Beginner");
  const [description, setDescription] = useState(initialPathway?.description ?? "");
  const [steps, setSteps] = useState<PathwayStep[]>(initialPathway?.steps ?? []);
  const [unlockRule, setUnlockRule] = useState<UnlockRuleType>(initialPathway?.unlockRule ?? "none");
  const [badgeAwardedId, setBadgeAwardedId] = useState<string | null>(initialPathway?.badgeAwardedId ?? null);
  const [published, setPublished] = useState<boolean>(initialPathway?.published ?? false);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function handleAddStep(step: PathwayStep) {
    setSteps((prev) => [...prev, step]);
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!name.trim()) {
      setError("Pathway name is required.");
      return;
    }
    if (!theme.trim()) {
      setError("Theme is required.");
      return;
    }
    if (steps.length === 0) {
      setError("Pathway must contain at least one step.");
      return;
    }

    setSaving(true);
    try {
      const saved = await savePathway(
        {
          name: name.trim(),
          theme: theme.trim(),
          level,
          description: description.trim() || undefined,
          steps,
          unlockRule,
          badgeAwardedId: badgeAwardedId || null,
          published,
        },
        initialPathway?.id,
      );
      if (onSaved) {
        onSaved(saved);
      } else {
        router.push(ROUTES.pathways);
        router.refresh();
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save pathway.");
    } finally {
      setSaving(false);
    }
  }

  const existingContentIds = steps.map((s) => s.contentId);

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      {error && (
        <div role="alert" className="rounded-md border border-danger/40 bg-danger-soft p-3 text-sm text-danger">
          {error}
        </div>
      )}

      <div className="card flex flex-col gap-4">
        <div className="space-y-4">
          <div className="space-y-1.5">
            <label htmlFor="pathway-name" className="block text-[13px] font-extrabold">
              Pathway name
            </label>
            <input
              id="pathway-name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Foundations of Discipleship"
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
              required
            />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <label htmlFor="pathway-theme" className="block text-[13px] font-extrabold">
                Theme / Ministry area
              </label>
              <input
                id="pathway-theme"
                type="text"
                value={theme}
                onChange={(e) => setTheme(e.target.value)}
                placeholder="e.g. Spiritual Growth"
                className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
                required
              />
            </div>

            <div className="space-y-1.5">
              <label htmlFor="pathway-level" className="block text-[13px] font-extrabold">
                Difficulty level
              </label>
              <select
                id="pathway-level"
                value={level}
                onChange={(e) => setLevel(e.target.value as PathwayLevel)}
                className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
              >
                <option value="Beginner">Beginner</option>
                <option value="Intermediate">Intermediate</option>
                <option value="Advanced">Advanced</option>
              </select>
            </div>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="pathway-description" className="block text-[13px] font-extrabold">
              Description
            </label>
            <textarea
              id="pathway-description"
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Brief summary of what the learner will gain..."
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            />
          </div>
        </div>

        <div className="space-y-4">
          <UnlockRuleSelect value={unlockRule} onChange={setUnlockRule} />

          <div className="space-y-1.5">
            <label htmlFor="pathway-badge" className="block text-[13px] font-extrabold">
              Badge awarded upon completion
            </label>
            <select
              id="pathway-badge"
              value={badgeAwardedId ?? ""}
              onChange={(e) => setBadgeAwardedId(e.target.value || null)}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary"
            >
              <option value="">No badge</option>
              {AVAILABLE_BADGES.map((b) => (
                <option key={b.id} value={b.id}>
                  {b.name}
                </option>
              ))}
            </select>
            <p className="text-xs text-muted">
              Students earn this badge automatically after completing all required steps.
            </p>
          </div>

          <div className="pt-2">
            <label className="flex items-center gap-2.5 text-sm font-medium text-foreground cursor-pointer">
              <input
                type="checkbox"
                checked={published}
                onChange={(e) => setPublished(e.target.checked)}
                className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
              />
              <span>Publish this pathway (make visible in student app)</span>
            </label>
          </div>
        </div>
      </div>

      <section className="card flex flex-col gap-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="eyebrow">Pathway steps</h2>
            <p className="text-xs text-muted">
              Add devotionals, videos, documents, or quizzes in sequential order.
            </p>
          </div>
          <AddStepDialog
            existingStepContentIds={existingContentIds}
            onAddStep={handleAddStep}
          />
        </div>

        <StepList steps={steps} onChange={setSteps} />
      </section>

      <div className="flex flex-wrap items-center gap-2.5">
        <button type="submit" disabled={saving} className="btn btn-primary">
          {saving ? "Saving…" : initialPathway ? "Update pathway" : "Create pathway"}
        </button>
        {onCancel ? (
          <button type="button" onClick={onCancel} className="btn btn-secondary">
            Cancel
          </button>
        ) : (
          <Link href={ROUTES.pathways} className="btn btn-secondary">
            Cancel
          </Link>
        )}
      </div>
    </form>
  );
}
