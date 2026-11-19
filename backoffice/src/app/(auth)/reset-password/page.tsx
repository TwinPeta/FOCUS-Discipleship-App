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
    <>
      <div>
        <h2 className="text-4xl font-black leading-[1.05] tracking-[-0.02em]">Choose a new password</h2>
        <p className="mt-1.5 text-[17px] opacity-85">This link works once and expires after 1 hour.</p>
      </div>

      <ResetPasswordForm token={params.token ?? ""} />
    </>
  );
}
