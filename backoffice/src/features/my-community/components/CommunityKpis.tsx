/**
 * src/features/my-community/components/CommunityKpis.tsx
 *
 * WHAT: Members, pending requests, reports to review, inactive members
 * REQUIREMENTS: FR-03,FR-04,FR-05
 * SPEC: docs/features/15-super-mentor-view.md
 * STATUS: implemented
 */

import Link from "next/link";
import { ROUTES } from "@/lib/constants/routes";
import type { CommunityKpiSummary } from "../queries";

export function CommunityKpis({ kpis }: { kpis: CommunityKpiSummary }) {
  const cards = [
    {
      label: "Members",
      value: kpis.members,
      href: ROUTES.myCommunityMembers,
    },
    {
      label: "Pending requests",
      value: kpis.pendingRequests,
      href: ROUTES.myCommunityJoinRequests,
    },
    {
      label: "Reports to review",
      value: kpis.reportsToReview,
      href: ROUTES.myCommunityModeration,
    },
    {
      label: "Inactive (14+ days)",
      value: kpis.inactiveMembers,
      href: ROUTES.myCommunityMembers,
    },
  ];

  return (
    <section className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4" aria-label="Caregroup KPIs">
      {cards.map((card) => (
        <Link key={card.label} href={card.href} className="card flex flex-col gap-1 transition hover:shadow-md">
          <p className="eyebrow">{card.label}</p>
          <p className="text-[34px] font-black leading-none tracking-tight">{card.value}</p>
        </Link>
      ))}
    </section>
  );
}
