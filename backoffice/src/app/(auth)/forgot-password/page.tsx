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
    <>
      <div>
        <h2 className="text-4xl font-black leading-[1.05] tracking-[-0.02em]">Forgot your password?</h2>
        <p className="mt-1.5 text-[17px] opacity-85">Enter your work email. We will send you a link to choose a new password.</p>
      </div>

      <ForgotPasswordForm />
    </>
  );
}
