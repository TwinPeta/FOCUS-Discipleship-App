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
    <div className="flex flex-col gap-5">
      {loadError && <ErrorState message={loadError} />}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Badges</h1>
          <p>Spiritual growth milestones, caregroup engagement recognitions, and pathway achievement rewards.</p>
        </div>

        <button type="button" onClick={() => setEditingBadge(null)} className="btn btn-primary">
          <Plus className="h-5 w-5" strokeWidth={2.6} aria-hidden="true" />
          New badge
        </button>
      </div>

      <div className="flex flex-wrap items-start gap-4">
        <BadgeTable badges={badges} onEditBadge={(b) => setEditingBadge(b)} selectedId={editingBadge?.id} />

        {editingBadge !== undefined && (
          <BadgeForm
            key={editingBadge?.id ?? "new"}
            badge={editingBadge}
            onSaved={handleSaved}
            onClose={() => setEditingBadge(undefined)}
          />
        )}
      </div>

      <p className="notice">
        <span>Badges are a proposal. Check with FOCUS Uganda that they suit the spiritual context. Rules are evaluated automatically from meeting attendance, quiz completions and pathway milestones.</span>
      </p>
    </div>
  );
}
