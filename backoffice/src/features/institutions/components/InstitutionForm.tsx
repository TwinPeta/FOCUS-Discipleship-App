/**
 * src/features/institutions/components/InstitutionForm.tsx
 *
 * WHAT: Create and edit institution form (type, country, city, general cover, sign-up visibility)
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  institutionSchema,
  InstitutionType,
  type Institution,
  type InstitutionInput,
} from "@/features/institutions/schemas";

interface InstitutionFormProps {
  initial?: Institution | null;
  onSubmit: (values: InstitutionInput) => Promise<void>;
  onCancel?: () => void;
}

export function InstitutionForm({
  initial,
  onSubmit,
  onCancel,
}: InstitutionFormProps) {
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<InstitutionInput>({
    resolver: zodResolver(institutionSchema),
    defaultValues: {
      name: initial?.name ?? "",
      type: initial?.type ?? InstitutionType.University,
      country: initial?.country ?? "Uganda",
      city: initial?.city ?? "",
      generalCoverUrl: initial?.generalCoverUrl ?? "",
      shownInSignup: initial?.shownInSignup ?? true,
    },
  });

  async function handleFormSubmit(values: InstitutionInput) {
    setError(null);
    try {
      await onSubmit(values);
    } catch {
      setError("Could not save institution. Please try again.");
    }
  }

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} noValidate className="space-y-4">
      {error && (
        <div
          role="alert"
          className="rounded-md border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800"
        >
          {error}
        </div>
      )}

      <div className="space-y-1.5">
        <label htmlFor="inst-name" className="block text-sm font-medium text-foreground">
          Institution name
        </label>
        <input
          id="inst-name"
          type="text"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("name")}
        />
        {errors.name && (
          <p role="alert" className="text-xs text-red-700">
            {errors.name.message}
          </p>
        )}
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="inst-type" className="block text-sm font-medium text-foreground">
            Type
          </label>
          <select
            id="inst-type"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("type")}
          >
            <option value={InstitutionType.University}>University</option>
            <option value={InstitutionType.Institute}>Institute</option>
            <option value={InstitutionType.HighSchool}>High school</option>
          </select>
        </div>

        <div className="space-y-1.5">
          <label htmlFor="inst-country" className="block text-sm font-medium text-foreground">
            Country
          </label>
          <input
            id="inst-country"
            type="text"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("country")}
          />
          {errors.country && (
            <p role="alert" className="text-xs text-red-700">
              {errors.country.message}
            </p>
          )}
        </div>
      </div>

      <div className="space-y-1.5">
        <label htmlFor="inst-city" className="block text-sm font-medium text-foreground">
          City
        </label>
        <input
          id="inst-city"
          type="text"
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("city")}
        />
        {errors.city && (
          <p role="alert" className="text-xs text-red-700">
            {errors.city.message}
          </p>
        )}
      </div>

      <div className="space-y-1.5">
        <label htmlFor="inst-cover" className="block text-sm font-medium text-foreground">
          General community cover URL
        </label>
        <input
          id="inst-cover"
          type="url"
          placeholder="https://..."
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
          {...register("generalCoverUrl")}
        />
      </div>

      <div className="flex items-center gap-2">
        <input
          id="inst-signup"
          type="checkbox"
          className="h-4 w-4 rounded border-border accent-primary"
          {...register("shownInSignup")}
        />
        <label htmlFor="inst-signup" className="text-sm text-foreground">
          Show in student sign-up list
        </label>
      </div>

      <div className="flex items-center gap-3 pt-2">
        <button
          type="submit"
          disabled={isSubmitting}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          {isSubmitting ? "Saving..." : initial ? "Save changes" : "Create institution"}
        </button>
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            className="rounded-md border border-border px-4 py-2 text-sm font-medium text-foreground hover:bg-surface"
          >
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}
