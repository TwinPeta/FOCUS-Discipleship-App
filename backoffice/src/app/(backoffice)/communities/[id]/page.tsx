/**
 * src/app/(backoffice)/communities/[id]/page.tsx
 *
 * WHAT: Community detail and edit page (meeting details, team, cover photo, open/closed status)
 * REQUIREMENTS: FR-03
 * SPEC: docs/features/03-institutions-communities.md
 * STATUS: implemented
 */

"use client";

import { use, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { CommunityForm } from "@/features/communities/components/CommunityForm";
import { fetchCommunity, updateCommunity } from "@/features/communities/queries";
import type { Community, CommunityInput } from "@/features/communities/schemas";
import { ROUTES } from "@/lib/constants/routes";

export default function CommunityDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const router = useRouter();
  const [community, setCommunity] = useState<Community | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchCommunity(id)
      .then(setCommunity)
      .catch(() => setError("Could not load caregroup details."))
      .finally(() => setLoading(false));
  }, [id]);

  async function handleUpdate(values: CommunityInput) {
    await updateCommunity(id, values);
    router.push(ROUTES.communities);
    router.refresh();
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <h1 className="text-[34px] leading-[1.05]">
          {community ? community.name : "Caregroup details"}
        </h1>
      </div>

      <div className="rounded-card border border-border bg-white p-6">
        {loading && <p className="text-sm text-muted-foreground">Loading caregroup...</p>}
        {error && (
          <p role="alert" className="text-sm text-danger">
            {error}
          </p>
        )}
        {community && (
          <CommunityForm
            initial={community}
            onSubmit={handleUpdate}
            onCancel={() => router.push(ROUTES.communities)}
          />
        )}
      </div>
    </div>
  );
}
