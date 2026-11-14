/**
 * src/features/account/components/ProfileForm.tsx
 *
 * WHAT: Edit own name and photo; email and role are read-only
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { updateProfile } from "@/features/account/queries";
import { useSession } from "@/features/auth/hooks/useSession";
import { ROLE_LABELS } from "@/lib/permissions/roles";

const profileSchema = z.object({
  fullName: z.string().trim().min(2, "Full name must be at least 2 characters"),
  avatarUrl: z.string().trim().optional().or(z.literal("")),
});

type ProfileValues = z.infer<typeof profileSchema>;

export function ProfileForm() {
  const { user, updateUser } = useSession();
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<ProfileValues>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      fullName: user?.fullName ?? "",
      avatarUrl: user?.avatarUrl ?? "",
    },
  });

  async function onSubmit(values: ProfileValues) {
    setSaved(false);
    setError(null);
    try {
      const patch = { fullName: values.fullName, avatarUrl: values.avatarUrl || null };
      await updateProfile(patch);
      updateUser(patch);
      setSaved(true);
    } catch {
      setError("Could not update your profile. Please try again.");
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
      {saved && (
        <div
          role="status"
          className="rounded-md border border-emerald-300 bg-emerald-50 px-3 py-2 text-sm text-emerald-900"
        >
          Profile updated.
        </div>
      )}
      {error && (
        <div
          role="alert"
          className="rounded-md border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800"
        >
          {error}
        </div>
      )}

      <div className="space-y-1.5">
        <label htmlFor="fullName" className="block text-sm font-medium text-foreground">
          Full name
        </label>
        <input
          id="fullName"
          type="text"
          aria-invalid={Boolean(errors.fullName)}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          {...register("fullName")}
        />
        {errors.fullName && (
          <p role="alert" className="text-xs text-red-700">
            {errors.fullName.message}
          </p>
        )}
      </div>

      <div className="space-y-1.5">
        <label htmlFor="avatarUrl" className="block text-sm font-medium text-foreground">
          Photo URL
        </label>
        <input
          id="avatarUrl"
          type="url"
          placeholder="https://..."
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          {...register("avatarUrl")}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="email-readonly" className="block text-sm font-medium text-muted-foreground">
            Work email
          </label>
          <input
            id="email-readonly"
            type="email"
            value={user?.email ?? ""}
            readOnly
            disabled
            className="w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-muted-foreground"
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="role-readonly" className="block text-sm font-medium text-muted-foreground">
            Role
          </label>
          <input
            id="role-readonly"
            type="text"
            value={user?.role ? ROLE_LABELS[user.role] : ""}
            readOnly
            disabled
            className="w-full rounded-md border border-border bg-surface px-3 py-2 text-sm text-muted-foreground"
          />
        </div>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground transition hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Saving..." : "Save changes"}
      </button>
    </form>
  );
}
