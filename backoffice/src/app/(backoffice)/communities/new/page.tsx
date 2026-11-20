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
import { PageHeader } from "@/components/layout/PageHeader";
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
    <div className="flex flex-col gap-5">
      <PageHeader
        title="New caregroup"
        description="Create a caregroup, assign a super-mentor and mentors, and upload a cover photo."
        backHref={ROUTES.communities}
        backLabel="Back to caregroups"
      />

      <div className="flex flex-wrap items-start gap-4">
        <div className="card min-w-0 flex-[999_1_520px]">
          <CommunityForm onSubmit={handleCreate} onCancel={() => router.push(ROUTES.communities)} />
        </div>

        <aside className="flex min-w-0 flex-[1_1_280px] flex-col gap-4 lg:max-w-[360px]">
          <section className="card flex flex-col gap-2">
            <h2 className="eyebrow">How it works</h2>
            <ul className="flex flex-col gap-2 text-[15px]">
              <li>Students join instantly.</li>
              <li>A student can join only one specific caregroup.</li>
              <li>Mentors help the super-mentor guide the group.</li>
            </ul>
          </section>
          <section className="card flex flex-col gap-2">
            <h2 className="eyebrow">Visible in the app</h2>
            <ul className="flex flex-col gap-2 text-[15px]">
              <li>Caregroups list for the campus, with day, time and place.</li>
              <li>Caregroup feed, prayer wall and resources.</li>
            </ul>
          </section>
        </aside>
      </div>
    </div>
  );
}
