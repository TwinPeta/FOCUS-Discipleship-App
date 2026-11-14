/**
 * src/app/(auth)/reset-password/page.tsx
 *
 * WHAT: B28 Reset password: single-use link expiring in 1 hour, password rules checklist
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { ResetPasswordForm } from "@/features/auth/components/ResetPasswordForm";

interface ResetPasswordPageProps {
  searchParams: Promise<{ token?: string }>;
}

export default async function ResetPasswordPage({
  searchParams,
}: ResetPasswordPageProps) {
  const params = await searchParams;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-foreground">Reset password</h2>
        <p className="mt-1 text-sm text-muted-foreground">
          Choose a strong password you have not used recently.
        </p>
      </div>

      <ResetPasswordForm token={params.token ?? ""} />
    </div>
  );
}
