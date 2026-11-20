/**
 * src/app/(backoffice)/pathways/[id]/page.tsx
 *
 * WHAT: Edit pathway: name, theme, level, ordered steps, unlock rule, badge awarded
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { PathwayEditor } from "@/features/pathways/components/PathwayEditor";
import { fetchPathway, type Pathway } from "@/features/pathways/queries";
import { ROUTES } from "@/lib/constants/routes";

export default function EditPathwayPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const [pathway, setPathway] = useState<Pathway | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPathway(id)
      .then(setPathway)
      .catch(() => setError("Failed to load pathway details."))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <div className="p-8 text-center text-sm text-muted">
        Loading pathway details…
      </div>
    );
  }

  if (error || !pathway) {
    return (
      <div className="space-y-4">
        <div role="alert" className="rounded-md border border-danger/40 bg-danger-soft p-4 text-sm text-danger">
          {error ?? "Pathway not found."}
        </div>
        <Link
          href={ROUTES.pathways}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-primary hover:underline"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to pathways</span>
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div className="flex items-center justify-between">
        <div>
          <Link
            href={ROUTES.pathways}
            className="inline-flex items-center gap-1.5 text-xs text-muted hover:text-foreground mb-1"
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            <span>Back to pathways</span>
          </Link>
          <h1 className="text-[34px] leading-[1.05]">
            Edit Pathway: {pathway.name}
          </h1>
        </div>
      </div>

      <PathwayEditor initialPathway={pathway} />
    </div>
  );
}
