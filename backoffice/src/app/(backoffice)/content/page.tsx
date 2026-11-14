/**
 * src/app/(backoffice)/content/page.tsx
 *
 * WHAT: B5 Content library and validation: status tabs, search, filters, link to new content
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ContentTable } from "@/features/content/components/ContentTable";
import type { ContentItem } from "@/features/content/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function ContentLibraryPage() {
  const initialItems: ContentItem[] = [];

  return (
    <div className="space-y-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Content library</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Create, validate, and publish videos, devotionals, quizzes, and study
            documents.
          </p>
        </div>

        <Link
          href={ROUTES.contentNew}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95"
        >
          New content
        </Link>
      </div>

      <ContentTable initialItems={initialItems} />
    </div>
  );
}
