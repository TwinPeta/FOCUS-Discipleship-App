/**
 * src/app/(my-community)/my-community/resources/page.tsx
 *
 * WHAT: Read-only published resources for the community
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

"use client";

import { useEffect, useState } from "react";
import { BookOpen } from "lucide-react";
import {
  fetchMyCommunityOverview,
  MOCK_MY_COMMUNITY,
  type CommunityResource,
} from "@/features/my-community/queries";

export default function MyCommunityResourcesPage() {
  const [communityName, setCommunityName] = useState(MOCK_MY_COMMUNITY.communityName);
  const [resources, setResources] = useState<CommunityResource[]>(MOCK_MY_COMMUNITY.resources);

  useEffect(() => {
    let active = true;
    fetchMyCommunityOverview().then((res) => {
      if (!active) return;
      setCommunityName(res.communityName);
      setResources(res.resources);
    });
    return () => {
      active = false;
    };
  }, []);

  return (
    <main className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-foreground">
          Resources — {communityName}
        </h1>
        <p className="mt-1 text-sm text-muted">
          Read-only published discipleship materials available to your community.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {resources.map((res) => (
          <article
            key={res.id}
            className="space-y-2 rounded-xl border border-border bg-white p-4"
          >
            <div className="flex items-center justify-between text-xs text-muted">
              <span className="inline-flex items-center gap-1 rounded bg-primary-soft px-2 py-0.5 font-medium text-foreground">
                <BookOpen className="h-3 w-3" aria-hidden="true" />
                {res.type}
              </span>
              <span>{res.publishedAt}</span>
            </div>
            <h2 className="text-sm font-semibold text-foreground">{res.title}</h2>
            <p className="text-xs text-muted">Pathway: {res.pathway}</p>
          </article>
        ))}
      </div>
    </main>
  );
}
