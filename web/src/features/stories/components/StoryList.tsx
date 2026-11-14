/**
 * src/features/stories/components/StoryList.tsx
 *
 * WHAT: Reorderable list of landing story videos with visibility toggles
 * REQUIREMENTS: -
 * SPEC: docs/features/09-announcements-stories.md
 * STATUS: implemented
 */

"use client";

import { ArrowDown, ArrowUp, CheckCircle, Eye, EyeOff, Video } from "lucide-react";
import type { LandingStory } from "../queries";

interface StoryListProps {
  stories: LandingStory[];
  onChange: (stories: LandingStory[]) => void;
}

export function StoryList({ stories, onChange }: StoryListProps) {
  function handleMoveUp(index: number) {
    if (index === 0) return;
    const copy = [...stories];
    const temp = copy[index - 1];
    copy[index - 1] = copy[index];
    copy[index] = temp;
    copy.forEach((s, idx) => {
      s.order = idx;
    });
    onChange(copy);
  }

  function handleMoveDown(index: number) {
    if (index === stories.length - 1) return;
    const copy = [...stories];
    const temp = copy[index + 1];
    copy[index + 1] = copy[index];
    copy[index] = temp;
    copy.forEach((s, idx) => {
      s.order = idx;
    });
    onChange(copy);
  }

  function handleToggleVisible(index: number) {
    const copy = stories.map((s, idx) =>
      idx === index ? { ...s, visible: !s.visible } : s,
    );
    onChange(copy);
  }

  if (stories.length === 0) {
    return (
      <div className="rounded-xl border border-border bg-white p-8 text-center text-sm text-muted">
        No student stories added yet. Click &quot;Add story video&quot; to highlight student voices on the app landing page.
      </div>
    );
  }

  return (
    <div className="space-y-2">
      {stories.map((story, index) => (
        <div
          key={story.id}
          className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-border bg-white p-3.5 shadow-sm hover:border-slate-300"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary-soft text-primary">
              <Video className="h-5 w-5" />
            </div>
            <div>
              <p className="font-semibold text-foreground text-sm">{story.studentName}</p>
              <p className="text-xs text-muted">
                {story.institution} · {story.duration}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4 text-xs">
            <span className="inline-flex items-center gap-1 text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded text-[11px] font-medium">
              <CheckCircle className="h-3 w-3" />
              <span>Consent verified</span>
            </span>

            <button
              type="button"
              onClick={() => handleToggleVisible(index)}
              className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium transition ${
                story.visible
                  ? "bg-emerald-100 text-emerald-800"
                  : "bg-slate-100 text-muted"
              }`}
            >
              {story.visible ? <Eye className="h-3.5 w-3.5" /> : <EyeOff className="h-3.5 w-3.5" />}
              <span>{story.visible ? "Visible on landing" : "Hidden"}</span>
            </button>

            <div className="flex items-center border-l border-border pl-2 gap-1">
              <button
                type="button"
                onClick={() => handleMoveUp(index)}
                disabled={index === 0}
                aria-label="Move story up"
                className="rounded p-1 text-muted hover:bg-slate-100 hover:text-foreground disabled:opacity-30"
              >
                <ArrowUp className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => handleMoveDown(index)}
                disabled={index === stories.length - 1}
                aria-label="Move story down"
                className="rounded p-1 text-muted hover:bg-slate-100 hover:text-foreground disabled:opacity-30"
              >
                <ArrowDown className="h-4 w-4" />
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
