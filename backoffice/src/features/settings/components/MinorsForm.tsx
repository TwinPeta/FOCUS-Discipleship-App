/**
 * src/features/settings/components/MinorsForm.tsx
 *
 * WHAT: Minors safeguarding rules (age threshold, guardian consent, DM limits, verified mentors)
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { saveMinorsSettings } from "@/features/settings/queries";
import { minorsSchema, type MinorsSettings } from "@/features/settings/schemas";

export function MinorsForm() {
  const [saved, setSaved] = useState(false);

  const {
    register,
    watch,
    handleSubmit,
    formState: { isSubmitting },
  } = useForm<MinorsSettings>({
    resolver: zodResolver(minorsSchema),
    defaultValues: {
      ageThreshold: 18,
      requireGuardianConsent: true,
      limitAdultDirectMessages: true,
      requireVerifiedMentors: true,
    },
  });

  const threshold = watch("ageThreshold");

  async function onSubmit(values: MinorsSettings) {
    setSaved(false);
    await saveMinorsSettings(values);
    setSaved(true);
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {saved && (
        <p role="status" className="text-xs font-medium text-emerald-800">
          Minors safeguarding rules saved.
        </p>
      )}

      <div className="space-y-1.5 max-w-xs">
        <label htmlFor="minors-age" className="block text-sm font-medium">
          Minor age threshold (years)
        </label>
        <input
          id="minors-age"
          type="number"
          min={13}
          max={21}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("ageThreshold", { valueAsNumber: true })}
        />
      </div>

      {threshold !== 18 && (
        <div
          role="alert"
          className="rounded-md border border-amber-300 bg-amber-50 px-3 py-2 text-xs text-amber-900"
        >
          Changing the age threshold affects existing user accounts and guardian
          consent requirements.
        </div>
      )}

      <div className="space-y-2 text-sm">
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            className="h-4 w-4 accent-primary"
            {...register("requireGuardianConsent")}
          />
          <span>Require guardian consent for users under {threshold}</span>
        </label>
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            className="h-4 w-4 accent-primary"
            {...register("limitAdultDirectMessages")}
          />
          <span>Limit direct messages between minors and unverified adults</span>
        </label>
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            className="h-4 w-4 accent-primary"
            {...register("requireVerifiedMentors")}
          />
          <span>Mentors must be verified before contacting a student</span>
        </label>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Saving..." : "Save safeguarding rules"}
      </button>
    </form>
  );
}
