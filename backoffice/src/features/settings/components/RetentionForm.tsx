/**
 * src/features/settings/components/RetentionForm.tsx
 *
 * WHAT: Data retention rules (inactive account retention months & deletion request deadline days)
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { fetchSettings, saveRetentionSettings } from "@/features/settings/queries";
import {
  retentionSchema,
  type RetentionSettings,
} from "@/features/settings/schemas";

export function RetentionForm() {
  const [saved, setSaved] = useState(false);

  const {
    register,
    handleSubmit,
    reset,
    formState: { isSubmitting },
  } = useForm<RetentionSettings>({
    resolver: zodResolver(retentionSchema),
    defaultValues: {
      inactiveRetentionMonths: 24,
      deletionDeadlineDays: 30,
    },
  });

  useEffect(() => {
    let active = true;
    fetchSettings<RetentionSettings>("retention").then((saved) => {
      if (active && saved) reset(saved);
    });
    return () => {
      active = false;
    };
  }, [reset]);

  async function onSubmit(values: RetentionSettings) {
    setSaved(false);
    await saveRetentionSettings(values);
    setSaved(true);
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {saved && (
        <p role="status" className="text-xs font-medium text-emerald-800">
          Retention settings saved.
        </p>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="retention-months" className="block text-sm font-medium">
            Keep inactive accounts (months)
          </label>
          <input
            id="retention-months"
            type="number"
            min={1}
            max={120}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("inactiveRetentionMonths", { valueAsNumber: true })}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="deletion-days" className="block text-sm font-medium">
            Answer deletion requests within (days)
          </label>
          <input
            id="deletion-days"
            type="number"
            min={1}
            max={90}
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("deletionDeadlineDays", { valueAsNumber: true })}
          />
        </div>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Saving..." : "Save retention rules"}
      </button>
    </form>
  );
}
