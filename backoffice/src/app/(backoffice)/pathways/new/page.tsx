/**
 * src/app/(backoffice)/pathways/new/page.tsx
 *
 * WHAT: New pathway creation
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

import { PathwayEditor } from "@/features/pathways/components/PathwayEditor";

export default function NewPathwayPage() {
  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">Create New Pathway</h1>
        <p className="mt-1 text-sm text-muted">
          Define a discipleship pathway, assemble ordered learning steps from the library, and configure unlock conditions.
        </p>
      </div>

      <PathwayEditor />
    </div>
  );
}
