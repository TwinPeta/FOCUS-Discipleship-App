/**
 * src/features/communities/components/CommunityForm.tsx
 *
 * WHAT: Community create/edit form composing meeting fields, team picker, and cover uploader
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  communitySchema,
  CommunityStatus,
  type Community,
  type CommunityInput,
} from "@/features/communities/schemas";
import { useSession } from "@/features/auth/hooks/useSession";
import { can } from "@/lib/permissions/can";
import { shouldHideCrossCommunityControls } from "@/lib/permissions/scope";
import { CommunityKind } from "@/types/enums";
import { CoverPhotoUploader } from "./CoverPhotoUploader";
import { MeetingFields } from "./MeetingFields";
import { TeamPicker, type StaffOption } from "./TeamPicker";
import { useLookups } from "@/lib/hooks/useLookups";

interface CommunityFormProps {
  initial?: Community | null;
  institutions?: { id: string; name: string }[];
  staffCandidates?: StaffOption[];
  onSubmit: (values: CommunityInput) => Promise<void>;
  onCancel?: () => void;
}

export function CommunityForm({
  initial,
  institutions: institutionsProp,
  staffCandidates: staffProp,
  onSubmit,
  onCancel,
}: CommunityFormProps) {
  const { user } = useSession();
  const lookups = useLookups({ institutions: true, staff: true });
  const institutions = institutionsProp ?? lookups.institutions;
  const staffCandidates = staffProp ?? lookups.staff;
  const [error, setError] = useState<string | null>(null);
  const canEditCover = can(user, "coverPhotos", "modify");
  const meetingOnly = shouldHideCrossCommunityControls(user);

  const {
    register,
    watch,
    setValue,
    getValues,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CommunityInput>({
    resolver: zodResolver(communitySchema),
    defaultValues: {
      institutionId: initial?.institutionId ?? institutions[0]?.id ?? "",
      kind: initial?.kind ?? CommunityKind.Specific,
      name: initial?.name ?? "",
      description: initial?.description ?? "",
      coverPhotoUrl: initial?.coverPhotoUrl ?? "",
      meetingDay: initial?.meetingDay ?? "",
      meetingTime: initial?.meetingTime ?? "",
      meetingPlace: initial?.meetingPlace ?? "",
      superMentorId: initial?.superMentorId ?? "",
      mentorIds: initial?.mentorIds ?? [],
      openForJoinRequests: initial?.openForJoinRequests ?? true,
      status: initial?.status ?? CommunityStatus.Active,
    },
  });

  // Dropdowns load after first render: preselect the first institution once it arrives (new communities only).
  useEffect(() => {
    if (!initial && institutions.length && !getValues("institutionId")) setValue("institutionId", institutions[0].id);
  }, [initial, institutions, getValues, setValue]);

  const superMentorId = watch("superMentorId");
  const mentorIds = watch("mentorIds");
  const coverPhotoUrl = watch("coverPhotoUrl");

  async function handleFormSubmit(values: CommunityInput) {
    setError(null);
    try {
      await onSubmit(values);
    } catch {
      setError("Could not save caregroup. Please try again.");
    }
  }

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} noValidate className="space-y-6">
      {error && (
        <div
          role="alert"
          className="rounded-md border border-danger/40 bg-danger-soft px-3 py-2 text-sm text-danger"
        >
          {error}
        </div>
      )}

      {!meetingOnly && (
        <>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <label htmlFor="institutionId" className="block text-[13px] font-extrabold">
                Campus
              </label>
              <select
                id="institutionId"
                className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
                {...register("institutionId")}
              >
                <option value="">Select campus</option>
                {institutions.map((inst) => (
                  <option key={inst.id} value={inst.id}>
                    {inst.name}
                  </option>
                ))}
              </select>
              {errors.institutionId && (
                <p role="alert" className="text-xs text-danger">
                  {errors.institutionId.message}
                </p>
              )}
            </div>

            <div className="space-y-1.5">
              <label htmlFor="kind" className="block text-[13px] font-extrabold">
                Caregroup type
              </label>
              <select
                id="kind"
                className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
                {...register("kind")}
              >
                <option value={CommunityKind.Specific}>Specific</option>
                <option value={CommunityKind.General}>General</option>
              </select>
            </div>
          </div>

          <div className="space-y-1.5">
            <label htmlFor="comm-name" className="block text-[13px] font-extrabold">
              Caregroup name
            </label>
            <input
              id="comm-name"
              type="text"
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
              {...register("name")}
            />
            {errors.name && (
              <p role="alert" className="text-xs text-danger">
                {errors.name.message}
              </p>
            )}
          </div>

          <div className="space-y-1.5">
            <label htmlFor="comm-desc" className="block text-[13px] font-extrabold">
              Description
            </label>
            <textarea
              id="comm-desc"
              rows={3}
              className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
              {...register("description")}
            />
          </div>

          {canEditCover && (
            <CoverPhotoUploader
              value={coverPhotoUrl}
              onChange={(url) => setValue("coverPhotoUrl", url, { shouldDirty: true })}
            />
          )}
        </>
      )}

      <MeetingFields register={register} />

      {!meetingOnly && (
        <>
          <TeamPicker
            superMentorId={superMentorId}
            mentorIds={mentorIds}
            candidates={staffCandidates}
            onSuperMentorChange={(id) => setValue("superMentorId", id)}
            onMentorIdsChange={(ids) => setValue("mentorIds", ids)}
          />

          <div className="flex flex-wrap items-center gap-6">
            <label className="flex items-center gap-2 text-sm text-foreground">
              <input
                type="checkbox"
                className="h-4 w-4 rounded border-border accent-primary"
                {...register("openForJoinRequests")}
              />
              Open for new members
            </label>

            <div className="flex items-center gap-2">
              <label htmlFor="comm-status" className="text-sm font-medium text-foreground">
                Status
              </label>
              <select
                id="comm-status"
                className="rounded-md border border-border bg-white px-3 py-1.5 text-sm"
                {...register("status")}
              >
                <option value={CommunityStatus.Active}>Active</option>
                <option value={CommunityStatus.Closed}>Closed</option>
              </select>
            </div>
          </div>
        </>
      )}

      <div className="flex items-center gap-3 pt-2">
        <button
          type="submit"
          disabled={isSubmitting}
          className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
        >
          {isSubmitting ? "Saving..." : initial ? "Save changes" : "Create caregroup"}
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
