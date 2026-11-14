/**
 * src/features/moderation/components/ModerationTabs.tsx
 *
 * WHAT: Moderation route tabs (Reports, Testimonies, Prayer & posts, Sanctions) with counts
 * REQUIREMENTS: FR-09
 * SPEC: docs/features/11-moderation.md
 * STATUS: implemented
 */

"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ROUTES } from "@/lib/constants/routes";

interface ModerationTabsProps {
  counts?: {
    reports?: number;
    testimonies?: number;
    posts?: number;
    sanctions?: number;
  };
}

export function ModerationTabs({ counts = {} }: ModerationTabsProps) {
  const pathname = usePathname();

  const tabs = [
    { href: ROUTES.moderationReports, label: "Reports", count: counts.reports },
    {
      href: ROUTES.moderationTestimonies,
      label: "Testimonies",
      count: counts.testimonies,
    },
    {
      href: ROUTES.moderationPosts,
      label: "Prayer & posts",
      count: counts.posts,
    },
    {
      href: ROUTES.moderationSanctions,
      label: "Sanctions",
      count: counts.sanctions,
    },
  ];

  return (
    <nav
      aria-label="Moderation queues"
      className="flex flex-wrap gap-2 border-b border-border pb-2"
    >
      {tabs.map((tab) => {
        const active = pathname === tab.href || pathname.startsWith(`${tab.href}/`);
        return (
          <Link
            key={tab.href}
            href={tab.href}
            className={`rounded-md px-3 py-1.5 text-sm font-medium ${
              active
                ? "bg-primary text-foreground"
                : "text-muted-foreground hover:bg-surface"
            }`}
          >
            {tab.label}
            {typeof tab.count === "number" ? ` (${tab.count})` : ""}
          </Link>
        );
      })}
    </nav>
  );
}
