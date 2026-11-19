/**
 * src/features/pathways/components/PathwayList.tsx
 *
 * WHAT: Pathways as selectable cards: name, published/draft chip, number of steps and learners (or what unlocks it)
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

import { QueueList } from "@/components/common/QueueList";
import type { Pathway } from "../queries";

interface PathwayListProps {
  pathways: Pathway[];
  selectedId?: string | null;
  onSelect: (pathway: Pathway) => void;
}

export function PathwayList({ pathways, selectedId, onSelect }: PathwayListProps) {
  return (
    <QueueList
      items={pathways.map((pw) => ({
        id: pw.id,
        title: pw.name,
        status: pw.published ? "Published" : "Draft",
        variant: pw.published ? "active" : "inactive",
        lines: [
          `${pw.steps.length} ${pw.steps.length === 1 ? "step" : "steps"} · ${
            pw.unlockRule !== "none" && pw.lockedUntilInfo ? pw.lockedUntilInfo : `${pw.learnersCount} learners`
          }`,
        ],
      }))}
      selectedId={selectedId}
      onSelect={(id) => {
        const pw = pathways.find((p) => p.id === id);
        if (pw) onSelect(pw);
      }}
      emptyText="No pathways created yet. Use “New pathway” to create the first discipleship track."
    />
  );
}
