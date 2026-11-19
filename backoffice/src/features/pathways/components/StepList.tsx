/**
 * src/features/pathways/components/StepList.tsx
 *
 * WHAT: Reorderable list of pathway steps with required flags and delete action
 * REQUIREMENTS: FR-15,FR-20
 * SPEC: docs/features/08-pathways-badges.md
 * STATUS: implemented
 */

"use client";

import { ArrowDown, ArrowUp, GripVertical, Trash2 } from "lucide-react";
import type { PathwayStep } from "../queries";

interface StepListProps {
  steps: PathwayStep[];
  onChange: (steps: PathwayStep[]) => void;
}

export function StepList({ steps, onChange }: StepListProps) {
  function handleMoveUp(index: number) {
    if (index === 0) return;
    const newSteps = [...steps];
    const temp = newSteps[index - 1];
    newSteps[index - 1] = newSteps[index];
    newSteps[index] = temp;
    // update order numbers
    newSteps.forEach((s, idx) => {
      s.order = idx;
    });
    onChange(newSteps);
  }

  function handleMoveDown(index: number) {
    if (index === steps.length - 1) return;
    const newSteps = [...steps];
    const temp = newSteps[index + 1];
    newSteps[index + 1] = newSteps[index];
    newSteps[index] = temp;
    // update order numbers
    newSteps.forEach((s, idx) => {
      s.order = idx;
    });
    onChange(newSteps);
  }

  function handleToggleRequired(index: number) {
    const newSteps = steps.map((step, idx) =>
      idx === index ? { ...step, required: !step.required } : step,
    );
    onChange(newSteps);
  }

  function handleRemove(index: number) {
    const newSteps = steps
      .filter((_, idx) => idx !== index)
      .map((step, idx) => ({ ...step, order: idx }));
    onChange(newSteps);
  }

  if (steps.length === 0) {
    return (
      <div className="rounded-lg border border-dashed border-border p-6 text-center text-xs text-muted">
        No steps added to this pathway yet. Add steps from the published content library above.
      </div>
    );
  }

  return (
    <div className="space-y-2" data-testid="step-list">
      {steps.map((step, index) => (
        <div
          key={step.id}
          data-testid={`step-item-${index}`}
          className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-border bg-white p-3 text-xs shadow-sm transition hover:border-border"
        >
          <div className="flex items-center gap-2.5">
            <span className="flex h-5 w-5 items-center justify-center rounded-full bg-blue-tint font-semibold text-muted">
              {index + 1}
            </span>
            <GripVertical className="h-4 w-4 text-muted/60" aria-hidden="true" />
            <div>
              <p className="font-medium text-foreground">{step.title}</p>
              <span className="capitalize text-muted">{step.contentType}</span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <label className="flex items-center gap-1.5 font-medium text-foreground cursor-pointer">
              <input
                type="checkbox"
                checked={step.required}
                onChange={() => handleToggleRequired(index)}
                aria-label={`Required flag for ${step.title}`}
                className="h-3.5 w-3.5 rounded border-border text-primary focus:ring-primary"
              />
              <span>Required</span>
            </label>

            <div className="flex items-center border-l border-border pl-2 gap-1">
              <button
                type="button"
                onClick={() => handleMoveUp(index)}
                disabled={index === 0}
                aria-label="Move step up"
                className="rounded p-1 text-muted hover:bg-blue-tint hover:text-foreground disabled:opacity-30 disabled:hover:bg-transparent"
              >
                <ArrowUp className="h-3.5 w-3.5" />
              </button>
              <button
                type="button"
                onClick={() => handleMoveDown(index)}
                disabled={index === steps.length - 1}
                aria-label="Move step down"
                className="rounded p-1 text-muted hover:bg-blue-tint hover:text-foreground disabled:opacity-30 disabled:hover:bg-transparent"
              >
                <ArrowDown className="h-3.5 w-3.5" />
              </button>
              <button
                type="button"
                onClick={() => handleRemove(index)}
                aria-label={`Remove step ${step.title}`}
                className="rounded p-1 text-rose-500 hover:bg-danger-soft hover:text-danger ml-1"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
