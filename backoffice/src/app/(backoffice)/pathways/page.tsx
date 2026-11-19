/**
 * src/app/(backoffice)/pathways/page.tsx
 *
 * WHAT: B6 Pathways: list with steps, learners, locked state and edit panel
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { Plus } from "lucide-react";
import { PathwayEditor } from "@/features/pathways/components/PathwayEditor";
import { PathwayList } from "@/features/pathways/components/PathwayList";
import {
  fetchPathways,
  type Pathway,
} from "@/features/pathways/queries";
import { ErrorState } from "@/components/feedback/ErrorState";

export default function PathwaysPage() {
  const [pathways, setPathways] = useState<Pathway[]>([]);
  const [editing, setEditing] = useState<Pathway | null | undefined>(undefined);

  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    fetchPathways()
      .then((res) => {
        if (active) setPathways(res);
      })
      .catch((e: unknown) => {
      if (active) setLoadError(e instanceof Error ? e.message : "Failed to load");
    });
    return () => {
      active = false;
    };
  }, []);

  function handleSaved(saved: Pathway) {
    setPathways((prev) => {
      const i = prev.findIndex((p) => p.id === saved.id);
      if (i >= 0) {
        const copy = [...prev];
        copy[i] = saved;
        return copy;
      }
      return [...prev, saved];
    });
    setEditing(undefined);
  }

  return (
    <div className="flex flex-col gap-5">
      {loadError && <ErrorState message={loadError} />}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Pathways</h1>
          <p>Guided spiritual growth journeys structured into ordered learning steps with unlock rules and completion badges.</p>
        </div>

        <button type="button" onClick={() => setEditing(null)} className="btn btn-primary">
          <Plus className="h-5 w-5" strokeWidth={2.6} aria-hidden="true" />
          New pathway
        </button>
      </div>

      <div className="flex flex-wrap items-start gap-4">
        <div className="min-w-0 flex-[1_1_300px] lg:max-w-[420px]">
          <PathwayList pathways={pathways} selectedId={editing?.id} onSelect={(p) => setEditing(p)} />
        </div>
        {editing !== undefined && (
          <div className="min-w-0 flex-[999_1_520px]">
            <h2 className="mb-3 text-[22px] font-black">{editing ? "Edit pathway" : "New pathway"}</h2>
            <PathwayEditor
              key={editing?.id ?? "new"}
              initialPathway={editing}
              onSaved={handleSaved}
              onCancel={() => setEditing(undefined)}
            />
          </div>
        )}
      </div>
    </div>
  );
}
