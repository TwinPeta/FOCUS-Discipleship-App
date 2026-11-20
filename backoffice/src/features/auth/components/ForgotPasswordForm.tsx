/**
 * src/features/auth/components/ForgotPasswordForm.tsx
 *
 * WHAT: Forgot password form with generic confirmation message (no account enumeration)
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
  forgotPasswordSchema,
  type ForgotPasswordInput,
} from "@/features/auth/schemas";
import { ROUTES } from "@/lib/constants/routes";

export function ForgotPasswordForm() {
  const [submitted, setSubmitted] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<ForgotPasswordInput>({
    resolver: zodResolver(forgotPasswordSchema),
    defaultValues: { email: "" },
  });

  async function onSubmit(values: ForgotPasswordInput) {
    try {
      await fetch("/api/proxy/auth/forgot-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(values),
      });
    } finally {
      // Always show a generic confirmation to avoid account enumeration
      setSubmitted(true);
    }
  }

  if (submitted) {
    return (
      <div className="space-y-4">
        <div
          role="status"
          className="rounded-md border border-border bg-primary-soft px-4 py-3 text-sm text-foreground"
        >
          If a staff account exists for that email address, we have sent a password
          reset link. The link expires after 1 hour.
        </div>
        <Link
          href={ROUTES.login}
          className="inline-block text-sm font-medium text-foreground underline underline-offset-2"
        >
          Back to sign in
        </Link>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
      <div className="space-y-1.5">
        <label htmlFor="email" className="block text-[13px] font-extrabold">
          Work email
        </label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          aria-invalid={Boolean(errors.email)}
          aria-describedby={errors.email ? "email-error" : undefined}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          placeholder="name@focusuganda.org"
          {...register("email")}
        />
        {errors.email && (
          <p id="email-error" role="alert" className="text-xs text-danger">
            {errors.email.message}
          </p>
        )}
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded-md bg-primary px-4 py-2 text-sm font-semibold text-foreground transition hover:brightness-95 disabled:opacity-60"
      >
        {isSubmitting ? "Sending link..." : "Send reset link"}
      </button>

      <div className="text-center">
        <Link
          href={ROUTES.login}
          className="text-sm font-medium text-foreground underline underline-offset-2"
        >
          Back to sign in
        </Link>
      </div>
    </form>
  );
}
