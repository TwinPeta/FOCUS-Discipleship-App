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
import Link from "next/link";
import { Plus } from "lucide-react";
import { PathwayList } from "@/features/pathways/components/PathwayList";
import {
  fetchPathways,
  MOCK_PATHWAYS,
  type Pathway,
} from "@/features/pathways/queries";
import { ROUTES } from "@/lib/constants/routes";

export default function PathwaysPage() {
  const [pathways, setPathways] = useState<Pathway[]>(MOCK_PATHWAYS);

  useEffect(() => {
    let active = true;
    fetchPathways().then((res) => {
      if (active) setPathways(res);
    });
    return () => {
      active = false;
    };
  }, []);

  return (
    <main className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-foreground">
            Discipleship Pathways
          </h1>
          <p className="mt-1 text-sm text-muted">
            Guided spiritual growth journeys structured into ordered learning steps with unlock rules and completion badges.
          </p>
        </div>

        <Link
          href={ROUTES.pathwayNew}
          className="inline-flex items-center gap-1.5 rounded-md bg-primary px-4 py-2 text-sm font-medium text-white hover:opacity-90"
        >
          <Plus className="h-4 w-4" aria-hidden="true" />
          <span>New pathway</span>
        </Link>
      </div>

      <PathwayList pathways={pathways} />
    </main>
  );
}
