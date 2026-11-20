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
import { InitialsAvatar } from "@/components/common/InitialsAvatar";
import { uploadFile } from "@/lib/upload";
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
  const [uploading, setUploading] = useState(false);

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<ProfileValues>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      fullName: user?.fullName ?? "",
      avatarUrl: user?.avatarUrl ?? "",
    },
  });

  const avatarUrl = watch("avatarUrl");

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

  async function onPhoto(file: File | undefined) {
    if (!file) return;
    setError(null);
    setUploading(true);
    try {
      setValue("avatarUrl", await uploadFile(file, "avatar"), { shouldDirty: true });
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not upload the photo.");
    } finally {
      setUploading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
      {saved && (
        <div role="status" className="notice">
          <span>Profile updated.</span>
        </div>
      )}
      {error && (
        <div role="alert" className="rounded-lg bg-danger-soft px-3.5 py-2.5 text-sm font-semibold text-danger">
          {error}
        </div>
      )}

      <div className="flex items-center gap-4">
        <InitialsAvatar name={user?.fullName ?? ""} avatarUrl={avatarUrl || null} size="xl" />
        <div className="flex flex-col items-start gap-1">
          <label htmlFor="avatar-file" className="btn btn-secondary btn-sm cursor-pointer">
            {uploading ? "Uploading…" : "Change photo"}
          </label>
          <input
            id="avatar-file"
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="sr-only"
            onChange={(e) => onPhoto(e.target.files?.[0])}
          />
          <p className="text-xs opacity-80">JPG, PNG or WebP, up to 2 MB.</p>
        </div>
      </div>
      <input type="hidden" {...register("avatarUrl")} />

      <div className="flex flex-col gap-1.5">
        <label htmlFor="fullName" className="text-[13px] font-extrabold">
          Full name
        </label>
        <input id="fullName" type="text" aria-invalid={Boolean(errors.fullName)} className="w-full px-3.5" {...register("fullName")} />
        {errors.fullName && (
          <p role="alert" className="text-xs font-semibold text-danger">
            {errors.fullName.message}
          </p>
        )}
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <label htmlFor="email-readonly" className="text-[13px] font-extrabold">
            Email
          </label>
          <input id="email-readonly" type="email" value={user?.email ?? ""} readOnly disabled className="w-full px-3.5" />
        </div>
        <div className="flex flex-col gap-1.5">
          <label htmlFor="role-readonly" className="text-[13px] font-extrabold">
            Role
          </label>
          <input id="role-readonly" type="text" value={user?.role ? ROLE_LABELS[user.role] : ""} readOnly disabled className="w-full px-3.5" />
        </div>
      </div>

      <div className="flex flex-wrap gap-2.5">
        <button type="submit" disabled={isSubmitting || uploading} className="btn btn-primary">
          {isSubmitting ? "Saving..." : "Save changes"}
        </button>
      </div>
    </form>
  );
}
