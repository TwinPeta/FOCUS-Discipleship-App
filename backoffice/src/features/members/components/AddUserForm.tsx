/**
 * src/features/members/components/AddUserForm.tsx
 *
 * WHAT: Add user form with role, institution, minor guardian consent check, and invitation toggle
 * REQUIREMENTS: FR-07, FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState, type ReactNode } from "react";
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
  /** Lets the page show help for the role being chosen */
  onRoleChange?: (role: Role) => void;
}

export function AddUserForm({
  institutions: institutionsProp,
  communities: communitiesProp,
  onSuccess,
  onRoleChange,
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
      country: "Uganda",
      yearOfStudy: "",
      localChurch: "",
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

  useEffect(() => {
    onRoleChange?.(role);
  }, [role, onRoleChange]);

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
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="flex flex-col gap-4">
      {error && (
        <div role="alert" className="rounded-lg bg-danger-soft px-3.5 py-2.5 text-sm font-semibold text-danger">
          {error}
        </div>
      )}

      <div className="flex flex-col gap-2">
        <h2 className="text-lg font-black">Role</h2>
        <RoleSelector variant="chips" id="add-role" value={role} onChange={(next) => setValue("role", next)} />
      </div>

      <h2 className="mt-1 text-lg font-black">Profile</h2>

      <div className="grid gap-4 sm:grid-cols-2">
        <Field id="add-fullName" label="Full name" error={errors.fullName?.message}>
          <input id="add-fullName" type="text" placeholder="[Full name]" className="w-full px-3.5" {...register("fullName")} />
        </Field>
        <Field id="add-email" label="Email" error={errors.email?.message}>
          <input id="add-email" type="email" placeholder="name@example.com" className="w-full px-3.5" {...register("email")} />
        </Field>
        <Field id="add-phone" label="Phone number">
          <input id="add-phone" type="tel" placeholder="+256 700 000 000" className="w-full px-3.5" {...register("phone")} />
        </Field>
        <Field id="add-birthdate" label="Birthdate">
          <input id="add-birthdate" type="date" className="w-full px-3.5" {...register("birthdate")} />
        </Field>
      </div>

      <Field id="add-country" label="Country">
        <select id="add-country" className="w-full px-3.5" {...register("country")}>
          {["Uganda", "Kenya", "Rwanda"].map((c) => (
            <option key={c} value={c}>
              {c}
            </option>
          ))}
        </select>
      </Field>

      {isMinor && (
        <div className="flex flex-col gap-2 rounded-xl bg-[#FFF8E6] p-3.5 text-sm">
          <p className="font-extrabold">
            This user is under 18. Guardian consent is required before the account is fully active.
          </p>
          <label className="flex items-center gap-2.5 font-semibold">
            <input type="checkbox" {...register("guardianConsentReceived")} />
            <span>Guardian consent already received</span>
          </label>
        </div>
      )}

      <Field id="add-institution" label="Campus" error={errors.institutionId?.message}>
        <select id="add-institution" className="w-full px-3.5" {...register("institutionId")}>
          <option value="">Select a campus</option>
          {institutions.map((i) => (
            <option key={i.id} value={i.id}>
              {i.name}
            </option>
          ))}
        </select>
      </Field>

      <Field id="add-year" label="Year / class">
        <select id="add-year" className="w-full px-3.5" {...register("yearOfStudy")}>
          <option value="">Select a year</option>
          {[1, 2, 3, 4, 5, 6, 7].map((y) => (
            <option key={y} value={String(y)}>
              Year {y}
            </option>
          ))}
        </select>
      </Field>

      <Field id="add-church" label="Local church (optional)">
        <input id="add-church" type="text" placeholder="[Church name]" className="w-full px-3.5" {...register("localChurch")} />
      </Field>

      <Field id="add-community" label="Specific caregroup (optional)">
        <select id="add-community" className="w-full px-3.5" {...register("communityId")}>
          <option value="">General caregroup only</option>
          {communities.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </Field>

      <label className="flex items-center gap-2.5 text-base font-semibold">
        <input type="checkbox" {...register("sendInvitation")} />
        <span>Send an invitation email so the user can set their password</span>
      </label>

      <div className="flex flex-wrap gap-2.5">
        <button type="submit" disabled={isSubmitting} className="btn btn-primary">
          {isSubmitting ? "Creating user..." : "Create user"}
        </button>
      </div>
    </form>
  );
}

function Field({
  id,
  label,
  error,
  children,
}: {
  id: string;
  label: string;
  error?: string;
  children: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-[13px] font-extrabold">
        {label}
      </label>
      {children}
      {error && (
        <p role="alert" className="text-xs font-semibold text-danger">
          {error}
        </p>
      )}
    </div>
  );
}
