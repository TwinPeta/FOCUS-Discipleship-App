/**
 * src/features/settings/components/CharterForm.tsx
 *
 * WHAT: Community charter text, version, effective date, and re-acceptance toggles
 * REQUIREMENTS: FR-10
 * SPEC: docs/features/14-settings-charter.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { saveCharterSettings } from "@/features/settings/queries";
import { charterSchema, type CharterSettings } from "@/features/settings/schemas";

export function CharterForm() {
  const [saved, setSaved] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CharterSettings>({
    resolver: zodResolver(charterSchema),
    defaultValues: {
      version: "1.0",
      effectiveDate: "2026-01-01",
      text: "We commit to honouring Christ, supporting one another in humility, and keeping our communities safe and welcoming.",
      requireAcceptance: true,
      repromptOnChange: true,
    },
  });

  async function onSubmit(values: CharterSettings) {
    setSaved(false);
    await saveCharterSettings(values);
    setSaved(true);
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      {saved && (
        <p role="status" className="text-xs font-medium text-emerald-800">
          Charter settings saved.
        </p>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="charter-version" className="block text-sm font-medium">
            Version
          </label>
          <input
            id="charter-version"
            type="text"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("version")}
          />
          {errors.version && (
            <p role="alert" className="text-xs text-red-700">
              {errors.version.message}
            </p>
          )}
        </div>

        <div className="space-y-1.5">
          <label htmlFor="charter-date" className="block text-sm font-medium">
            Effective date
          </label>
          <input
            id="charter-date"
            type="date"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("effectiveDate")}
          />
        </div>
      </div>

      <div className="space-y-1.5">
        <label htmlFor="charter-text" className="block text-sm font-medium">
          Charter text shown at sign-up
        </label>
        <textarea
          id="charter-text"
          rows={4}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("text")}
        />
        {errors.text && (
          <p role="alert" className="text-xs text-red-700">
            {errors.text.message}
          </p>
        )}
      </div>

      <div className="flex flex-wrap gap-6 text-sm">
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            className="h-4 w-4 accent-primary"
            {...register("requireAcceptance")}
          />
          <span>Require acceptance at sign-up</span>
        </label>
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            className="h-4 w-4 accent-primary"
            {...register("repromptOnChange")}
          />
          <span>Ask members to re-accept when version changes</span>
        </label>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Saving..." : "Save charter"}
      </button>
    </form>
  );
}
