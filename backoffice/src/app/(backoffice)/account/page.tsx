/**
 * src/app/(backoffice)/account/page.tsx
 *
 * WHAT: B25 My account: profile, change password, where you are signed in with sign-out per session
 * REQUIREMENTS: FR-07
 * SPEC: docs/features/01-staff-access.md
 * STATUS: implemented
 */

import { ChangePasswordForm } from "@/features/account/components/ChangePasswordForm";
import { ProfileForm } from "@/features/account/components/ProfileForm";
import { SessionsList } from "@/features/account/components/SessionsList";

export default function AccountPage() {
  return (
    <div className="flex max-w-4xl flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">My account</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Manage your profile, password, and active staff sessions.
        </p>
      </div>

      <section className="rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Profile</h2>
        <div className="mt-4">
          <ProfileForm />
        </div>
      </section>

      <section id="security" className="scroll-mt-20 rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">Change password</h2>
        <div className="mt-4">
          <ChangePasswordForm />
        </div>
      </section>

      <section id="sessions" className="scroll-mt-20 rounded-card border border-border bg-white p-6">
        <h2 className="eyebrow">
          Where you are signed in
        </h2>
        <p className="mt-1 text-xs text-muted-foreground">
          Sign out any device you no longer recognise.
        </p>
        <div className="mt-4">
          <SessionsList />
        </div>
      </section>
    </div>
  );
}
