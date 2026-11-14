/**
 * src/app/(auth)/forgot-password/page.tsx
 *
 * WHAT: B27 Forgot password: work email, send reset link, back to sign in
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { ForgotPasswordForm } from "@/features/auth/components/ForgotPasswordForm";

export default function ForgotPasswordPage() {
  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-foreground">Forgot password</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Enter your work email and we will send you a single-use reset link.
        </p>
      </div>

      <ForgotPasswordForm />
    </div>
  );
}
