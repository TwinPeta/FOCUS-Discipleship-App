/**
 * src/features/members/components/AddUserForm.tsx
 *
 * WHAT: Add user form with role, institution, minor guardian consent check, and invitation toggle
 * REQUIREMENTS: FR-07, FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { createMember } from "@/features/members/queries";
import {
  addUserSchema,
  isMinorBirthdate,
  type AddUserInput,
} from "@/features/members/schemas";
import { Role } from "@/types/enums";
import { RoleSelector } from "./RoleSelector";
import { useLookups } from "@/lib/hooks/useLookups";

interface AddUserFormProps {
  institutions?: { id: string; name: string }[];
  communities?: { id: string; name: string }[];
  onSuccess?: () => void;
}

export function AddUserForm({
  institutions: institutionsProp,
  communities: communitiesProp,
  onSuccess,
}: AddUserFormProps) {
  const lookups = useLookups({ institutions: true, communities: true });
  const institutions = institutionsProp ?? lookups.institutions;
  const communities = communitiesProp ?? lookups.communities;
  const [error, setError] = useState<string | null>(null);

  const {
    register,
    watch,
    setValue,
    getValues,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<AddUserInput>({
    resolver: zodResolver(addUserSchema),
    defaultValues: {
      fullName: "",
      email: "",
      phone: "",
      birthdate: "",
      role: Role.Student,
      institutionId: institutions[0]?.id ?? "",
      communityId: "",
      guardianConsentReceived: false,
      sendInvitation: true,
    },
  });

  // Dropdowns load after first render: preselect the first institution once it arrives.
  useEffect(() => {
    if (institutions.length && !getValues("institutionId")) setValue("institutionId", institutions[0].id);
  }, [institutions, getValues, setValue]);

  const birthdate = watch("birthdate");
  const role = watch("role");
  const isMinor = isMinorBirthdate(birthdate);

  async function onSubmit(values: AddUserInput) {
    setError(null);
    try {
      await createMember(values);
      onSuccess?.();
    } catch {
      setError("Could not create user. Please check the details and try again.");
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
      {error && (
        <div
          role="alert"
          className="rounded-md border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-800"
        >
          {error}
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="add-fullName" className="block text-sm font-medium text-foreground">
            Full name
          </label>
          <input
            id="add-fullName"
            type="text"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("fullName")}
          />
          {errors.fullName && (
            <p role="alert" className="text-xs text-red-700">
              {errors.fullName.message}
            </p>
          )}
        </div>

        <div className="space-y-1.5">
          <label htmlFor="add-email" className="block text-sm font-medium text-foreground">
            Email
          </label>
          <input
            id="add-email"
            type="email"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("email")}
          />
          {errors.email && (
            <p role="alert" className="text-xs text-red-700">
              {errors.email.message}
            </p>
          )}
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-1.5">
          <label htmlFor="add-phone" className="block text-sm font-medium text-foreground">
            Phone (optional)
          </label>
          <input
            id="add-phone"
            type="tel"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("phone")}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="add-birthdate" className="block text-sm font-medium text-foreground">
            Birthdate
          </label>
          <input
            id="add-birthdate"
            type="date"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("birthdate")}
          />
        </div>
      </div>

      {isMinor && (
        <div className="space-y-2 rounded-md border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900">
          <p className="font-medium">
            This user is under 18. Guardian consent is required before the account
            is fully active.
          </p>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              className="h-4 w-4 rounded border-border accent-primary"
              {...register("guardianConsentReceived")}
            />
            <span>Guardian consent already received</span>
          </label>
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-3">
        <div className="space-y-1.5">
          <label htmlFor="add-role" className="block text-sm font-medium text-foreground">
            Role
          </label>
          <RoleSelector
            id="add-role"
            value={role}
            onChange={(next) => setValue("role", next)}
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="add-institution" className="block text-sm font-medium text-foreground">
            Institution
          </label>
          <select
            id="add-institution"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("institutionId")}
          >
            <option value="">Select institution</option>
            {institutions.map((i) => (
              <option key={i.id} value={i.id}>
                {i.name}
              </option>
            ))}
          </select>
          {errors.institutionId && (
            <p role="alert" className="text-xs text-red-700">
              {errors.institutionId.message}
            </p>
          )}
        </div>

        <div className="space-y-1.5">
          <label htmlFor="add-community" className="block text-sm font-medium text-foreground">
            Community (optional)
          </label>
          <select
            id="add-community"
            className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm"
            {...register("communityId")}
          >
            <option value="">General community only</option>
            {communities.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <label className="flex items-center gap-2 text-sm text-foreground">
        <input
          type="checkbox"
          className="h-4 w-4 rounded border-border accent-primary"
          {...register("sendInvitation")}
        />
        <span>Send invitation email so the user can set their password</span>
      </label>

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Creating user..." : "Create user"}
      </button>
    </form>
  );
}
