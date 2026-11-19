/**
 * src/features/auth/components/LoginForm.tsx
 *
 * WHAT: Login form with validation and safe error messages (wrong credentials, suspended)
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

"use client";

import { useState } from "react";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Eye, EyeOff, ShieldCheck } from "lucide-react";
import { loginSchema, type LoginInput } from "@/features/auth/schemas";
import { resolvePostLoginRedirect } from "@/lib/auth/redirects";
import { ROUTES } from "@/lib/constants/routes";
import type { Role } from "@/types/enums";

interface LoginFormProps {
  returnTo?: string | null;
  initialError?: string | null;
}

export function LoginForm({ returnTo, initialError }: LoginFormProps) {
  const [showPassword, setShowPassword] = useState(false);
  const [serverError, setServerError] = useState<string | null>(
    initialError === "suspended"
      ? "Your staff account has been suspended. Contact a system administrator."
      : initialError === "expired"
        ? "Your session has ended. Please sign in again."
        : initialError === "unavailable"
          ? "The server is not responding right now. Please try again shortly."
          : null,
  );

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginInput>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: "",
      password: "",
      rememberMe: false,
    },
  });

  async function onSubmit(values: LoginInput) {
    setServerError(null);
    try {
      const res = await fetch("/api/proxy/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(values),
      });

      if (!res.ok) {
        const body = (await res.json().catch(() => ({}))) as {
          code?: string;
        };
        const code = body.code?.toLowerCase();
        if (res.status === 403 && code === "account_suspended") {
          setServerError(
            "Your staff account has been suspended. Contact a system administrator.",
          );
        } else if (res.status === 403 && code === "not_staff") {
          setServerError("This account does not have back-office access.");
        } else if (res.status === 429) {
          setServerError("Too many attempts. Please wait a few minutes and try again.");
        } else if (res.status >= 500) {
          setServerError("The server is not responding right now. Please try again shortly.");
        } else {
          setServerError("Invalid work email or password.");
        }
        return;
      }

      const data = (await res.json()) as { user?: { role?: Role } };
      const role = data.user?.role;
      const target = role ? resolvePostLoginRedirect(role, returnTo) : ROUTES.dashboard;
      // A full page load, not router.push: the client router may hold a "redirect to /login" it cached while the
      // person was signed out, and would replay it (the login -> dashboard -> login loop). A real navigation always
      // sends the fresh session cookie.
      window.location.assign(target);
    } catch {
      setServerError("Unable to sign in right now. Please try again.");
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
      {serverError && (
        <div
          role="alert"
          className="rounded-md border border-danger/40 bg-danger-soft px-3 py-2 text-sm text-danger"
        >
          {serverError}
        </div>
      )}

      <div className="space-y-1.5">
        <label htmlFor="email" className="block text-base font-extrabold text-foreground">
          Work email
        </label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          aria-invalid={Boolean(errors.email)}
          aria-describedby={errors.email ? "email-error" : undefined}
          className="w-full rounded-md border border-border bg-white px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          placeholder="name@example.com"
          {...register("email")}
        />
        {errors.email && (
          <p id="email-error" role="alert" className="text-xs text-danger">
            {errors.email.message}
          </p>
        )}
      </div>

      <div className="space-y-1.5">
        <label htmlFor="password" className="block text-base font-extrabold text-foreground">
          Password
        </label>
        <div className="relative">
          <input
            id="password"
            type={showPassword ? "text" : "password"}
            autoComplete="current-password"
            aria-invalid={Boolean(errors.password)}
            aria-describedby={errors.password ? "password-error" : undefined}
            className="w-full rounded-md border border-border bg-white px-3 py-2 pr-10 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
            placeholder="Your password"
          {...register("password")}
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? "Hide password" : "Show password"}
            className="absolute right-1.5 top-1 flex h-11 w-11 items-center justify-center text-ink"
          >
            {showPassword ? (
              <EyeOff className="h-[22px] w-[22px]" aria-hidden="true" />
            ) : (
              <Eye className="h-[22px] w-[22px]" aria-hidden="true" />
            )}
          </button>
        </div>
        {errors.password && (
          <p id="password-error" role="alert" className="text-xs text-danger">
            {errors.password.message}
          </p>
        )}
      </div>

      <div className="flex flex-wrap items-center justify-between gap-2.5">
        <label htmlFor="rememberMe" className="flex items-center gap-2.5 text-base font-semibold">
          <input id="rememberMe" type="checkbox" className="h-5 w-5 accent-ink" {...register("rememberMe")} />
          Keep me signed in
        </label>
        <Link href={ROUTES.forgotPassword} className="text-base font-extrabold text-blue underline">
          Forgot password?
        </Link>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="btn btn-primary btn-lg w-full"
      >
        {isSubmitting ? "Signing in..." : "Sign in"}
      </button>

      <div className="flex items-start gap-2.5 rounded-lg bg-[linear-gradient(135deg,#E8F2FD_0%,#CFE3F8_100%)] px-3.5 py-3 text-sm leading-[1.35]">
        <ShieldCheck className="h-[22px] w-[22px] shrink-0" aria-hidden="true" />
        <span>Sign-ins and access to personal data are recorded in the audit log.</span>
      </div>
    </form>
  );
}
