/**
 * src/app/(backoffice)/communities/new/page.tsx
 *
 * WHAT: B14 New community: institution, name, meeting schedule, super-mentor, mentors, cover photo
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { useRouter } from "next/navigation";
import { CommunityForm } from "@/features/communities/components/CommunityForm";
import { createCommunity } from "@/features/communities/queries";
import type { CommunityInput } from "@/features/communities/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function NewCommunityPage() {
  const router = useRouter();

  async function handleCreate(values: CommunityInput) {
    await createCommunity(values);
    router.push(ROUTES.communities);
    router.refresh();
  }

  return (
    <div className="mx-auto max-w-3xl space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">New community</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Create a community, assign a super-mentor and mentors, and upload a
          cover photo.
        </p>
      </div>

      <div className="rounded-card border border-border bg-white p-6">
        <CommunityForm
          onSubmit={handleCreate}
          onCancel={() => router.push(ROUTES.communities)}
        />
      </div>
    </div>
  );
}
