/**
 * src/features/pathways/components/AddStepDialog.tsx
 *
 * WHAT: Dialog to select published content items from library and add to pathway
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { Plus, Search, X } from "lucide-react";
import {
  fetchAvailableContent,
  type AvailableContentItem,
  type PathwayStep,
} from "../queries";

interface AddStepDialogProps {
  existingStepContentIds: string[];
  onAddStep: (step: PathwayStep) => void;
}

export function AddStepDialog({ existingStepContentIds, onAddStep }: AddStepDialogProps) {
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<AvailableContentItem[]>([]);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState<string>("all");

  useEffect(() => {
    if (open) {
      fetchAvailableContent().then(setItems);
    }
  }, [open]);

  const filtered = items.filter((item) => {
    const matchesSearch = item.title.toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === "all" || item.type === typeFilter;
    const notAdded = !existingStepContentIds.includes(item.id);
    return matchesSearch && matchesType && notAdded;
  });

  function handleSelect(item: AvailableContentItem) {
    const newStep: PathwayStep = {
      id: `step-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      contentId: item.id,
      title: item.title,
      contentType: item.type,
      order: existingStepContentIds.length,
      required: true,
    };
    onAddStep(newStep);
    setOpen(false);
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="inline-flex items-center gap-1.5 rounded-md border border-dashed border-border px-3 py-2 text-xs font-medium text-foreground hover:bg-blue-tint"
      >
        <Plus className="h-4 w-4" aria-hidden="true" />
        <span>Add step from content library</span>
      </button>

      {open && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Add content step to pathway"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
        >
          <div className="w-full max-w-lg space-y-4 rounded-xl border border-border bg-white p-5 shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-base font-semibold text-foreground">
                  Add step from content library
                </h3>
                <p className="text-xs text-muted">
                  Only published content items can be added to a discipleship pathway.
                </p>
              </div>
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded p-1 text-muted hover:text-foreground"
                aria-label="Close"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="grid gap-2 sm:grid-cols-2">
              <div className="relative">
                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted" />
                <input
                  type="search"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search published content…"
                  className="w-full rounded-md border border-border pl-8 pr-3 py-1.5 text-xs text-foreground"
                />
              </div>

              <select
                value={typeFilter}
                onChange={(e) => setTypeFilter(e.target.value)}
                className="rounded-md border border-border px-3 py-1.5 text-xs text-foreground"
              >
                <option value="all">All content types</option>
                <option value="devotional">Devotionals</option>
                <option value="video">Videos</option>
                <option value="document">Documents</option>
                <option value="quiz">Quizzes</option>
              </select>
            </div>

            <div className="max-h-60 overflow-y-auto divide-y divide-border rounded-lg border border-border">
              {filtered.length === 0 ? (
                <div className="p-4 text-center text-xs text-muted">
                  No matching published content available to add.
                </div>
              ) : (
                filtered.map((item) => (
                  <div
                    key={item.id}
                    className="flex items-center justify-between p-3 text-xs hover:bg-blue-tint"
                  >
                    <div>
                      <p className="font-medium text-foreground">{item.title}</p>
                      <p className="capitalize text-muted">{item.type}</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleSelect(item)}
                      className="rounded bg-primary px-2.5 py-1 text-xs font-medium text-white hover:opacity-90"
                    >
                      Add
                    </button>
                  </div>
                ))
              )}
            </div>

            <div className="flex justify-end pt-2">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="rounded-md border border-border px-3 py-1.5 text-xs font-medium text-foreground hover:bg-blue-tint"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
