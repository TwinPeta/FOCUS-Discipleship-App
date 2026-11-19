/**
 * src/app/(backoffice)/content/page.tsx
 *
 * WHAT: B5 Content library and validation: status tabs, search, filters, link to new content
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

import Link from "next/link";
import { Plus } from "lucide-react";
import { ContentTable } from "@/features/content/components/ContentTable";
import type { ContentItem } from "@/features/content/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function ContentLibraryPage() {
  const initialItems: ContentItem[] = [];

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-[34px] leading-[1.05]">Content library</h1>
          <p>Create, validate, and publish videos, devotionals, quizzes, and study documents.</p>
        </div>
        <Link href={ROUTES.contentNew} className="btn btn-primary">
          <Plus className="h-5 w-5" strokeWidth={2.6} aria-hidden="true" />
          New content
        </Link>
      </div>

      <ContentTable initialItems={initialItems} />
    </div>
  );
}
