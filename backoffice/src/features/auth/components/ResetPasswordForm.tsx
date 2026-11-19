/**
 * src/features/auth/components/ResetPasswordForm.tsx
 *
 * WHAT: Reset password form with live rules checklist and expired/used link handling
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import {
  resetPasswordSchema,
  type ResetPasswordInput,
} from "@/features/auth/schemas";
import { ROUTES } from "@/lib/constants/routes";
import { PasswordRules } from "./PasswordRules";

interface ResetPasswordFormProps {
  token: string;
}

export function ResetPasswordForm({ token }: ResetPasswordFormProps) {
  const [status, setStatus] = useState<"idle" | "success" | "expired" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const {
    register,
    watch,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<ResetPasswordInput>({
    resolver: zodResolver(resetPasswordSchema),
    defaultValues: {
      token,
      password: "",
      confirmPassword: "",
    },
  });

  const passwordValue = watch("password");

  async function onSubmit(values: ResetPasswordInput) {
    setErrorMessage(null);
    try {
      const res = await fetch("/api/proxy/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token: values.token,
          password: values.password,
        }),
      });

      if (res.status === 400 || res.status === 410) {
        setStatus("expired");
        return;
      }

      if (!res.ok) {
        setStatus("error");
        setErrorMessage("Could not reset password. Please try again.");
        return;
      }

      setStatus("success");
    } catch {
      setStatus("error");
      setErrorMessage("Network error. Please try again.");
    }
  }

  if (!token || status === "expired") {
    return (
      <div className="space-y-4">
        <div
          role="alert"
          className="rounded-md border border-primary bg-primary-soft px-4 py-3 text-sm text-ink"
        >
          This password reset link is invalid, has expired, or has already been used.
        </div>
        <Link
          href={ROUTES.forgotPassword}
          className="inline-block rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground"
        >
          Request a new reset link
        </Link>
      </div>
    );
  }

  if (status === "success") {
    return (
      <div className="space-y-4">
        <div
          role="status"
          className="rounded-md border border-blue/30 bg-blue-soft px-4 py-3 text-sm text-ink"
        >
          Your password has been updated. You can now sign in with your new password.
        </div>
        <Link
          href={ROUTES.login}
          className="inline-block rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground"
        >
          Go to sign in
        </Link>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
      <input type="hidden" {...register("token")} />

      {errorMessage && (
        <div
          role="alert"
          className="rounded-md border border-danger/40 bg-danger-soft px-3 py-2 text-sm text-danger"
        >
          {errorMessage}
        </div>
      )}

      <div className="space-y-1.5">
        <label htmlFor="password" className="block text-[13px] font-extrabold">
          New password
        </label>
        <input
          id="password"
          type="password"
          autoComplete="new-password"
          aria-invalid={Boolean(errors.password)}
          aria-describedby={errors.password ? "password-error" : undefined}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          {...register("password")}
        />
        {errors.password && (
          <p id="password-error" role="alert" className="text-xs text-danger">
            {errors.password.message}
          </p>
        )}
      </div>

      <PasswordRules password={passwordValue} />

      <div className="space-y-1.5">
        <label
          htmlFor="confirmPassword"
          className="block text-[13px] font-extrabold"
        >
          Confirm new password
        </label>
        <input
          id="confirmPassword"
          type="password"
          autoComplete="new-password"
          aria-invalid={Boolean(errors.confirmPassword)}
          aria-describedby={errors.confirmPassword ? "confirm-error" : undefined}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          {...register("confirmPassword")}
        />
        {errors.confirmPassword && (
          <p id="confirm-error" role="alert" className="text-xs text-danger">
            {errors.confirmPassword.message}
          </p>
        )}
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground transition hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Updating password..." : "Update password"}
      </button>
    </form>
  );
}
