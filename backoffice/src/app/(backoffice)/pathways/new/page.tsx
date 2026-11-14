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
    <main className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-foreground">Create New Pathway</h1>
        <p className="mt-1 text-sm text-muted">
          Define a discipleship pathway, assemble ordered learning steps from the library, and configure unlock conditions.
        </p>
      </div>

      <PathwayEditor />
    </main>
  );
}
