/**
 * src/app/(backoffice)/badges/page.tsx
 *
 * WHAT: B21 Badges: table with rule, earned count, status and edit panel
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { Plus } from "lucide-react";
import { BadgeForm } from "@/features/badges/components/BadgeForm";
import { BadgeTable } from "@/features/badges/components/BadgeTable";
import {
  fetchBadges,
  type Badge,
} from "@/features/badges/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function BadgesPage() {
  const [badges, setBadges] = useState<Badge[]>([]);
  const [editingBadge, setEditingBadge] = useState<Badge | null | undefined>(undefined);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchBadges()
      .then((res) => {
        if (active) setBadges(res);
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    return () => {
      active = false;
    };
  }, []);

  function handleSaved(saved: Badge) {
    setBadges((prev) => {
      const idx = prev.findIndex((b) => b.id === saved.id);
      if (idx >= 0) {
        const copy = [...prev];
        copy[idx] = saved;
        return copy;
      }
      return [saved, ...prev];
    });
  }

  return (
    <main className="space-y-6">
      {loadError && <ErrorState message={loadError} />}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">
            Discipleship Badges
          </h1>
          <p className="mt-1 text-sm text-muted">
            Spiritual growth milestones, community engagement recognitions, and pathway achievement rewards.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setEditingBadge(null)}
          className="inline-flex items-center gap-1.5 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90"
        >
          <Plus className="h-4 w-4" aria-hidden="true" />
          <span>New badge</span>
        </button>
      </div>

      <div className="rounded-lg border border-amber-200 bg-amber-50/70 p-3.5 text-xs text-amber-900">
        <p className="font-semibold">Note on Spiritual Context (Open Question #3)</p>
        <p className="mt-0.5">
          Badges serve as encouraging milestones in discipleship rather than competitive gamification. Rules are evaluated automatically by the backend engine upon meeting attendance, quiz completions, and pathway milestones.
        </p>
      </div>

      <BadgeTable
        badges={badges}
        onEditBadge={(b) => setEditingBadge(b)}
      />

      {editingBadge !== undefined && (
        <BadgeForm
          badge={editingBadge}
          onSaved={handleSaved}
          onClose={() => setEditingBadge(undefined)}
        />
      )}
    </main>
  );
}
