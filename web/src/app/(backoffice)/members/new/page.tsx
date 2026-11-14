/**
 * src/app/(backoffice)/members/new/page.tsx
 *
 * WHAT: B11 Add user: role, profile, institution, minor guardian consent, community, invitation email
 * REQUIREMENTS: FR-07, FR-10
 * SPEC: docs/features/05-members-users.md
 * STATUS: implemented
 */

"use client";

import { useRouter } from "next/navigation";
import { AddUserForm } from "@/features/members/components/AddUserForm";
import { ROUTES } from "@/lib/constants/routes";

export default function NewMemberPage() {
  const router = useRouter();

  return (
    <div className="mx-auto max-w-3xl space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Add user</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Create a member account and optionally send a password setup invitation.
        </p>
      </div>

      <div className="rounded-card border border-border bg-white p-6">
        <AddUserForm onSuccess={() => router.push(ROUTES.members)} />
      </div>
    </div>
  );
}
