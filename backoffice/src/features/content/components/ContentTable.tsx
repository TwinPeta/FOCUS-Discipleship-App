/**
 * src/features/content/components/ContentTable.tsx
 *
 * WHAT: Content library table with status tabs with counts and filters
 * REQUIREMENTS: FR-01, FR-08
 * SPEC: docs/features/06-content-validation.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import type { ContentItem } from "@/features/content/schemas";
import { ROUTES } from "@/lib/constants/routes";
import { ContentStatus } from "@/types/enums";
import { ContentFilters } from "./ContentFilters";
import { WorkflowStatusBadge } from "./WorkflowStatusBadge";
import { useRemoteItems } from "@/lib/hooks/useRemoteItems";
import { fetchContentList } from "@/features/content/queries";

interface ContentTableProps {
  initialItems: ContentItem[];
}

export function ContentTable({ initialItems: seedItems }: ContentTableProps) {
  const [initialItems] = useRemoteItems<ContentItem>(seedItems, fetchContentList);
  const [statusTab, setStatusTab] = useState<string>("ALL");
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("ALL");

  const tabs = [
    { key: "ALL", label: "All", count: initialItems.length },
    {
      key: ContentStatus.Draft,
      label: "Draft",
      count: initialItems.filter((i) => i.status === ContentStatus.Draft).length,
    },
    {
      key: ContentStatus.InReview,
      label: "In review",
      count: initialItems.filter((i) => i.status === ContentStatus.InReview).length,
    },
    {
      key: ContentStatus.Published,
      label: "Published",
      count: initialItems.filter((i) => i.status === ContentStatus.Published).length,
    },
    {
      key: ContentStatus.Archived,
      label: "Archived",
      count: initialItems.filter((i) => i.status === ContentStatus.Archived).length,
    },
  ];

  const filtered = initialItems.filter((item) => {
    if (statusTab !== "ALL" && item.status !== statusTab) return false;
    if (typeFilter !== "ALL" && item.type !== typeFilter) return false;
    if (search.trim()) {
      const q = search.toLowerCase();
      return (
        item.title.toLowerCase().includes(q) ||
        item.bibleLink.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <div className="flex flex-col gap-5">
      <div className="flex flex-wrap gap-2" role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            role="tab"
            aria-selected={statusTab === tab.key}
            onClick={() => setStatusTab(tab.key)}
            className={`rounded-md px-3 py-1.5 text-sm font-medium ${
              statusTab === tab.key
                ? "bg-primary text-foreground"
                : "text-muted-foreground hover:bg-surface"
            }`}
          >
            {tab.label} <span className="opacity-80">{tab.count}</span>
          </button>
        ))}
      </div>

      <section className="card flex flex-col gap-2">
      <ContentFilters
        search={search}
        onSearchChange={setSearch}
        typeFilter={typeFilter}
        onTypeChange={setTypeFilter}
      />

      <div className="overflow-x-auto">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface text-xs uppercase text-muted-foreground">
            <tr>
              <th className="px-4 py-3">Title</th>
              <th className="px-4 py-3">Type</th>
              <th className="px-4 py-3">Bible link</th>
              <th className="px-4 py-3">Author</th>
              <th className="px-4 py-3">Validator</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                  No content items match your filters.
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-surface/60">
                  <td className="text-base font-extrabold">{item.title}</td>
                  <td className="capitalize">{item.type.toString().toLowerCase()}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.bibleLink}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.authorName}</td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {item.validatorName || "—"}
                  </td>
                  <td className="px-4 py-3">
                    <WorkflowStatusBadge status={item.status} />
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Link
                      href={ROUTES.contentDetail(item.id)}
                      className="rounded-md border border-border px-2.5 py-1 text-xs font-medium hover:bg-surface"
                    >
                      Open
                    </Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      </section>
    </div>
  );
}
